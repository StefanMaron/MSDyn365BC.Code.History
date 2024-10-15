codeunit 31425 "Undo Transfer Ship. Line CZA"
{
    Permissions = TableData "Transfer Line" = rimd,
                  TableData "Transfer Shipment Line" = rimd,
                  TableData "Item Application Entry" = rmd,
                  TableData "Item Entry Relation" = ri;
    TableNo = "Transfer Shipment Line";

    trigger OnRun()
    var
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        ItemList, ConfirmQst : Text;
    begin
        ItemList := GetItemList(Rec);
        if ItemList = '' then
            Error(EmptyItemNoErr);

        ConfirmQst := ReallyUndoQst + '\\' + ItemList;
        if not HideDialog then
            if not Confirm(ConfirmQst) then
                exit;

        TransShptLine.Copy(Rec);
        Code();
        UpdateItemAnalysisView.UpdateAll(0, true);
        Rec := TransShptLine;
    end;

    var
        TransShptLine: Record "Transfer Shipment Line";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        TempGlobalItemLedgEntry: Record "Item Ledger Entry" temporary;
        TempGlobalItemEntryRelation: Record "Item Entry Relation" temporary;
        UndoPostingMgt: Codeunit "Undo Posting Management";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        WhseUndoQty: Codeunit "Whse. Undo Quantity";
        HideDialog: Boolean;
        NextLineNo: Integer;

        EmptyItemNoErr: Label 'Undo Shipment can be performed only for lines with nonempty Item No. Please select a line with nonempty Item No. and repeat the procedure.';
        ReallyUndoQst: Label 'Do you really want to undo the selected Shipment lines?';
        UndoQtyMsg: Label 'Undo quantity posting...';
        NotEnoughLineSpaceErr: Label 'There is not enough space to insert correction lines.';
        CheckingLinesMsg: Label 'Checking lines...';
        AlreadyReversedErr: Label 'This shipment has already been reversed.';
        AlreadyReceivedErr: Label 'This shipment has already been received. Undo Shipment can only be applied to posted, but not received Transfer Lines.';
        NoTransOrderLineNoErr: Label 'The Transfer Shipment Line is missing a value in the field Trans. Order Line No. This is automatically populated when posting new Transfer Shipments';
        NonSurplusResEntriesErr: Label 'You cannot undo transfer shipment line %1 because this line is Reserved. Reservation Entry No. %2', Comment = '%1 = Line No., %2 = Entry No.';


    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    local procedure "Code"()
    var
        PostedWhseShptLine: Record "Posted Whse. Shipment Line";
        TransferLine: Record "Transfer Line";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        Window: Dialog;
        ItemShptEntryNo: Integer;
        DocLineNo: Integer;
        Direction: Enum "Transfer Direction";
        PostedWhseShptLineFound: Boolean;
    begin
        Clear(ItemJnlPostLine);
        TransShptLine.SetCurrentKey("Item Shpt. Entry No.");
        TransShptLine.SetFilter(Quantity, '<>0');
        TransShptLine.SetRange("Correction CZA", false);

        if TransShptLine.IsEmpty() then
            Error(AlreadyReversedErr);
        TransShptLine.FindSet();
        repeat
            if not HideDialog then
                Window.Open(CheckingLinesMsg);
            CheckTransferShptLine(TransShptLine);
        until TransShptLine.Next() = 0;

        TransShptLine.FindSet();
        repeat
            if TransShptLine."Transfer Order Line No. CZA" = 0 then
                Error(NoTransOrderLineNoErr);
            TransferLine.Get(TransShptLine."Transfer Order No.", TransShptLine."Transfer Order Line No. CZA");
            if TransferLine."Qty. Received (Base)" > 0 then
                Error(AlreadyReceivedErr);

            TempGlobalItemLedgEntry.Reset();
            if not TempGlobalItemLedgEntry.IsEmpty() then
                TempGlobalItemLedgEntry.DeleteAll();
            TempGlobalItemEntryRelation.Reset();
            if not TempGlobalItemEntryRelation.IsEmpty() then
                TempGlobalItemEntryRelation.DeleteAll();

            if not HideDialog then
                Window.Open(UndoQtyMsg);

            PostedWhseShptLineFound :=
             WhseUndoQty.FindPostedWhseShptLine(
                 PostedWhseShptLine, Database::"Transfer Shipment Line", TransShptLine."Document No.",
                 Database::"Transfer Line", Direction::Outbound.AsInteger(), TransShptLine."Transfer Order No.", TransShptLine."Line No.");

            // Undo derived transfer line and move tracking to current line
            UpdateDerivedTransferLine(TransferLine, TransShptLine);

            Clear(ItemJnlPostLine);
            ItemShptEntryNo := PostItemJnlLine(TransShptLine, DocLineNo);
            InsertNewShipmentLine(TransShptLine, ItemShptEntryNo, DocLineNo);

            if PostedWhseShptLineFound then
                WhseUndoQty.UndoPostedWhseShptLine(PostedWhseShptLine);

            TempWhseJnlLine.SetRange("Source Line No.", TransShptLine."Line No.");
            WhseUndoQty.PostTempWhseJnlLineCache(TempWhseJnlLine, WhseJnlRegisterLine);

            UpdateOrderLine(TransShptLine);
            if PostedWhseShptLineFound then
                WhseUndoQty.UpdateShptSourceDocLines(PostedWhseShptLine);

            TransShptLine."Correction CZA" := true;
            TransShptLine.Modify();

        until TransShptLine.Next() = 0;

        MakeInventoryAdjustment();
    end;

    local procedure CheckTransferShptLine(TransShptLine: Record "Transfer Shipment Line")
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
    begin
        if TransShptLine."Correction CZA" then
            Error(AlreadyReversedErr);

        UndoPostingMgt.RunTestAllTransactions(
            Database::"Transfer Shipment Line", TransShptLine."Document No.", TransShptLine."Line No.",
            Database::"Transfer Line", 0, TransShptLine."Transfer Order No.", TransShptLine."Line No.");

        UndoPostingMgt.CollectItemLedgEntries(
            TempItemLedgEntry, Database::"Transfer Shipment Line", TransShptLine."Document No.", TransShptLine."Line No.", TransShptLine."Quantity (Base)", TransShptLine."Item Shpt. Entry No.");
        UndoPostingMgt.CheckItemLedgEntries(TempItemLedgEntry, TransShptLine."Line No.", false);
    end;

    local procedure UpdateDerivedTransferLine(var TransferLine: Record "Transfer Line"; var TransferShptLine: Record "Transfer Shipment Line")
    var
        DerivedTransferLine: Record "Transfer Line";
    begin
        // Find the derived line
        // The premise is that the only one derived line exist. It means that the partial shipping is not supported.
        DerivedTransferLine.SetRange("Document No.", TransferShptLine."Transfer Order No.");
        DerivedTransferLine.SetRange("Derived From Line No.", TransferShptLine."Transfer Order Line No. CZA");
        DerivedTransferLine.FindFirst();

        // Move tracking information from the derived line to the original line
        TransferTracking(DerivedTransferLine, TransferLine, TransferShptLine);

        // Delete the derived line - a new one gets created for each shipment
        DerivedTransferLine.Delete();
    end;

    local procedure TransferTracking(var FromTransLine: Record "Transfer Line"; var ToTransLine: Record "Transfer Line"; var TransferShptLine: Record "Transfer Shipment Line")
    var
        ReservationEntry: Record "Reservation Entry";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        FromReservationEntryRowID: Text[250];
        ToReservationEntryRowID: Text[250];
        TransferQty: Decimal;
    begin
        TransferQty := FromTransLine.Quantity;
        FindReservEntrySet(FromTransLine, ReservationEntry, "Transfer Direction"::Inbound);
        if ReservationEntry.IsEmpty() then
            exit;

        CheckReservationEntryStatus(ReservationEntry, TransferShptLine);

        FromReservationEntryRowID := ItemTrackingMgt.ComposeRowID( // From invisible TransferLine holding tracking
                    DATABASE::"Transfer Line", 1, ReservationEntry."Source ID", '', ReservationEntry."Source Prod. Order Line", ReservationEntry."Source Ref. No.");
        ToReservationEntryRowID := ItemTrackingMgt.ComposeRowID( // To original TransferLine
              DATABASE::"Transfer Line", 0, ReservationEntry."Source ID", '', 0, ReservationEntry."Source Prod. Order Line");

        ToTransLine.TestField("Variant Code", FromTransLine."Variant Code");

        // Recreate reservation entries on from-location which were deleted on posting shipment
        ItemTrackingMgt.CopyItemTracking(FromReservationEntryRowID, ToReservationEntryRowID, true); // Switch sign on quantities

        if not ReservationEntry.IsEmpty() then
            repeat
                ReservationEntry.TestItemFields(FromTransLine."Item No.", FromTransLine."Variant Code", FromTransLine."Transfer-to Code");
                UpdateTransferQuantity(TransferQty, ToTransLine, ReservationEntry);
            until (ReservationEntry.Next() = 0) or (TransferQty = 0);
    end;

    local procedure FindReservEntrySet(TransLine: Record "Transfer Line"; var ReservEntry: Record "Reservation Entry"; Direction: Enum "Transfer Direction"): Boolean
    begin
        ReservEntry.InitSortingAndFilters(false);
        TransLine.SetReservationFilters(ReservEntry, Direction);
        exit(ReservEntry.FindSet());
    end;

    local procedure CheckReservationEntryStatus(var ReservationEntry: Record "Reservation Entry"; var TransferShipmentLine: Record "Transfer Shipment Line")
    begin
        ReservationEntry.SetFilter("Reservation Status", '<>%1', "Reservation Status"::Surplus);
        if ReservationEntry.FindFirst() then
            Error(NonSurplusResEntriesErr, TransferShipmentLine."Line No.", ReservationEntry."Entry No.");
        ReservationEntry.SetRange("Reservation Status");
        ReservationEntry.FindSet();
    end;

    local procedure UpdateTransferQuantity(var TransferQty: Decimal; var NewTransLine: Record "Transfer Line"; var OldReservEntry: Record "Reservation Entry")
    var
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        TransferQty :=
            CreateReservEntry.TransferReservEntry(DATABASE::"Transfer Line",
            "Transfer Direction"::Inbound.AsInteger(), NewTransLine."Document No.", '', NewTransLine."Derived From Line No.",
            NewTransLine."Line No.", NewTransLine."Qty. per Unit of Measure", OldReservEntry, TransferQty);
    end;

    local procedure GetCorrectionLineNo(TransferShptLine: Record "Transfer Shipment Line") Result: Integer;
    var
        TransferShptLine2: Record "Transfer Shipment Line";
        LineSpacing: Integer;
    begin
        TransferShptLine2.SetRange("Document No.", TransferShptLine."Document No.");
        TransferShptLine2.SetFilter("Line No.", '>%1', TransferShptLine."Line No.");
        if TransferShptLine2.FindFirst() then begin
            LineSpacing := (TransferShptLine2."Line No." - TransferShptLine."Line No.") div 2;
            if LineSpacing = 0 then
                Error(NotEnoughLineSpaceErr);
        end else
            LineSpacing := 10000;

        Result := TransferShptLine."Line No." + LineSpacing;
    end;

    local procedure PostItemJnlLine(TransShptLine: Record "Transfer Shipment Line"; var DocLineNo: Integer): Integer
    var
        ItemJnlLine: Record "Item Journal Line";
        TransShptHeader: Record "Transfer Shipment Header";
        SourceCodeSetup: Record "Source Code Setup";
        TempApplyToEntryList: Record "Item Ledger Entry" temporary;
        TempDummyItemEntryRelation: Record "Item Entry Relation" temporary;
        ItemLedgEntry: Record "Item Ledger Entry";
        Direction: Enum "Transfer Direction";
    begin
        DocLineNo := GetCorrectionLineNo(TransShptLine);

        SourceCodeSetup.Get();
        TransShptHeader.Get(TransShptLine."Document No.");

        ItemJnlLine.Init();
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Transfer;
        ItemJnlLine."Order Type" := ItemJnlLine."Order Type"::Transfer;
        ItemJnlLine."Item No." := TransShptLine."Item No.";
        ItemJnlLine."Posting Date" := TransShptHeader."Posting Date";
        ItemJnlLine."Document No." := TransShptLine."Document No.";
        ItemJnlLine."Document Line No." := DocLineNo;
        ItemJnlLine."Gen. Prod. Posting Group" := TransShptLine."Gen. Prod. Posting Group";
        ItemJnlLine."Inventory Posting Group" := TransShptLine."Inventory Posting Group";
        ItemJnlLine."Location Code" := TransShptLine."Transfer-from Code";
        ItemJnlLine."Source Code" := SourceCodeSetup.Transfer;
        ItemJnlLine.Correction := true;
        ItemJnlLine."Variant Code" := TransShptLine."Variant Code";
        ItemJnlLine."Bin Code" := TransShptLine."Transfer-from Bin Code";
        ItemJnlLine."Document Date" := TransShptHeader."Shipment Date";
        ItemJnlLine."Unit of Measure Code" := TransShptLine."Unit of Measure Code";

        WhseUndoQty.InsertTempWhseJnlLine(
                       ItemJnlLine,
                       Database::"Transfer Line", Direction::Outbound.AsInteger(), TransShptLine."Transfer Order No.", TransShptLine."Line No.",
                       TempWhseJnlLine."Reference Document"::"Posted Shipment", TempWhseJnlLine, NextLineNo);

        if GetShptEntries(TransShptLine, ItemLedgEntry) then begin
            ItemLedgEntry.SetTrackingFilterBlank();
            if ItemLedgEntry.FindSet() then begin
                // First undo In-Transit item ledger entries
                ItemLedgEntry.SetRange("Location Code", TransShptHeader."In-Transit Code");
                ItemLedgEntry.FindSet();
                PostCorrectiveItemLedgEntries(ItemJnlLine, ItemLedgEntry);

                // Then undo from-location item ledger entries
                ItemLedgEntry.SetRange("Location Code", TransShptHeader."Transfer-from Code");
                ItemLedgEntry.FindSet();
                PostCorrectiveItemLedgEntries(ItemJnlLine, ItemLedgEntry);

                exit(ItemJnlLine."Item Shpt. Entry No.");
            end
            else begin
                ItemLedgEntry.ClearTrackingFilter();
                ItemLedgEntry.FindSet();
                MoveItemLedgerEntriesToTempRec(ItemLedgEntry, TempApplyToEntryList);
                // First undo In-Transit item ledger entries
                TempApplyToEntryList.SetRange("Location Code", TransShptHeader."In-Transit Code");
                TempApplyToEntryList.FindSet();
                //Pass dummy ItemEntryRelation because, these are not used for In-Transit location
                UndoPostingMgt.PostItemJnlLineAppliedToList(
                    ItemJnlLine, TempApplyToEntryList, TransShptLine.Quantity, TransShptLine."Quantity (Base)", TempGlobalItemLedgEntry, TempDummyItemEntryRelation, false);

                // Then undo from-location item ledger entries
                TempApplyToEntryList.SetRange("Location Code", TransShptHeader."Transfer-from Code");
                TempApplyToEntryList.FindSet();
                UndoPostingMgt.PostItemJnlLineAppliedToList(
                    ItemJnlLine, TempApplyToEntryList, TransShptLine.Quantity, TransShptLine."Quantity (Base)", TempGlobalItemLedgEntry, TempGlobalItemEntryRelation, false);
            end;
        end;
        exit(0);
    end;

    local procedure MoveItemLedgerEntriesToTempRec(var ItemLedgerEntry: Record "Item Ledger Entry"; var TempItemLedgerEntry: Record "Item Ledger Entry" temporary)
    begin
        if ItemLedgerEntry.FindSet() then
            repeat
                TempItemLedgerEntry.TransferFields(ItemLedgerEntry);
                TempItemLedgerEntry.Insert();
            until ItemLedgerEntry.Next() = 0;
    end;

    local procedure PostCorrectiveItemLedgEntries(var ItemJnlLine: Record "Item Journal Line"; var ItemLedgEntry: Record "Item Ledger Entry")
    begin
        repeat
            ItemJnlLine."Applies-to Entry" := ItemLedgEntry."Entry No.";
            ItemJnlLine."Location Code" := ItemLedgEntry."Location Code";
            ItemJnlLine.Quantity := ItemLedgEntry.Quantity;
            ItemJnlLine."Quantity (Base)" := ItemLedgEntry.Quantity;
            ItemJnlLine."Invoiced Quantity" := ItemLedgEntry."Invoiced Quantity";
            ItemJnlLine."Invoiced Qty. (Base)" := ItemLedgEntry."Invoiced Quantity";
            ItemJnlPostLine.Run(ItemJnlLine);
        until ItemLedgEntry.Next() = 0;
    end;

    local procedure InsertNewShipmentLine(OldTransShptLine: Record "Transfer Shipment Line"; ItemShptEntryNo: Integer; DocLineNo: Integer)
    var
        NewTransShptLine: Record "Transfer Shipment Line";
    begin
        NewTransShptLine.Init();
        NewTransShptLine.Copy(OldTransShptLine);
        NewTransShptLine."Line No." := DocLineNo;
        NewTransShptLine."Item Shpt. Entry No." := ItemShptEntryNo;
        NewTransShptLine.Quantity := -OldTransShptLine.Quantity;
        NewTransShptLine."Quantity (Base)" := -OldTransShptLine."Quantity (Base)";
        NewTransShptLine."Correction CZA" := true;
        NewTransShptLine."Dimension Set ID" := OldTransShptLine."Dimension Set ID";
        NewTransShptLine.Insert();

        InsertItemEntryRelation(TempGlobalItemEntryRelation, NewTransShptLine, OldTransShptLine."Transfer Order Line No. CZA");
    end;

    local procedure UpdateOrderLine(TransShptLine: Record "Transfer Shipment Line")
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.Get(TransShptLine."Transfer Order No.", TransShptLine."Line No.");
        UpdateTransLine(
            TransferLine, TransShptLine.Quantity,
            TransShptLine."Quantity (Base)");
    end;

    local procedure UpdateTransLine(TransferLine: Record "Transfer Line"; UndoQty: Decimal; UndoQtyBase: Decimal)
    var
        xTransferLine: Record "Transfer Line";
        SalesSetup: Record "Sales & Receivables Setup";
        TransferLineReserve: Codeunit "Transfer Line-Reserve";
        Direction: Enum "Transfer Direction";
    begin
        SalesSetup.Get();
        xTransferLine := TransferLine;
        TransferLine."Quantity Shipped" := TransferLine."Quantity Shipped" - UndoQty;
        TransferLine."Qty. Shipped (Base)" := TransferLine."Qty. Shipped (Base)" - UndoQtyBase;
        TransferLine."Qty. to Receive" := Maximum(TransferLine."Qty. to Receive" - UndoQty, 0);
        TransferLine."Qty. to Receive (Base)" := Maximum(TransferLine."Qty. to Receive (Base)" - UndoQtyBase, 0);
        TransferLine.InitOutstandingQty();
        TransferLine.InitQtyToShip();
        TransferLine.InitQtyInTransit();

        TransferLine.Modify();
        xTransferLine."Quantity (Base)" := 0;
        TransferLineReserve.VerifyQuantity(TransferLine, xTransferLine);

        UpdateWarehouseRequest(DATABASE::"Transfer Line", Direction::Outbound.AsInteger(), TransferLine."Document No.", TransferLine."Transfer-from Code");
    end;

    local procedure Maximum(A: Decimal; B: Decimal): Decimal
    begin
        if A < B then
            exit(B);
        exit(A);
    end;

    local procedure UpdateWarehouseRequest(SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        WarehouseRequest.SetSourceFilter(SourceType, SourceSubtype, SourceNo);
        WarehouseRequest.SetRange("Location Code", LocationCode);
        if not WarehouseRequest.IsEmpty() then
            WarehouseRequest.ModifyAll("Completely Handled", false);
    end;

    local procedure InsertItemEntryRelation(var TempItemEntryRelation: Record "Item Entry Relation" temporary; NewTransShptLine: Record "Transfer Shipment Line"; OrderLineNo: Integer)
    var
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        if TempItemEntryRelation.FindFirst() then
            repeat
                ItemEntryRelation := TempItemEntryRelation;
                ItemEntryRelation.TransferFieldsTransShptLine(NewTransShptLine);
                ItemEntryRelation."Order Line No." := OrderLineNo;
                ItemEntryRelation.Insert();
            until TempItemEntryRelation.Next() = 0;
    end;

    local procedure GetShptEntries(TransShptLine: Record "Transfer Shipment Line"; var ItemLedgEntry: Record "Item Ledger Entry"): Boolean
    begin
        ItemLedgEntry.SetCurrentKey("Document No.", "Document Type", "Document Line No.");
        ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Transfer Shipment");
        ItemLedgEntry.SetRange("Document No.", TransShptLine."Document No.");
        ItemLedgEntry.SetRange("Document Line No.", TransShptLine."Line No.");
        exit(ItemLedgEntry.FindSet());
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

    local procedure GetItemList(var TransferShipmentLine: Record "Transfer Shipment Line") ItemList: Text
    var
        TransferShipmentLine2: Record "Transfer Shipment Line";
        FourPlaceholdersTok: Label '%1 %2: %3 %4\', Locked = true;
    begin
        TransferShipmentLine2.Copy(TransferShipmentLine);
        TransferShipmentLine2.SetFilter(TransferShipmentLine2."Item No.", '<>%1', '');
        TransferShipmentLine2.SetFilter(TransferShipmentLine2.Quantity, '<>%1', 0);
        if TransferShipmentLine2.FindSet() then
            repeat
                ItemList += StrSubstNo(FourPlaceholdersTok, TransferShipmentLine2."Item No.", TransferShipmentLine2.Description, TransferShipmentLine2.Quantity, TransferShipmentLine2."Unit of Measure Code");
            until TransferShipmentLine2.Next() = 0;
    end;

    procedure PostItemJnlLineAppliedToListTr(ItemJournalLine: Record "Item Journal Line"; var TempApplyToItemLedgerEntry: Record "Item Ledger Entry" temporary; UndoQty: Decimal; UndoQtyBase: Decimal; var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; var TempItemEntryRelation: Record "Item Entry Relation" temporary)
    var
#if CLEAN19
        ItemTrackingSetup: Record "Item Tracking Setup";
#endif
        ItemJnlPostLine2: Codeunit "Item Jnl.-Post Line";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        NonDistrQuantity: Decimal;
        NonDistrQuantityBase: Decimal;
        ExpDate: Date;
        DummyEntriesExist: Boolean;
    begin
        TempApplyToItemLedgerEntry.FindSet(false, false); // Assertion: will fail if not found.
        ItemJournalLine.TestField("Entry Type", ItemJournalLine."Entry Type"::Transfer);
        NonDistrQuantity := UndoQty;
        NonDistrQuantityBase := UndoQtyBase;
        repeat
            ItemJournalLine."Applies-to Entry" := 0;
            ItemJournalLine."Item Shpt. Entry No." := 0;
            ItemJournalLine."Quantity (Base)" := -TempApplyToItemLedgerEntry.Quantity;
            ItemJournalLine."Serial No." := TempApplyToItemLedgerEntry."Serial No.";
            ItemJournalLine."Lot No." := TempApplyToItemLedgerEntry."Lot No.";
            ItemJournalLine."New Serial No." := TempApplyToItemLedgerEntry."Serial No.";
            ItemJournalLine."New Lot No." := TempApplyToItemLedgerEntry."Lot No.";

            if (ItemJournalLine."Serial No." <> '') or
               (ItemJournalLine."Lot No." <> '')
            then begin
#if not CLEAN19
#pragma warning disable AL0432
                ExpDate := ItemTrackingManagement.ExistingExpirationDate(
                    ItemJournalLine."Item No.",
                    ItemJournalLine."Variant Code",
                    ItemJournalLine."Lot No.",
                    ItemJournalLine."Serial No.",
                    false, DummyEntriesExist);
#pragma warning restore AL0432
#else
                ItemTrackingSetup."Serial No." := ItemJnlLine."Serial No.";
                ItemTrackingSetup."Lot No." := ItemJnlLine."Lot No.";
                ExpDate := ItemTrackingManagement.ExistingExpirationDate(
                    ItemJournalLine."Item No.",
                    ItemJournalLine."Variant Code",
                    ItemTrackingSetup,
                    false, DummyEntriesExist);
#endif
                ItemJournalLine."New Item Expiration Date" := ExpDate;
                ItemJournalLine."Item Expiration Date" := ExpDate;
            end;

            // Quantity is filled in according to UOM:
            ItemTrackingManagement.AdjustQuantityRounding(
              NonDistrQuantity, ItemJournalLine.Quantity,
              NonDistrQuantityBase, ItemJournalLine."Quantity (Base)");

            NonDistrQuantity -= ItemJournalLine.Quantity;
            NonDistrQuantityBase -= ItemJournalLine."Quantity (Base)";

            ItemJournalLine."Invoiced Quantity" := ItemJournalLine.Quantity;
            ItemJournalLine."Invoiced Qty. (Base)" := ItemJournalLine."Quantity (Base)";

            ItemJnlPostLine2.xSetExtLotSN(true);
            ItemJnlPostLine2.RunWithCheck(ItemJournalLine);

            ItemJnlPostLine2.CollectItemEntryRelation(TempItemEntryRelation);
            TempItemLedgerEntry := TempApplyToItemLedgerEntry;
            TempItemLedgerEntry.Insert();
        until TempApplyToItemLedgerEntry.Next() = 0;
    end;

    procedure UpdateTransferLine(TransferLine: Record "Transfer Line"; UndoQty: Decimal; UndoQtyBase: Decimal; var TempUndoneItemLedgerEntry: Record "Item Ledger Entry" temporary)
    var
        TransferLine1: Record "Transfer Line";
        TransferLine2: Record "Transfer Line";
        ReservationEntry: Record "Reservation Entry";
        ItemEntryRelation: Record "Item Entry Relation";
        TransferLineReserve: Codeunit "Transfer Line-Reserve";
        Line, ResEntryNo : Integer;
    begin
        TransferLine1 := TransferLine;
        TransferLine."Quantity Shipped" := TransferLine."Quantity Shipped" - UndoQty;
        TransferLine."Qty. Shipped (Base)" := TransferLine."Qty. Shipped (Base)" - UndoQtyBase;
        TransferLine.InitQtyInTransit();
        TransferLine.InitOutstandingQty();
        TransferLine.InitQtyToShip();
        TransferLine.InitQtyToReceive();
        TransferLine.Modify();
        TransferLine1."Quantity (Base)" := 0;
        TransferLineReserve.VerifyQuantity(TransferLine, TransferLine1);

        if TempUndoneItemLedgerEntry.FindSet(false, false) then
            repeat
                if (TempUndoneItemLedgerEntry."Serial No." <> '') or (TempUndoneItemLedgerEntry."Lot No." <> '') then begin
                    ReservationEntry.Reset();
                    ReservationEntry.SetCurrentKey("Source ID");
                    ReservationEntry.SetRange("Source Type", Database::"Transfer Line");
                    ReservationEntry.SetRange("Source ID", TransferLine."Document No.");
                    ReservationEntry.SetRange("Source Batch Name", '');
                    ReservationEntry.SetRange("Source Prod. Order Line", TransferLine."Line No.");
                    ReservationEntry.SetRange("Serial No.", TempUndoneItemLedgerEntry."Serial No.");
                    ReservationEntry.SetRange("Lot No.", TempUndoneItemLedgerEntry."Lot No.");
                    while ReservationEntry.FindFirst() do begin
                        if ReservationEntry."Source Ref. No." <> 0 then
                            Line := ReservationEntry."Source Ref. No.";
                        ReservationEntry.Delete();
                    end;
                    if ItemEntryRelation.Get(TempUndoneItemLedgerEntry."Entry No.") then begin
                        ItemEntryRelation."Undo CZA" := true;
                        ItemEntryRelation.Modify();
                    end;

                    ReservationEntry.Reset();
                    Clear(ResEntryNo);
                    if ReservationEntry.FindLast() then
                        ResEntryNo := ReservationEntry."Entry No.";
                    ResEntryNo += 1;
                    ReservationEntry.Init();
                    ReservationEntry."Entry No." := ResEntryNo;
                    ReservationEntry.Positive := false;
                    ReservationEntry."Item No." := TempUndoneItemLedgerEntry."Item No.";
                    ReservationEntry."Location Code" := TransferLine."Transfer-from Code";
                    ReservationEntry."Quantity (Base)" := TempUndoneItemLedgerEntry.Quantity;
                    ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Surplus;
                    ReservationEntry."Creation Date" := Today;
                    ReservationEntry."Source Type" := Database::"Transfer Line";
                    ReservationEntry."Source Subtype" := 0;
                    ReservationEntry."Source ID" := TransferLine."Document No.";
                    ReservationEntry."Source Ref. No." := TransferLine."Line No.";
                    ReservationEntry."Expected Receipt Date" := 0D;
                    ReservationEntry."Shipment Date" := TransferLine."Shipment Date";
                    ReservationEntry."Created By" := CopyStr(UserId(), 1, StrLen(ReservationEntry."Created By"));
                    ReservationEntry."Qty. per Unit of Measure" := TempUndoneItemLedgerEntry."Qty. per Unit of Measure";
                    if TempUndoneItemLedgerEntry."Serial No." <> '' then
                        ReservationEntry.Quantity := -1
                    else
                        ReservationEntry.Quantity := ReservationEntry."Quantity (Base)" / ReservationEntry."Qty. per Unit of Measure";
                    ReservationEntry."Qty. to Handle (Base)" := ReservationEntry."Quantity (Base)";
                    ReservationEntry."Qty. to Invoice (Base)" := ReservationEntry."Quantity (Base)";
                    ReservationEntry."Lot No." := TempUndoneItemLedgerEntry."Lot No.";
                    ReservationEntry."Variant Code" := TempUndoneItemLedgerEntry."Variant Code";
                    ReservationEntry."Serial No." := TempUndoneItemLedgerEntry."Serial No.";
                    ReservationEntry.Insert();
                    ResEntryNo += 1;
                    ReservationEntry."Entry No." := ResEntryNo;
                    ReservationEntry.Positive := true;
                    ReservationEntry."Location Code" := TransferLine."Transfer-to Code";
                    ReservationEntry."Quantity (Base)" := -ReservationEntry."Quantity (Base)";
                    ReservationEntry."Source Subtype" := 1;
                    ReservationEntry."Expected Receipt Date" := TransferLine."Receipt Date";
                    ReservationEntry."Shipment Date" := 0D;
                    ReservationEntry.Quantity := -ReservationEntry.Quantity;
                    ReservationEntry."Qty. to Handle (Base)" := ReservationEntry."Quantity (Base)";
                    ReservationEntry."Qty. to Invoice (Base)" := ReservationEntry."Quantity (Base)";
                    ReservationEntry.Insert();
                end;
            until TempUndoneItemLedgerEntry.Next() = 0;
        if Line <> 0 then
            TransferLine2.SetRange("Line No.", Line);
        TransferLine2.SetRange("Document No.", TransferLine."Document No.");
        TransferLine2.SetRange("Derived From Line No.", TransferLine."Line No.");
#pragma warning disable AA0210
        TransferLine2.SetRange(Quantity, UndoQty);
#pragma warning restore AA0210
        TransferLine2.FindFirst();
        TransferLine2.Delete(true);
    end;
}
