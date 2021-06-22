codeunit 5815 "Undo Sales Shipment Line"
{
    Permissions = TableData "Sales Line" = imd,
                  TableData "Sales Shipment Line" = imd,
                  TableData "Item Application Entry" = rmd,
                  TableData "Item Entry Relation" = ri;
    TableNo = "Sales Shipment Line";

    trigger OnRun()
    var
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
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

        SalesShptLine.Copy(Rec);
        Code;
        UpdateItemAnalysisView.UpdateAll(0, true);
        Rec := SalesShptLine;
    end;

    var
        SalesShptLine: Record "Sales Shipment Line";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        TempGlobalItemLedgEntry: Record "Item Ledger Entry" temporary;
        TempGlobalItemEntryRelation: Record "Item Entry Relation" temporary;
        InvtSetup: Record "Inventory Setup";
        UndoPostingMgt: Codeunit "Undo Posting Management";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        Text000: Label 'Do you really want to undo the selected Shipment lines?';
        Text001: Label 'Undo quantity posting...';
        Text002: Label 'There is not enough space to insert correction lines.';
        WhseUndoQty: Codeunit "Whse. Undo Quantity";
        InvtAdjmt: Codeunit "Inventory Adjustment";
        ResJnlPostLine: Codeunit "Res. Jnl.-Post Line";
        AsmPost: Codeunit "Assembly-Post";
        UOMMgt: Codeunit "Unit of Measure Management";
        ATOWindow: Dialog;
        HideDialog: Boolean;
        Text003: Label 'Checking lines...';
        Text004: Label 'Some shipment lines may have unused service items. Do you want to delete them?';
        NextLineNo: Integer;
        Text005: Label 'This shipment has already been invoiced. Undo Shipment can be applied only to posted, but not invoiced shipments.';
        Text006: Label 'Undo Shipment can be performed only for lines of type Item. Please select a line of the Item type and repeat the procedure.';
        Text055: Label '#1#################################\\Checking Undo Assembly #2###########.';
        Text056: Label '#1#################################\\Posting Undo Assembly #2###########.';
        Text057: Label '#1#################################\\Finalizing Undo Assembly #2###########.';
        Text059: Label '%1 %2 %3', Comment = '%1 = SalesShipmentLine."Document No.". %2 = SalesShipmentLine.FIELDCAPTION("Line No."). %3 = SalesShipmentLine."Line No.". This is used in a progress window.';
        AlreadyReversedErr: Label 'This shipment has already been reversed.';

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    local procedure "Code"()
    var
        PostedWhseShptLine: Record "Posted Whse. Shipment Line";
        SalesLine: Record "Sales Line";
        ServItem: Record "Service Item";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        Window: Dialog;
        ItemShptEntryNo: Integer;
        DocLineNo: Integer;
        DeleteServItems: Boolean;
        PostedWhseShptLineFound: Boolean;
    begin
        with SalesShptLine do begin
            Clear(ItemJnlPostLine);
            SetCurrentKey("Item Shpt. Entry No.");
            SetFilter(Quantity, '<>0');
            SetRange(Correction, false);
            if IsEmpty then
                Error(AlreadyReversedErr);
            FindFirst();
            repeat
                if not HideDialog then
                    Window.Open(Text003);
                CheckSalesShptLine(SalesShptLine);
            until Next = 0;

            ServItem.SetCurrentKey("Sales/Serv. Shpt. Document No.");
            ServItem.SetRange("Sales/Serv. Shpt. Document No.", "Document No.");
            if ServItem.FindFirst then
                if not HideDialog then
                    DeleteServItems := Confirm(Text004, true)
                else
                    DeleteServItems := true;

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
                        DATABASE::"Sales Shipment Line",
                        "Document No.",
                        DATABASE::"Sales Line",
                        SalesLine."Document Type"::Order,
                        "Order No.",
                        "Order Line No.");

                    Clear(ItemJnlPostLine);
                    ItemShptEntryNo := PostItemJnlLine(SalesShptLine, DocLineNo);
                end else
                    DocLineNo := GetCorrectionLineNo(SalesShptLine);

                InsertNewShipmentLine(SalesShptLine, ItemShptEntryNo, DocLineNo);
                OnAfterInsertNewShipmentLine(SalesShptLine, PostedWhseShptLine, PostedWhseShptLineFound, DocLineNo);

                if PostedWhseShptLineFound then
                    WhseUndoQty.UndoPostedWhseShptLine(PostedWhseShptLine);

                TempWhseJnlLine.SetRange("Source Line No.", "Line No.");
                WhseUndoQty.PostTempWhseJnlLineCache(TempWhseJnlLine, WhseJnlRegisterLine);

                UndoPostATO(SalesShptLine, WhseJnlRegisterLine);

                UpdateOrderLine(SalesShptLine);
                if PostedWhseShptLineFound then
                    WhseUndoQty.UpdateShptSourceDocLines(PostedWhseShptLine);

                if ("Blanket Order No." <> '') and ("Blanket Order Line No." <> 0) then
                    UpdateBlanketOrder(SalesShptLine);

                if DeleteServItems then
                    DeleteSalesShptLineServItems(SalesShptLine);

                "Quantity Invoiced" := Quantity;
                "Qty. Invoiced (Base)" := "Quantity (Base)";
                "Qty. Shipped Not Invoiced" := 0;
                Correction := true;

                OnBeforeSalesShptLineModify(SalesShptLine);
                Modify;
                OnAfterSalesShptLineModify(SalesShptLine);

                UndoFinalizePostATO(SalesShptLine);
            until Next = 0;

            InvtSetup.Get();
            if InvtSetup."Automatic Cost Adjustment" <>
               InvtSetup."Automatic Cost Adjustment"::Never
            then begin
                InvtAdjmt.SetProperties(true, InvtSetup."Automatic Cost Posting");
                InvtAdjmt.SetJobUpdateProperties(true);
                InvtAdjmt.MakeMultiLevelAdjmt;
            end;
        end;

        OnAfterCode(SalesShptLine);
    end;

    local procedure CheckSalesShptLine(SalesShptLine: Record "Sales Shipment Line")
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        IsHandled: Boolean;
        SkipTestFields: Boolean;
        SkipUndoPosting: Boolean;
        SkipUndoInitPostATO: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesShptLine(SalesShptLine, IsHandled, SkipTestFields, SkipUndoPosting, SkipUndoInitPostATO);
        if IsHandled then
            exit;

        with SalesShptLine do begin
            if not SkipTestFields then begin
                if Correction then
                    Error(AlreadyReversedErr);
                if "Qty. Shipped Not Invoiced" <> Quantity then
                    if HasInvoicedNotReturnedQuantity(SalesShptLine) then
                        Error(Text005);
            end;
            if Type = Type::Item then begin
                if not SkipTestFields then
                    TestField("Drop Shipment", false);

                if not SkipUndoPosting then begin
                    UndoPostingMgt.TestSalesShptLine(SalesShptLine);
                    UndoPostingMgt.CollectItemLedgEntries(
                        TempItemLedgEntry, DATABASE::"Sales Shipment Line", "Document No.", "Line No.", "Quantity (Base)", "Item Shpt. Entry No.");
                    UndoPostingMgt.CheckItemLedgEntries(TempItemLedgEntry, "Line No.", "Qty. Shipped Not Invoiced" <> Quantity);
                end;
                if not SkipUndoInitPostATO then
                    UndoInitPostATO(SalesShptLine);
            end;
        end;
    end;

    local procedure GetCorrectionLineNo(SalesShptLine: Record "Sales Shipment Line"): Integer;
    var
        SalesShptLine2: Record "Sales Shipment Line";
        LineSpacing: Integer;
    begin
        with SalesShptLine do begin
            SalesShptLine2.SetRange("Document No.", "Document No.");
            SalesShptLine2."Document No." := "Document No.";
            SalesShptLine2."Line No." := "Line No.";
            SalesShptLine2.Find('=');

            if SalesShptLine2.Find('>') then begin
                LineSpacing := (SalesShptLine2."Line No." - "Line No.") div 2;
                if LineSpacing = 0 then
                    Error(Text002);
            end else
                LineSpacing := 10000;

            exit("Line No." + LineSpacing);
        end;
    end;

    local procedure PostItemJnlLine(SalesShptLine: Record "Sales Shipment Line"; var DocLineNo: Integer): Integer
    var
        ItemJnlLine: Record "Item Journal Line";
        SalesLine: Record "Sales Line";
        SalesShptHeader: Record "Sales Shipment Header";
        SourceCodeSetup: Record "Source Code Setup";
        TempApplyToEntryList: Record "Item Ledger Entry" temporary;
        ItemLedgEntryNotInvoiced: Record "Item Ledger Entry";
        ItemLedgEntryNo: Integer;
        RemQtyBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemJnlLine(SalesShptLine, DocLineNo, ItemLedgEntryNo, IsHandled);
        if IsHandled then
            exit(ItemLedgEntryNo);

        with SalesShptLine do begin
            DocLineNo := GetCorrectionLineNo(SalesShptLine);

            SourceCodeSetup.Get();
            SalesShptHeader.Get("Document No.");

            ItemJnlLine.Init();
            ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Sale;
            ItemJnlLine."Item No." := "No.";
            ItemJnlLine."Posting Date" := SalesShptHeader."Posting Date";
            ItemJnlLine."Document No." := "Document No.";
            ItemJnlLine."Document Line No." := DocLineNo;
            ItemJnlLine."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
            ItemJnlLine."Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";
            ItemJnlLine."Location Code" := "Location Code";
            ItemJnlLine."Source Code" := SourceCodeSetup.Sales;
            ItemJnlLine.Correction := true;
            ItemJnlLine."Variant Code" := "Variant Code";
            ItemJnlLine."Bin Code" := "Bin Code";
            ItemJnlLine."Document Date" := SalesShptHeader."Document Date";

            OnAfterCopyItemJnlLineFromSalesShpt(ItemJnlLine, SalesShptHeader, SalesShptLine, TempWhseJnlLine);

            WhseUndoQty.InsertTempWhseJnlLine(ItemJnlLine,
              DATABASE::"Sales Line",
              SalesLine."Document Type"::Order,
              "Order No.",
              "Order Line No.",
              TempWhseJnlLine."Reference Document"::"Posted Shipment",
              TempWhseJnlLine,
              NextLineNo);

            if GetUnvoicedShptEntries(SalesShptLine, ItemLedgEntryNotInvoiced) then begin
                RemQtyBase := -("Quantity (Base)" - "Qty. Invoiced (Base)");
                repeat
                    ItemJnlLine."Applies-to Entry" := ItemLedgEntryNotInvoiced."Entry No.";
                    ItemJnlLine.Quantity := ItemLedgEntryNotInvoiced.Quantity;
                    ItemJnlLine."Quantity (Base)" := ItemLedgEntryNotInvoiced.Quantity;
                    ItemJnlPostLine.Run(ItemJnlLine);
                    RemQtyBase -= ItemJnlLine.Quantity;
                    if ItemLedgEntryNotInvoiced.Next = 0 then;
                until (RemQtyBase = 0);
                exit(ItemJnlLine."Item Shpt. Entry No.");
            end;
            UndoPostingMgt.CollectItemLedgEntries(TempApplyToEntryList, DATABASE::"Sales Shipment Line",
              "Document No.", "Line No.", "Quantity (Base)", "Item Shpt. Entry No.");
            UndoPostingMgt.PostItemJnlLineAppliedToList(
                ItemJnlLine, TempApplyToEntryList, Quantity - "Quantity Invoiced", "Quantity (Base)" - "Qty. Invoiced (Base)", TempGlobalItemLedgEntry, TempGlobalItemEntryRelation, "Qty. Shipped Not Invoiced" <> Quantity);

            exit(0); // "Item Shpt. Entry No."
        end;
    end;

    local procedure InsertNewShipmentLine(OldSalesShptLine: Record "Sales Shipment Line"; ItemShptEntryNo: Integer; DocLineNo: Integer)
    var
        NewSalesShptLine: Record "Sales Shipment Line";
    begin
        with OldSalesShptLine do begin
            NewSalesShptLine.Init();
            NewSalesShptLine.Copy(OldSalesShptLine);
            NewSalesShptLine."Line No." := DocLineNo;
            NewSalesShptLine."Appl.-from Item Entry" := "Item Shpt. Entry No.";
            NewSalesShptLine."Item Shpt. Entry No." := ItemShptEntryNo;
            NewSalesShptLine.Quantity := -Quantity;
            NewSalesShptLine."Qty. Shipped Not Invoiced" := 0;
            NewSalesShptLine."Quantity (Base)" := -"Quantity (Base)";
            NewSalesShptLine."Quantity Invoiced" := NewSalesShptLine.Quantity;
            NewSalesShptLine."Qty. Invoiced (Base)" := NewSalesShptLine."Quantity (Base)";
            NewSalesShptLine.Correction := true;
            NewSalesShptLine."Dimension Set ID" := "Dimension Set ID";
            OnBeforeNewSalesShptLineInsert(NewSalesShptLine, OldSalesShptLine);
            NewSalesShptLine.Insert();
            OnAfterNewSalesShptLineInsert(NewSalesShptLine, OldSalesShptLine);

            InsertItemEntryRelation(TempGlobalItemEntryRelation, NewSalesShptLine);
        end;
    end;

    procedure UpdateOrderLine(SalesShptLine: Record "Sales Shipment Line")
    var
        SalesLine: Record "Sales Line";
    begin
        with SalesShptLine do begin
            SalesLine.Get(SalesLine."Document Type"::Order, "Order No.", "Order Line No.");
            UndoPostingMgt.UpdateSalesLine(SalesLine, Quantity - "Quantity Invoiced", "Quantity (Base)" - "Qty. Invoiced (Base)", TempGlobalItemLedgEntry);
            OnAfterUpdateSalesLine(SalesLine, SalesShptLine);
        end;
    end;

    procedure UpdateBlanketOrder(SalesShptLine: Record "Sales Shipment Line")
    var
        BlanketOrderSalesLine: Record "Sales Line";
        xBlanketOrderSalesLine: Record "Sales Line";
    begin
        with SalesShptLine do
            if BlanketOrderSalesLine.Get(
                 BlanketOrderSalesLine."Document Type"::"Blanket Order", "Blanket Order No.", "Blanket Order Line No.")
            then begin
                BlanketOrderSalesLine.TestField(Type, Type);
                BlanketOrderSalesLine.TestField("No.", "No.");
                BlanketOrderSalesLine.TestField("Sell-to Customer No.", "Sell-to Customer No.");
                xBlanketOrderSalesLine := BlanketOrderSalesLine;

                if BlanketOrderSalesLine."Qty. per Unit of Measure" = "Qty. per Unit of Measure" then
                    BlanketOrderSalesLine."Quantity Shipped" := BlanketOrderSalesLine."Quantity Shipped" - Quantity
                else
                    BlanketOrderSalesLine."Quantity Shipped" :=
                      BlanketOrderSalesLine."Quantity Shipped" -
                      Round(
                        "Qty. per Unit of Measure" / BlanketOrderSalesLine."Qty. per Unit of Measure" * Quantity, UOMMgt.QtyRndPrecision);

                BlanketOrderSalesLine."Qty. Shipped (Base)" := BlanketOrderSalesLine."Qty. Shipped (Base)" - "Quantity (Base)";
                OnBeforeBlanketOrderInitOutstanding(BlanketOrderSalesLine, SalesShptLine);
                BlanketOrderSalesLine.InitOutstanding;
                BlanketOrderSalesLine.Modify();

                AsmPost.UpdateBlanketATO(xBlanketOrderSalesLine, BlanketOrderSalesLine);
            end;
    end;

    local procedure InsertItemEntryRelation(var TempItemEntryRelation: Record "Item Entry Relation" temporary; NewSalesShptLine: Record "Sales Shipment Line")
    var
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        if TempItemEntryRelation.Find('-') then
            repeat
                ItemEntryRelation := TempItemEntryRelation;
                ItemEntryRelation.TransferFieldsSalesShptLine(NewSalesShptLine);
                ItemEntryRelation.Insert();
            until TempItemEntryRelation.Next = 0;
    end;

    local procedure DeleteSalesShptLineServItems(SalesShptLine: Record "Sales Shipment Line")
    var
        ServItem: Record "Service Item";
    begin
        ServItem.SetCurrentKey("Sales/Serv. Shpt. Document No.", "Sales/Serv. Shpt. Line No.");
        ServItem.SetRange("Sales/Serv. Shpt. Document No.", SalesShptLine."Document No.");
        ServItem.SetRange("Sales/Serv. Shpt. Line No.", SalesShptLine."Line No.");
        ServItem.SetRange("Shipment Type", ServItem."Shipment Type"::Sales);
        if ServItem.Find('-') then
            repeat
                if ServItem.CheckIfCanBeDeleted = '' then
                    if ServItem.Delete(true) then;
            until ServItem.Next = 0;
    end;

    local procedure UndoInitPostATO(var SalesShptLine: Record "Sales Shipment Line")
    var
        PostedAsmHeader: Record "Posted Assembly Header";
    begin
        if SalesShptLine.AsmToShipmentExists(PostedAsmHeader) then begin
            OpenATOProgressWindow(Text055, SalesShptLine, PostedAsmHeader);

            AsmPost.UndoInitPostATO(PostedAsmHeader);

            ATOWindow.Close;
        end;
    end;

    local procedure UndoPostATO(var SalesShptLine: Record "Sales Shipment Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    var
        PostedAsmHeader: Record "Posted Assembly Header";
    begin
        if SalesShptLine.AsmToShipmentExists(PostedAsmHeader) then begin
            OpenATOProgressWindow(Text056, SalesShptLine, PostedAsmHeader);

            AsmPost.UndoPostATO(PostedAsmHeader, ItemJnlPostLine, ResJnlPostLine, WhseJnlRegisterLine);

            ATOWindow.Close;
        end;
    end;

    local procedure UndoFinalizePostATO(var SalesShptLine: Record "Sales Shipment Line")
    var
        PostedAsmHeader: Record "Posted Assembly Header";
    begin
        if SalesShptLine.AsmToShipmentExists(PostedAsmHeader) then begin
            OpenATOProgressWindow(Text057, SalesShptLine, PostedAsmHeader);

            AsmPost.UndoFinalizePostATO(PostedAsmHeader);
            SynchronizeATO(SalesShptLine);

            ATOWindow.Close;
        end;
    end;

    local procedure SynchronizeATO(var SalesShptLine: Record "Sales Shipment Line")
    var
        SalesLine: Record "Sales Line";
        AsmHeader: Record "Assembly Header";
    begin
        with SalesLine do begin
            Get("Document Type"::Order, SalesShptLine."Order No.", SalesShptLine."Order Line No.");

            if AsmToOrderExists(AsmHeader) and (AsmHeader.Status = AsmHeader.Status::Released) then begin
                AsmHeader.Status := AsmHeader.Status::Open;
                AsmHeader.Modify();
                AutoAsmToOrder;
                AsmHeader.Status := AsmHeader.Status::Released;
                AsmHeader.Modify();
            end else
                AutoAsmToOrder;

            Modify(true);
        end;
    end;

    local procedure OpenATOProgressWindow(State: Text[250]; SalesShptLine: Record "Sales Shipment Line"; PostedAsmHeader: Record "Posted Assembly Header")
    begin
        ATOWindow.Open(State);
        ATOWindow.Update(1,
          StrSubstNo(Text059,
            SalesShptLine."Document No.", SalesShptLine.FieldCaption("Line No."), SalesShptLine."Line No."));
        ATOWindow.Update(2, PostedAsmHeader."No.");
    end;

    local procedure GetUnvoicedShptEntries(SalesShptLine: Record "Sales Shipment Line"; var ItemLedgEntry: Record "Item Ledger Entry"): Boolean
    begin
        ItemLedgEntry.SetCurrentKey("Document No.", "Document Type", "Document Line No.");
        ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Sales Shipment");
        ItemLedgEntry.SetRange("Document No.", SalesShptLine."Document No.");
        ItemLedgEntry.SetRange("Document Line No.", SalesShptLine."Line No.");
        ItemLedgEntry.SetRange("Serial No.", '');
        ItemLedgEntry.SetRange("Lot No.", '');
        ItemLedgEntry.SetRange("Completely Invoiced", false);
        exit(ItemLedgEntry.FindSet)
    end;

    local procedure HasInvoicedNotReturnedQuantity(SalesShipmentLine: Record "Sales Shipment Line"): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReturnedInvoicedItemLedgerEntry: Record "Item Ledger Entry";
        ItemApplicationEntry: Record "Item Application Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        InvoicedQuantity: Decimal;
        ReturnedInvoicedQuantity: Decimal;
    begin
        if SalesShipmentLine.Type = SalesShipmentLine.Type::Item then begin
            ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Sales Shipment");
            ItemLedgerEntry.SetRange("Document No.", SalesShipmentLine."Document No.");
            ItemLedgerEntry.SetRange("Document Line No.", SalesShipmentLine."Line No.");
            ItemLedgerEntry.FindSet();
            repeat
                InvoicedQuantity += ItemLedgerEntry."Invoiced Quantity";
                if ItemApplicationEntry.AppliedInbndEntryExists(ItemLedgerEntry."Entry No.", false) then
                    repeat
                        if ItemApplicationEntry."Item Ledger Entry No." = ItemApplicationEntry."Inbound Item Entry No." then begin
                            ReturnedInvoicedItemLedgerEntry.Get(ItemApplicationEntry."Item Ledger Entry No.");
                            if IsCancelled(ReturnedInvoicedItemLedgerEntry) then
                                ReturnedInvoicedQuantity += ReturnedInvoicedItemLedgerEntry."Invoiced Quantity";
                        end;
                    until ItemApplicationEntry.Next() = 0;
            until ItemLedgerEntry.Next() = 0;
            exit(InvoicedQuantity + ReturnedInvoicedQuantity <> 0);
        end else begin
            SalesInvoiceLine.SetRange("Order No.", SalesShipmentLine."Order No.");
            SalesInvoiceLine.SetRange("Order Line No.", SalesShipmentLine."Order Line No.");
            if SalesInvoiceLine.FindSet() then
                repeat
                    SalesInvoiceHeader.Get(SalesInvoiceLine."Document No.");
                    SalesInvoiceHeader.CalcFields(Cancelled);
                    if not SalesInvoiceHeader.Cancelled then
                        exit(true);
                until SalesInvoiceLine.Next() = 0;

            exit(false);
        end;
    end;

    local procedure IsCancelled(ItemLedgerEntry: Record "Item Ledger Entry"): Boolean
    var
        CancelledDocument: Record "Cancelled Document";
        ReturnReceiptHeader: Record "Return Receipt Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        case ItemLedgerEntry."Document Type" of
            ItemLedgerEntry."Document Type"::"Sales Return Receipt":
                begin
                    ReturnReceiptHeader.Get(ItemLedgerEntry."Document No.");
                    if ReturnReceiptHeader."Applies-to Doc. Type" = ReturnReceiptHeader."Applies-to Doc. Type"::Invoice then
                        exit(CancelledDocument.Get(Database::"Sales Invoice Header", ReturnReceiptHeader."Applies-to Doc. No."));
                end;
            ItemLedgerEntry."Document Type"::"Sales Credit Memo":
                begin
                    SalesCrMemoHeader.Get(ItemLedgerEntry."Document No.");
                    if SalesCrMemoHeader."Applies-to Doc. Type" = SalesCrMemoHeader."Applies-to Doc. Type"::Invoice then
                        exit(CancelledDocument.Get(Database::"Sales Invoice Header", SalesCrMemoHeader."Applies-to Doc. No."));
                end;
        end;

        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var SalesShipmentLine: Record "Sales Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromSalesShpt(var ItemJournalLine: Record "Item Journal Line"; SalesShipmentHeader: Record "Sales Shipment Header"; SalesShipmentLine: Record "Sales Shipment Line"; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterNewSalesShptLineInsert(var NewSalesShipmentLine: Record "Sales Shipment Line"; OldSalesShipmentLine: Record "Sales Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesShptLineModify(var SalesShptLine: Record "Sales Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSalesLine(var SalesLine: Record "Sales Line"; var SalesShptLine: Record "Sales Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBlanketOrderInitOutstanding(var BlanketOrderSalesLine: Record "Sales Line"; SalesShipmentLine: Record "Sales Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesShptLine(var SalesShipmentLine: Record "Sales Shipment Line"; var IsHandled: Boolean; var SkipTestFields: Boolean; var SkipUndoPosting: Boolean; var SkipUndoInitPostATO: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertNewShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; PostedWhseShipmentLine: Record "Posted Whse. Shipment Line"; var PostedWhseShptLineFound: Boolean; DocLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var SalesShipmentLine: Record "Sales Shipment Line"; var IsHandled: Boolean; var SkipTypeCheck: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewSalesShptLineInsert(var NewSalesShipmentLine: Record "Sales Shipment Line"; OldSalesShipmentLine: Record "Sales Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLine(var SalesShipmentLine: Record "Sales Shipment Line"; DocLineNo: Integer; var ItemLedgEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesShptLineModify(var SalesShptLine: Record "Sales Shipment Line")
    begin
    end;
}

