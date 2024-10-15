﻿namespace Microsoft.Inventory.Transfer;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Comment;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Document;
using Microsoft.Utilities;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using System.Utilities;

codeunit 5704 "TransferOrder-Post Shipment"
{
    Permissions = TableData "Item Entry Relation" = i;
    TableNo = "Transfer Header";

    trigger OnRun()
    begin
        RunWithCheck(Rec);
    end;

    internal procedure RunWithCheck(var TransferHeader2: Record "Transfer Header")
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        SourceCodeSetup: Record "Source Code Setup";
        InvtCommentLine: Record "Inventory Comment Line";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        RecordLinkManagement: Codeunit "Record Link Management";
        Window: Dialog;
        LineCount: Integer;
        NextLineNo: Integer;
        WipToShip: Boolean;
        HasLinesToShip: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(TransferHeader2, HideValidationDialog, SuppressCommit, IsHandled);
        if not IsHandled then begin
            ReleaseDocument(TransferHeader2);
            TransHeader := TransferHeader2;
            TransHeader.SetHideValidationDialog(HideValidationDialog);

            OnBeforeTransferOrderPostShipment(TransHeader, SuppressCommit);

            with TransHeader do begin
                CheckBeforePost();

                WhseReference := "Posting from Whse. Ref.";
                "Posting from Whse. Ref." := 0;

                CheckShippingAdvice(TransHeader);

                CheckDim();
                TransLine.Reset();
                TransLine.SetRange("Document No.", "No.");
                TransLine.SetRange("Derived From Line No.", 0);
                WipToShip := false;
                CalcFields("Subcontracting Order");
                if "Subcontracting Order" then begin
                    TransLine.SetFilter("WIP Qty. To Ship", '<>0');
                    WipToShip := not TransLine.IsEmpty();
                    TransLine.SetRange("WIP Qty. To Ship");
                end;
                TransLine.SetFilter(Quantity, '<>0');
                TransLine.SetFilter("Qty. to Ship", '<>0');
                HasLinesToShip := not TransLine.IsEmpty();
                if not HasLinesToShip and not WipToShip then
                    Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());

                WhseShip := TempWhseShptHeader.FindFirst();
                InvtPickPutaway := WhseReference <> 0;
                if HasLinesToShip then
                    CheckItemInInventoryAndWarehouse(TransLine, not (WhseShip or InvtPickPutaway));

                CheckTransferLines(true);

                if GuiAllowed then begin
                    Window.Open(
                      '#1#################################\\' +
                      Text003);

                    Window.Update(1, StrSubstNo(Text004, "No."));
                end;

                SourceCodeSetup.Get();
                SourceCode := SourceCodeSetup.Transfer;
                InvtSetup.Get();
                InvtSetup.TestField("Posted Transfer Shpt. Nos.");

                CheckInvtPostingSetup();
                OnAfterCheckInvtPostingSetup(TransHeader, TempWhseShptHeader, SourceCode);

                LockTables(InvtSetup."Automatic Cost Posting");

                // Insert shipment header
                PostedWhseShptHeader.LockTable();
                TransShptHeader.LockTable();
                InsertTransShptHeader(TransShptHeader, TransHeader, InvtSetup."Posted Transfer Shpt. Nos.");

                if InvtSetup."Copy Comments Order to Shpt." then begin
                    InvtCommentLine.CopyCommentLines(
                        "Inventory Comment Document Type"::"Transfer Order", "No.",
                        "Inventory Comment Document Type"::"Posted Transfer Shipment", TransShptHeader."No.");
                    RecordLinkManagement.CopyLinks(TransferHeader2, TransShptHeader);
                end;

                if WhseShip then begin
                    WhseShptHeader.Get(TempWhseShptHeader."No.");
                    WhsePostShpt.CreatePostedShptHeader(PostedWhseShptHeader, WhseShptHeader, TransShptHeader."No.", "Posting Date");
                end;

                // Insert shipment lines
                OnRunOnBeforeInsertShipmentLines(WhseShptHeader, WhseShptLine);
                LineCount := 0;
                if WhseShip then
                    PostedWhseShptLine.LockTable();
                if InvtPickPutaway then
                    WhseRqst.LockTable();
                TransShptLine.LockTable();
                TransLine.SetRange(Quantity);
                TransLine.SetRange("Qty. to Ship");
                OnRunOnAfterTransLineSetFiltersForShptLines(TransLine, TransHeader, Location, WhseShip);
                if TransLine.Find('-') then
                    repeat
                        LineCount := LineCount + 1;
                        if GuiAllowed then
                            Window.Update(2, LineCount);

                        if (TransLine."Item No." <> '') and (TransLine."Qty. to Ship" <> 0) then begin
                            Item.Get(TransLine."Item No.");
                            CheckItemNotBlocked(Item);

                            if TransLine."Variant Code" <> '' then begin
                                ItemVariant.Get(TransLine."Item No.", TransLine."Variant Code");
                                CheckItemVariantNotBlocked(ItemVariant);
                            end;
                        end;

                        GetLocation(TransLine."Transfer-from Code");
                        WhsePosting :=
                            Location."Bin Mandatory" and not (WhseShip or InvtPickPutaway) and
                            (TransLine.Quantity <> 0) and (TransLine."Qty. to Ship" <> 0);

                        OnCheckTransLine(TransLine, TransHeader, Location, WhseShip, TransShptLine, InvtPickPutaway, WhsePosting);

                        InsertTransShptLine(TransShptHeader);
                    until TransLine.Next() = 0;

                MakeInventoryAdjustment();

                if WhseShip then
                    WhseShptLine.LockTable();
                TransLine.LockTable();

                OnBeforeCopyTransLines(TransHeader);

                TransLine.SetRange("Qty. to Ship");
                TransLine.SetFilter("WIP Qty. To Ship", '<>0');
                if TransLine.FindSet(true) then begin
                    repeat
                        TransLine.Validate("WIP Qty. Shipped", TransLine."WIP Qty. Shipped" + TransLine."WIP Qty. To Ship");
                        TransLine.Modify();
                    until TransLine.Next() = 0;
                end;
                TransLine.SetRange("WIP Qty. To Ship");
                TransLine.SetFilter(Quantity, '<>0');
                TransLine.SetFilter("Qty. to Ship", '<>0');
                OnAfterSetFilterTransferLine(TransLine);
                if TransLine.Find('-') then begin
                    NextLineNo := AssignLineNo(TransLine."Document No.");
                    repeat
                        IsHandled := false;
                        OnBeforeTransLineModify(TransLine, IsHandled);
                        if not IsHandled then begin
                            CopyTransLine(TransLine2, TransLine, NextLineNo, TransHeader);
                            TransferTracking(TransLine, TransLine2, TransLine."Qty. to Ship (Base)");
                            TransLine.Validate("Quantity Shipped", TransLine."Quantity Shipped" + TransLine."Qty. to Ship");
                            SetDerivedNoOnTransShptLine(TransLine, TransLine2);

                            OnBeforeUpdateWithWarehouseShipReceive(TransLine);
                            TransLine.UpdateWithWarehouseShipReceive();
                            TransLine.Modify();
                        end;
                        OnAfterTransLineModify(TransLine, TransHeader);
                    until TransLine.Next() = 0;
                end;

                OnRunOnBeforeLockTables(ItemJnlPostLine);
                if WhseShip then
                    WhseShptLine.LockTable();
                LockTable();
                if WhseShip then begin
                    WhsePostShpt.PostUpdateWhseDocuments(WhseShptHeader);
                    TempWhseShptHeader.Delete();
                end;

                "Last Shipment No." := TransShptHeader."No.";
                Modify();

                FinalizePosting(TransHeader, TransLine);

                OnRunOnBeforeCommit(TransHeader, TransShptHeader, PostedWhseShptHeader, SuppressCommit);
                if not (InvtPickPutaway or "Direct Transfer" or SuppressCommit or PreviewMode) then begin
                    Commit();
                    UpdateAnalysisView.UpdateAll(0, true);
                    UpdateItemAnalysisView.UpdateAll(0, true);
                end;
                Clear(WhsePostShpt);

                if GuiAllowed() then
                    Window.Close();
            end;

            TransferHeader2 := TransHeader;
        end;
        OnAfterTransferOrderPostShipment(TransferHeader2, SuppressCommit, TransShptHeader, InvtPickPutaway);
    end;

    var
        Text002: Label 'Warehouse handling is required for Transfer order = %1, %2 = %3.';
        Text003: Label 'Posting transfer lines     #2######';
        Text004: Label 'Transfer Order %1';
        Text005: Label 'The combination of dimensions used in transfer order %1 is blocked. %2';
        Text006: Label 'The combination of dimensions used in transfer order %1, line no. %2 is blocked. %3';
        Text007: Label 'The dimensions that are used in transfer order %1, line no. %2 are not valid. %3.';
        InvtSetup: Record "Inventory Setup";
        TransShptHeader: Record "Transfer Shipment Header";
        TransShptLine: Record "Transfer Shipment Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        TransLine2: Record "Transfer Line";
        Location: Record Location;
        ItemJnlLine: Record "Item Journal Line";
        WhseRqst: Record "Warehouse Request";
        WhseShptHeader: Record "Warehouse Shipment Header";
        TempWhseShptHeader: Record "Warehouse Shipment Header" temporary;
        WhseShptLine: Record "Warehouse Shipment Line";
        PostedWhseShptHeader: Record "Posted Whse. Shipment Header";
        PostedWhseShptLine: Record "Posted Whse. Shipment Line";
        TempWhseSplitSpecification: Record "Tracking Specification" temporary;
        TempHandlingSpecification: Record "Tracking Specification" temporary;
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        DimMgt: Codeunit DimensionManagement;
        WhseTransferRelease: Codeunit "Whse.-Transfer Release";
        ReserveTransLine: Codeunit "Transfer Line-Reserve";
        WhsePostShpt: Codeunit "Whse.-Post Shipment";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        UOMMgt: Codeunit "Unit of Measure Management";
        SourceCode: Code[10];
        WhseShip: Boolean;
        WhsePosting: Boolean;
        InvtPickPutaway: Boolean;
        WhseReference: Integer;
        OriginalQuantity: Decimal;
        OriginalQuantityBase: Decimal;
        Text008: Label 'This order must be a complete shipment.';
        Text009: Label 'Item %1 is not in inventory.';
        SuppressCommit: Boolean;
        HideValidationDialog: Boolean;
        PreviewMode: Boolean;

    local procedure PostItem(var TransferLine: Record "Transfer Line"; TransShptHeader2: Record "Transfer Shipment Header"; TransShptLine2: Record "Transfer Shipment Line"; WhseShip: Boolean; WhseShptHeader2: Record "Warehouse Shipment Header")
    var
        IsHandled: Boolean;
    begin
        OnBeforePostItem(TransShptHeader2, IsHandled, TransferLine, TransShptLine2, WhseShip, WhseShptHeader2, ItemJnlPostLine, WhseJnlRegisterLine);
        if IsHandled then
            exit;

        CreateItemJnlLine(ItemJnlLine, TransferLine, TransShptHeader2, TransShptLine2);
        ReserveItemJnlLine(ItemJnlLine, TransferLine, WhseShip, WhseShptHeader2);

        OnBeforePostItemJournalLine(ItemJnlLine, TransferLine, TransShptHeader2, TransShptLine2, SuppressCommit);
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
    end;

    local procedure CreateItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; TransferLine: Record "Transfer Line"; TransShptHeader2: Record "Transfer Shipment Header"; TransShptLine2: Record "Transfer Shipment Line")
    begin
        with ItemJnlLine do begin
            Init();
            CopyDocumentFields(
              "Document Type"::"Transfer Shipment", TransShptHeader2."No.", TransShptHeader2."External Document No.", SourceCode, '');
            "Posting Date" := TransShptHeader2."Posting Date";
            "Document Date" := TransShptHeader2."Posting Date";
            "Document Line No." := TransShptLine2."Line No.";
            "Order Type" := "Order Type"::Transfer;
            "Order No." := TransShptHeader2."Transfer Order No.";
            "Order Line No." := TransferLine."Line No.";
            "Prod. Order No." := TransShptLine2."Prod. Order No.";
            "Prod. Order Line No." := TransShptLine2."Prod. Order Line No.";
            "Entry Type" := "Entry Type"::Transfer;
            "Item No." := TransShptLine2."Item No.";
            "Variant Code" := TransShptLine2."Variant Code";
            Description := TransShptLine2.Description;
            "Location Code" := TransShptHeader2."Transfer-from Code";
            "New Location Code" := TransHeader."In-Transit Code";
            "Bin Code" := TransLine."Transfer-from Bin Code";
            "Shortcut Dimension 1 Code" := TransShptLine2."Shortcut Dimension 1 Code";
            "New Shortcut Dimension 1 Code" := TransShptLine2."Shortcut Dimension 1 Code";
            "Shortcut Dimension 2 Code" := TransShptLine2."Shortcut Dimension 2 Code";
            "New Shortcut Dimension 2 Code" := TransShptLine2."Shortcut Dimension 2 Code";
            "Dimension Set ID" := TransShptLine2."Dimension Set ID";
            "New Dimension Set ID" := TransShptLine2."Dimension Set ID";
            Quantity := TransShptLine2.Quantity;
            "Invoiced Quantity" := TransShptLine2.Quantity;
            "Quantity (Base)" := TransShptLine2."Quantity (Base)";
            "Invoiced Qty. (Base)" := TransShptLine2."Quantity (Base)";
            "Gen. Prod. Posting Group" := TransShptLine2."Gen. Prod. Posting Group";
            "Inventory Posting Group" := TransShptLine2."Inventory Posting Group";
            "Unit of Measure Code" := TransShptLine2."Unit of Measure Code";
            "Qty. per Unit of Measure" := TransShptLine2."Qty. per Unit of Measure";
            "Country/Region Code" := TransShptHeader2."Trsf.-from Country/Region Code";
            "Transaction Type" := TransShptHeader2."Transaction Type";
            "Transport Method" := TransShptHeader2."Transport Method";
            "Entry/Exit Point" := TransShptHeader2."Entry/Exit Point";
            Area := TransShptHeader2.Area;
            "Transaction Specification" := TransShptHeader2."Transaction Specification";
            "Item Category Code" := TransferLine."Item Category Code";
            "Applies-to Entry" := TransferLine."Appl.-to Item Entry";
            "Shpt. Method Code" := TransShptHeader2."Shipment Method Code";
            "Direct Transfer" := TransferLine."Direct Transfer";
            "Reason Code" := TransShptHeader2."Reason Code";
            "Source No." := TransShptHeader2."Source No.";
            "Source Type" := TransShptHeader2."Source Type";
            "Prod. Order Comp. Line No." := TransShptLine2."Prod. Order Comp. Line No.";
            "Subcontr. Purch. Order No." := TransShptLine2."Subcontr. Purch. Order No.";
            "Subcontr. Purch. Order Line" := TransShptLine2."Subcontr. Purch. Order Line";
        end;

        OnAfterCreateItemJnlLine(ItemJnlLine, TransferLine, TransShptHeader2, TransShptLine2);
    end;

    local procedure SetDerivedNoOnTransShptLine(TransferLine: Record "Transfer Line"; DerivedTransferLine: Record "Transfer Line")
    var
        TransShptLineLocal: Record "Transfer Shipment Line";
    begin
        TransShptLineLocal.SetLoadFields("Trans. Order Line No.", "Derived Trans. Order Line No.");
        TransShptLineLocal.SetRange("Document No.", TransShptHeader."No.");
        TransShptLineLocal.SetRange("Trans. Order Line No.", TransferLine."Line No.");
        if TransShptLineLocal.FindFirst() then begin
            TransShptLineLocal."Derived Trans. Order Line No." := DerivedTransferLine."Line No.";
            TransShptLineLocal.Modify();
        end;
    end;

    local procedure CheckItemNotBlocked(var Item: Record Item)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemNotBlocked(TransLine, Item, Transheader, Location, WhseShip, IsHandled);
        if IsHandled then
            exit;

        Item.TestField(Blocked, false);
    end;

    local procedure CheckItemVariantNotBlocked(var ItemVariant: Record "Item Variant")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemVariantNotBlocked(TransLine, ItemVariant, Transheader, Location, WhseShip, IsHandled);
        if IsHandled then
            exit;

        ItemVariant.TestField(Blocked, false);
    end;

    local procedure ReserveItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; var TransferLine: Record "Transfer Line"; WhseShip: Boolean; WhseShptHeader2: Record "Warehouse Shipment Header")
    begin
        GetLocation(TransferLine."Transfer-from Code");
        if WhseShip and (WhseShptHeader2."Document Status" = WhseShptHeader2."Document Status"::"Partially Picked") and
           Location."Bin Mandatory"
        then
            ReserveTransLine.TransferWhseShipmentToItemJnlLine(
              TransferLine, ItemJnlLine, WhseShptHeader2, ItemJnlLine."Quantity (Base)")
        else
            ReserveTransLine.TransferTransferToItemJnlLine(
              TransferLine, ItemJnlLine, ItemJnlLine."Quantity (Base)", Enum::"Transfer Direction"::Outbound);
    end;

    local procedure CheckDim()
    begin
        TransLine."Line No." := 0;
        CheckDimComb(TransHeader, TransLine);
        CheckDimValuePosting(TransHeader, TransLine);

        TransLine.SetRange("Document No.", TransHeader."No.");
        if TransLine.FindFirst() then begin
            CheckDimComb(TransHeader, TransLine);
            CheckDimValuePosting(TransHeader, TransLine);
        end;
    end;

    local procedure CheckDimComb(TransferHeader: Record "Transfer Header"; TransferLine: Record "Transfer Line")
    begin
        if TransferLine."Line No." = 0 then
            if not DimMgt.CheckDimIDComb(TransferHeader."Dimension Set ID") then
                Error(
                  Text005,
                  TransHeader."No.", DimMgt.GetDimCombErr());
        if TransferLine."Line No." <> 0 then
            if not DimMgt.CheckDimIDComb(TransferLine."Dimension Set ID") then
                Error(
                  Text006,
                  TransHeader."No.", TransferLine."Line No.", DimMgt.GetDimCombErr());

        OnAfterCheckDimComb(TransferHeader, TransferLine);
    end;

    local procedure CheckDimValuePosting(TransferHeader: Record "Transfer Header"; TransferLine: Record "Transfer Line")
    var
        TableIDArr: array[10] of Integer;
        NumberArr: array[10] of Code[20];
        IsHandled: Boolean;
    begin
        OnBeforeCheckDimValuePosting(TransferHeader, TransferLine, IsHandled);
        if IsHandled then
            exit;

        TableIDArr[1] := DATABASE::Item;
        NumberArr[1] := TransferLine."Item No.";
        TableIDArr[2] := DATABASE::Location;
        NumberArr[2] := TransferLine."Transfer-from Code";
        if TransferLine."Line No." = 0 then
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, TransferHeader."Dimension Set ID") then
                Error(Text007, TransHeader."No.", TransferLine."Line No.", DimMgt.GetDimValuePostingErr());

        if TransferLine."Line No." <> 0 then
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, TransferLine."Dimension Set ID") then
                Error(Text007, TransHeader."No.", TransferLine."Line No.", DimMgt.GetDimValuePostingErr());
    end;

    local procedure FinalizePosting(var TransHeader: Record "Transfer Header"; var TransLine: Record "Transfer Line")
    var
        DeleteOne: Boolean;
    begin
        OnBeforeFinalizePosting(TransHeader, PostedWhseShptHeader, WhseShip);
        TransLine.SetRange(Quantity);
        TransLine.SetRange("Qty. to Ship");
        DeleteOne := TransHeader.ShouldDeleteOneTransferOrder(TransLine);
        OnBeforeDeleteOneTransferOrder(TransHeader, DeleteOne);
        if DeleteOne then
            TransHeader.DeleteOneTransferOrder(TransHeader, TransLine)
        else begin
            WhseTransferRelease.Release(TransHeader);
            ReserveTransLine.UpdateItemTrackingAfterPosting(TransHeader, Enum::"Transfer Direction"::Outbound);
        end;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    local procedure AssignLineNo(FromDocNo: Code[20]): Integer
    var
        TransLine3: Record "Transfer Line";
    begin
        TransLine3.SetRange("Document No.", FromDocNo);
        if TransLine3.FindLast() then
            exit(TransLine3."Line No." + 10000);
    end;

    local procedure InsertShptEntryRelation(var TransShptLine: Record "Transfer Shipment Line") Result: Integer
    var
        TempHandlingSpecification2: Record "Tracking Specification" temporary;
        ItemEntryRelation: Record "Item Entry Relation";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WhseSplitSpecification: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertShptEntryRelation(TransShptLine, TransLine, ItemJnlLine, WhsePosting, ItemJnlPostLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if WhsePosting then begin
            TempWhseSplitSpecification.Reset();
            TempWhseSplitSpecification.DeleteAll();
        end;

        TempHandlingSpecification2.Reset();
        if ItemJnlPostLine.CollectTrackingSpecification(TempHandlingSpecification2) then begin
            TempHandlingSpecification2.SetRange("Buffer Status", 0);
            if TempHandlingSpecification2.Find('-') then begin
                repeat
                    WhseSplitSpecification := WhsePosting or WhseShip or InvtPickPutaway;
                    OnInsertShptEntryRelationOnAfterCalcWhseSplitSpecification(
                        TransLine, TransShptLine, TempHandlingSpecification2, TempWhseSplitSpecification, WhsePosting, WhseShip, InvtPickPutaway, WhseSplitSpecification);
                    if WhseSplitSpecification then begin
                        if ItemTrackingMgt.GetWhseItemTrkgSetup(TransShptLine."Item No.") then begin
                            TempWhseSplitSpecification := TempHandlingSpecification2;
                            TempWhseSplitSpecification."Source Type" := DATABASE::"Transfer Line";
                            TempWhseSplitSpecification."Source ID" := TransLine."Document No.";
                            TempWhseSplitSpecification."Source Ref. No." := TransLine."Line No.";
                            TempWhseSplitSpecification.Insert();
                        end;
                    end;

                    ItemEntryRelation.InitFromTrackingSpec(TempHandlingSpecification2);
                    ItemEntryRelation.TransferFieldsTransShptLine(TransShptLine);
                    ItemEntryRelation.Insert();
                    TempHandlingSpecification := TempHandlingSpecification2;
                    TempHandlingSpecification."Source Prod. Order Line" := TransShptLine."Line No.";
                    TempHandlingSpecification."Buffer Status" := TempHandlingSpecification."Buffer Status"::MODIFY;
                    TempHandlingSpecification.Insert();
                until TempHandlingSpecification2.Next() = 0;
                OnAfterInsertShptEntryRelation(TransLine, WhseShip, 0, SuppressCommit);
                exit(0);
            end;
        end else begin
            OnAfterInsertShptEntryRelation(TransLine, WhseShip, ItemJnlLine."Item Shpt. Entry No.", SuppressCommit);
            exit(ItemJnlLine."Item Shpt. Entry No.");
        end;
    end;

    local procedure InsertTransShptHeader(var TransShptHeader: Record "Transfer Shipment Header"; var TransHeader: Record "Transfer Header"; NoSeries: Code[20])
    var
        TransportReasonCode: Record "Transport Reason Code";
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        TransShptHeader.Init();
        TransShptHeader.CopyFromTransferHeader(TransHeader);
        TransShptHeader."No. Series" := NoSeries;
        if TransHeader."Transport Reason Code" <> '' then begin
            TransportReasonCode.Get(TransHeader."Transport Reason Code");
            if TransportReasonCode."Posted Shpt. Nos." <> '' then
                TransShptHeader."No. Series" := TransportReasonCode."Posted Shpt. Nos.";
        end else
            TransportReasonCode.Init();
        TransShptHeader."Transport Reason Code" := TransHeader."Transport Reason Code";
        TransShptHeader."Reason Code" := TransportReasonCode."Reason Code";

        OnBeforeGenNextNo(TransShptHeader, TransHeader);
        if TransShptHeader."No." = '' then
            TransShptHeader."No." := NoSeriesMgt.GetNextNo(TransShptHeader."No. Series", TransHeader."Posting Date", true);
        OnBeforeInsertTransShptHeader(TransShptHeader, TransHeader, SuppressCommit);
        TransShptHeader.Insert();
        OnAfterInsertTransShptHeader(TransHeader, TransShptHeader);
    end;

    local procedure InsertTransShptLine(TransShptHeader: Record "Transfer Shipment Header")
    var
        TransShptLine: Record "Transfer Shipment Line";
        PurchOrderLine: Record "Purchase Line";
        IsHandled: Boolean;
        ShouldRunPosting: Boolean;
    begin
        OnBeforeInsertTransShipmentLine(TransLine);

        TransShptLine.Init();
        TransShptLine."Document No." := TransShptHeader."No.";
        TransShptLine.CopyFromTransferLine(TransLine);
        TransShptLine."Subcontr. Purch. Order No." := TransLine."Subcontr. Purch. Order No.";
        TransShptLine."Subcontr. Purch. Order Line" := TransLine."Subcontr. Purch. Order Line";
        TransShptLine."Prod. Order No." := TransLine."Prod. Order No.";
        TransShptLine."Prod. Order Line No." := TransLine."Prod. Order Line No.";
        TransShptLine."Prod. Order Comp. Line No." := TransLine."Prod. Order Comp. Line No.";
        if TransLine."WIP Item" then begin
            TransShptLine.Quantity := TransLine."WIP Qty. To Ship";
            TransShptLine."Quantity (Base)" :=
              Round(TransShptLine.Quantity * TransLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
            if TransShptLine.Quantity > 0 then
                if PurchOrderLine.Get(PurchOrderLine."Document Type"::Order,
                     TransShptLine."Subcontr. Purch. Order No.",
                     TransShptLine."Subcontr. Purch. Order Line")
                then begin
                    PurchOrderLine."Not Proc. WIP Qty to Receive" := TransShptLine.Quantity;
                    PurchOrderLine.Modify();
                end;
        end;
        TransShptLine."WIP Item" := TransLine."WIP Item";
        TransShptLine."Routing No." := TransLine."Routing No.";
        TransShptLine."Routing Reference No." := TransLine."Routing Reference No.";
        TransShptLine."Work Center No." := TransLine."Work Center No.";
        TransShptLine."Operation No." := TransLine."Operation No.";
        TransShptLine."Return Order" := TransLine."Return Order";
        if TransShptLine.Quantity > 0 then begin
            OriginalQuantity := TransLine."Qty. to Ship";
            OriginalQuantityBase := TransLine."Qty. to Ship (Base)";
            if not TransLine."WIP Item" then
                PostItem(TransLine, TransShptHeader, TransShptLine, WhseShip, WhseShptHeader)
            else
                PostWIPItemJnlLine(TransLine, TransShptHeader, TransShptLine);
            TransShptLine."Item Shpt. Entry No." := InsertShptEntryRelation(TransShptLine);
            if WhseShip then begin
                WhseShptLine.SetCurrentKey(
                  "No.", "Source Type", "Source Subtype", "Source No.", "Source Line No.");
                WhseShptLine.SetRange("No.", WhseShptHeader."No.");
                WhseShptLine.SetRange("Source Type", DATABASE::"Transfer Line");
                WhseShptLine.SetRange("Source No.", TransLine."Document No.");
                WhseShptLine.SetRange("Source Line No.", TransLine."Line No.");
                if WhseShptLine.FindFirst() then
                    CreatePostedShptLineFromWhseShptLine(TransShptLine);
            end;
            ShouldRunPosting := WhsePosting;
            OnInsertTransShptLineOnBeforePostWhseJnlLine(TransShptLine, TransLine, SuppressCommit, WhsePosting, ShouldRunPosting);
            if ShouldRunPosting then
                PostWhseJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase);
        end;

        IsHandled := false;
        OnBeforeInsertTransShptLine(TransShptLine, TransLine, SuppressCommit, IsHandled, TransShptHeader);
        if IsHandled then
            exit;

        TransShptLine.Insert();
        OnAfterInsertTransShptLine(TransShptLine, TransLine, SuppressCommit, TransShptHeader);
    end;

    local procedure CreatePostedShptLineFromWhseShptLine(var TransferShipmentLine: Record "Transfer Shipment Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreatePostedShptLineFromWhseShptLine(TransferShipmentLine, WhseShptLine, PostedWhseShptHeader, PostedWhseShptLine, TempWhseSplitSpecification, IsHandled, WhseJnlRegisterLine, WhsePostShpt);
        if IsHandled then
            exit;

        WhseShptLine.TestField("Qty. to Ship", TransferShipmentLine.Quantity);
        WhsePostShpt.CreatePostedShptLine(
          WhseShptLine, PostedWhseShptHeader, PostedWhseShptLine, TempWhseSplitSpecification);

        OnInsertTransShptLineOnAfterCreatePostedShptLine(WhseShptLine, PostedWhseShptLine);
    end;

    local procedure TransferTracking(var FromTransLine: Record "Transfer Line"; var ToTransLine: Record "Transfer Line"; TransferQty: Decimal)
    var
        DummySpecification: Record "Tracking Specification";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferTracking(FromTransLine, ToTransLine, TransferQty, IsHandled);
        if IsHandled then
            exit;

        TempHandlingSpecification.Reset();
        TempHandlingSpecification.SetRange("Source Prod. Order Line", ToTransLine."Derived From Line No.");
        if TempHandlingSpecification.Find('-') then begin
            repeat
                ReserveTransLine.TransferTransferToTransfer(
                  FromTransLine, ToTransLine, -TempHandlingSpecification."Quantity (Base)", Enum::"Transfer Direction"::Inbound, TempHandlingSpecification);
                TransferQty += TempHandlingSpecification."Quantity (Base)";
            until TempHandlingSpecification.Next() = 0;
            TempHandlingSpecification.DeleteAll();
        end;

        OnTransferTrackingOnBeforeReserveTransferToTransfer(FromTransLine, ToTransLine, TransferQty);

        if TransferQty > 0 then
            ReserveTransLine.TransferTransferToTransfer(
              FromTransLine, ToTransLine, TransferQty, Enum::"Transfer Direction"::Inbound, DummySpecification);
    end;

    local procedure CheckWarehouse(TransLine: Record "Transfer Line")
    var
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        ShowError: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWarehouse(TransLine, IsHandled);
        if IsHandled then
            exit;

        GetLocation(TransLine."Transfer-from Code");
        if Location."Require Pick" or Location."Require Shipment" then begin
            if Location."Bin Mandatory" then
                ShowError := true
            else
                if WhseValidateSourceLine.WhseLinesExist(
                     DATABASE::"Transfer Line",
                     0,// Out
                     TransLine."Document No.",
                     TransLine."Line No.",
                     0,
                     TransLine.Quantity)
                then
                    ShowError := true;

            if ShowError then
                Error(
                  Text002,
                  TransLine."Document No.",
                  TransLine.FieldCaption("Line No."),
                  TransLine."Line No.");
        end;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Location.GetLocationSetup(LocationCode, Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure PostWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; OriginalQuantity: Decimal; OriginalQuantityBase: Decimal)
    var
        WhseJnlLine: Record "Warehouse Journal Line";
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WMSMgmt: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostWhseJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase, IsHandled);
        if IsHandled then
            exit;

        with ItemJnlLine do begin
            Quantity := OriginalQuantity;
            "Quantity (Base)" := OriginalQuantityBase;
            GetLocation("Location Code");
            if Location."Bin Mandatory" then
                if WMSMgmt.CreateWhseJnlLine(ItemJnlLine, 1, WhseJnlLine, false) then begin
                    WMSMgmt.SetTransferLine(TransLine, WhseJnlLine, 0, TransShptHeader."No.");
                    OnPostWhseJnlLineOnBeforeSplitWhseJnlLine();
                    ItemTrackingMgt.SplitWhseJnlLine(
                      WhseJnlLine, TempWhseJnlLine2, TempWhseSplitSpecification, true);
                    if TempWhseJnlLine2.Find('-') then
                        repeat
                            WMSMgmt.CheckWhseJnlLine(TempWhseJnlLine2, 1, 0, true);
                            WhseJnlRegisterLine.RegisterWhseJnlLine(TempWhseJnlLine2);
                        until TempWhseJnlLine2.Next() = 0;
                end;
        end;
    end;

    procedure SetWhseShptHeader(var WhseShptHeader2: Record "Warehouse Shipment Header")
    begin
        WhseShptHeader := WhseShptHeader2;
        TempWhseShptHeader := WhseShptHeader;
        TempWhseShptHeader.Insert();
    end;

    local procedure GetShippingAdvice(): Boolean
    var
        TransLine: Record "Transfer Line";
    begin
        TransLine.SetRange("Document No.", TransHeader."No.");
        if TransLine.Find('-') then
            repeat
                if TransLine."Quantity (Base)" <>
                   TransLine."Qty. to Ship (Base)" + TransLine."Qty. Shipped (Base)"
                then
                    exit(false);
            until TransLine.Next() = 0;
        exit(true);
    end;

    local procedure CheckItemInInventory(TransLine: Record "Transfer Line")
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemInInventory(TransLine, IsHandled);
        if IsHandled then
            exit;

        with Item do begin
            Get(TransLine."Item No.");
            SetRange("Variant Filter", TransLine."Variant Code");
            SetRange("Location Filter", TransLine."Transfer-from Code");
            CalcFields(Inventory);
            if Inventory <= 0 then
                Error(Text009, TransLine."Item No.");
        end;
    end;

    local procedure CheckItemInInventoryAndWarehouse(var TransLine: Record "Transfer Line"; NeedCheckWarehouse: Boolean)
    var
        TransLine2: Record "Transfer Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemInInventoryAndWarehouse(TransLine, NeedCheckWarehouse, IsHandled);
        if IsHandled then
            exit;

        TransLine2.CopyFilters(TransLine);
        TransLine2.FindSet();
        repeat
            CheckItemInInventory(TransLine2);
            if NeedCheckWarehouse then
                CheckWarehouse(TransLine2);
        until TransLine2.Next() = 0;
    end;

    local procedure CheckShippingAdvice(var TransferHeader: Record "Transfer Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckHeaderShippingAdvice(TransferHeader, IsHandled);
        if IsHandled then
            exit;

        if TransferHeader."Shipping Advice" = TransferHeader."Shipping Advice"::Complete then
            if not GetShippingAdvice() then
                Error(Text008);
    end;

    local procedure LockTables(AutoCostPosting: Boolean)
    var
        GLEntry: Record "G/L Entry";
    begin
        if AutoCostPosting then begin
            GLEntry.LockTable();
            if GLEntry.FindLast() then;
        end;
    end;

    local procedure CopyTransLine(var NewTransferLine: Record "Transfer Line"; TransferLine: Record "Transfer Line"; var NextLineNo: Integer; TransferHeader: Record "Transfer Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyTransLine(NewTransferLine, TransferLine, NextLineNo, TransferHeader, IsHandled);
        if IsHandled then
            exit;

        NewTransferLine.Init();
        NewTransferLine := TransferLine;
        if TransferHeader."In-Transit Code" <> '' then
            NewTransferLine."Transfer-from Code" := TransferLine."In-Transit Code";
        NewTransferLine."In-Transit Code" := '';
        NewTransferLine."Derived From Line No." := TransferLine."Line No.";
        NewTransferLine."Line No." := NextLineNo;
        NextLineNo := NextLineNo + 10000;
        NewTransferLine.Quantity := TransferLine."Qty. to Ship";
        NewTransferLine."Quantity (Base)" := TransferLine."Qty. to Ship (Base)";
        NewTransferLine."Qty. to Ship" := NewTransferLine.Quantity;
        NewTransferLine."Qty. to Ship (Base)" := NewTransferLine."Quantity (Base)";
        NewTransferLine."Qty. to Receive" := NewTransferLine.Quantity;
        NewTransferLine."Qty. to Receive (Base)" := NewTransferLine."Quantity (Base)";
        NewTransferLine.ResetPostedQty();
        NewTransferLine."Outstanding Quantity" := NewTransferLine.Quantity;
        NewTransferLine."Outstanding Qty. (Base)" := NewTransferLine."Quantity (Base)";
        OnBeforeNewTransferLineInsert(NewTransferLine, TransferLine, NextLineNo);
        NewTransferLine.Insert();
        OnAfterCopyTransLine(NewTransferLine, TransferLine);
    end;

    local procedure ReleaseDocument(var TransferHeader: Record "Transfer Header")
    var
        ReleaseTransferDocument: Codeunit "Release Transfer Document";
    begin
        OnBeforeReleaseDocument(TransferHeader);

        if TransferHeader.Status = TransferHeader.Status::Open then begin
            ReleaseTransferDocument.Release(TransferHeader);
            TransferHeader.Status := TransferHeader.Status::Open;
            TransferHeader.Modify();
            if not (SuppressCommit or PreviewMode) then
                Commit();
            TransferHeader.Status := TransferHeader.Status::Released;
        end;
    end;

    [Scope('OnPrem')]
    procedure PostWIPItemJnlLine(var TransLine3: Record "Transfer Line"; TransShptHeader2: Record "Transfer Shipment Header"; TransShptLine2: Record "Transfer Shipment Line")
    begin
        ItemJnlLine.Init();
        ItemJnlLine."Posting Date" := TransShptHeader2."Posting Date";
        ItemJnlLine."Document Date" := TransShptHeader2."Posting Date";
        ItemJnlLine."Document No." := TransShptLine2."Prod. Order No.";
        ItemJnlLine."Order Type" := ItemJnlLine."Order Type"::Production;
        ItemJnlLine."Order No." := TransShptLine2."Prod. Order No.";
        ItemJnlLine."External Document No." := TransShptHeader2."External Document No.";
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Output;
        ItemJnlLine."Item No." := TransShptLine2."Item No.";
        ItemJnlLine.Description := TransShptLine2.Description;
        ItemJnlLine."Shortcut Dimension 1 Code" := TransShptLine2."Shortcut Dimension 1 Code";
        ItemJnlLine."Shortcut Dimension 2 Code" := TransShptLine2."Shortcut Dimension 2 Code";
        ItemJnlLine."Source Code" := SourceCode;
        ItemJnlLine."Gen. Prod. Posting Group" := TransShptLine2."Gen. Prod. Posting Group";
        ItemJnlLine."Inventory Posting Group" := TransShptLine2."Inventory Posting Group";
        ItemJnlLine."Unit of Measure Code" := TransShptLine2."Unit of Measure Code";
        ItemJnlLine."Qty. per Unit of Measure" := TransShptLine2."Qty. per Unit of Measure";
        ItemJnlLine."Variant Code" := TransShptLine2."Variant Code";
        ItemJnlLine."Reason Code" := TransShptHeader2."Reason Code";
        ItemJnlLine."Order Line No." := TransShptLine2."Prod. Order Line No.";
        ItemJnlLine.Type := ItemJnlLine.Type::"Work Center";
        ItemJnlLine."No." := TransShptLine2."Work Center No.";
        ItemJnlLine."Routing No." := TransShptLine2."Routing No.";
        ItemJnlLine."Routing Reference No." := TransShptLine2."Routing Reference No.";
        ItemJnlLine."Source No." := TransShptHeader2."Source No.";
        ItemJnlLine."Source Type" := TransShptHeader2."Source Type";
        ItemJnlLine."Work Center No." := TransShptLine2."Work Center No.";
        ItemJnlLine."Operation No." := TransShptLine2."Operation No.";
        ItemJnlLine."WIP Quantity" := TransShptLine2."Quantity (Base)";
        if TransShptLine2."Return Order" then
            ItemJnlLine."WIP Quantity" := ItemJnlLine."WIP Quantity" * -1;
        ItemJnlLine."WIP Item" := TransShptLine2."WIP Item";
        ItemJnlLine."Subcontr. Purch. Order No." := TransShptLine2."Subcontr. Purch. Order No.";
        ItemJnlLine."Subcontr. Purch. Order Line" := TransShptLine2."Subcontr. Purch. Order Line";
        ItemJnlLine."Dimension Set ID" := TransShptLine2."Dimension Set ID";

        OnPostWIPItemJnlLineOnBeforeRunWithCheck(ItemJnlLine, TransShptHeader2, TransShptLine2);

        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
    end;

    local procedure MakeInventoryAdjustment()
    var
        InvtAdjmtHandler: Codeunit "Inventory Adjustment Handler";
    begin
        InvtSetup.Get();
        if InvtSetup.AutomaticCostAdjmtRequired() then begin
            InvtAdjmtHandler.MakeInventoryAdjustment(true, InvtSetup."Automatic Cost Posting");
            OnAfterInvtAdjmt(TransHeader, TransShptHeader);
        end;
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    internal procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; TransferLine: Record "Transfer Line"; TransferShipmentHeader: Record "Transfer Shipment Header"; TransferShipmentLine: Record "Transfer Shipment Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeTransferOrderPostShipment(var TransferHeader: Record "Transfer Header"; var CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemNotBlocked(TransferLine: Record "Transfer Line"; Item: Record Item; TransferHeader: Record "Transfer Header"; Location: Record Location; WhseShip: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemVariantNotBlocked(TransferLine: Record "Transfer Line"; ItemVariant: Record "Item Variant"; TransferHeader: Record "Transfer Header"; Location: Record Location; WhseShip: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var TransferHeader: Record "Transfer Header"; var HideValidationDialog: Boolean; var SuppressCommit: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckInvtPostingSetup(var TransferHeader: Record "Transfer Header"; var TempWhseShipmentHeader: Record "Warehouse Shipment Header" temporary; var SourceCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; TransferLine: Record "Transfer Line"; TransferShipmentHeader: Record "Transfer Shipment Header"; TransferShipmentLine: Record "Transfer Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTransLine(var NewTransferLine: Record "Transfer Line"; TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInvtAdjmt(var TransferHeader: Record "Transfer Header"; var TransferShipmentHeader: Record "Transfer Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransLineModify(var TransferLine: Record "Transfer Line"; var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferOrderPostShipment(var TransferHeader: Record "Transfer Header"; CommitIsSuppressed: Boolean; var TransferShipmentHeader: Record "Transfer Shipment Header"; InvtPickPutaway: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertShptEntryRelation(var TransLine: Record "Transfer Line"; WhseShip: Boolean; EntryNo: Integer; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertTransShptHeader(var TransferHeader: Record "Transfer Header"; var TransferShipmentHeader: Record "Transfer Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertTransShptLine(var TransShptLine: Record "Transfer Shipment Line"; TransLine: Record "Transfer Line"; CommitIsSuppressed: Boolean; TransShptHeader: Record "Transfer Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTransShptHeader(var TransShptHeader: Record "Transfer Shipment Header"; TransHeader: Record "Transfer Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDimValuePosting(TransferHeader: Record "Transfer Header"; TransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWarehouse(TransLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemInInventoryAndWarehouse(var TransLine: Record "Transfer Line"; NeedCheckWarehouse: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyTransLines(TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyTransLine(var NewTransferLine: Record "Transfer Line"; TransferLine: Record "Transfer Line"; var NextLineNo: Integer; TransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePostedShptLineFromWhseShptLine(var TransShptLine: Record "Transfer Shipment Line"; var WhseShptLine: Record "Warehouse Shipment Line"; var PostedWhseShptHeader: Record "Posted Whse. Shipment Header"; var PostedWhseShptLine: Record "Posted Whse. Shipment Line"; var TempWhseSplitSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line"; var WhsePostShpt: Codeunit "Whse.-Post Shipment")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTransShptLine(var TransShptLine: Record "Transfer Shipment Line"; TransLine: Record "Transfer Line"; CommitIsSuppressed: Boolean; var IsHandled: Boolean; TransShptHeader: Record "Transfer Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteOneTransferOrder(TransferHeader: Record "Transfer Header"; var DeleteOne: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinalizePosting(TransferHeader: Record "Transfer Header"; PostedWhseShptHeader: Record "Posted Whse. Shipment Header"; WhseShip: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenNextNo(var TransferShipmentHeader: Record "Transfer Shipment Header"; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemInInventory(TransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertShptEntryRelation(var TransShptLine: Record "Transfer Shipment Line"; TransferLine: Record "Transfer Line"; var ItemJnlLine: Record "Item Journal Line"; WhsePosting: Boolean; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewTransferLineInsert(var NewTransferLine: Record "Transfer Line"; TransferLine: Record "Transfer Line"; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItem(var TransferShipmentHeader: Record "Transfer Shipment Header"; var IsHandled: Boolean; var TransferLine: Record "Transfer Line"; TransShptLine2: Record "Transfer Shipment Line"; WhseShip: Boolean; WhseShptHeader2: Record "Warehouse Shipment Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseDocument(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferTracking(var FromTransLine: Record "Transfer Line"; var ToTransLine: Record "Transfer Line"; TransferQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateWithWarehouseShipReceive(var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckTransLine(TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header"; Location: Record Location; WhseShip: Boolean; TransShptLine: Record "Transfer Shipment Line"; InvtPickPutaway: Boolean; var WhsePosting: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTransShptLineOnAfterCreatePostedShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var PostedWhseShipmentLine: Record "Posted Whse. Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTransShptLineOnBeforePostWhseJnlLine(TransShptLine: Record "Transfer Shipment Line"; TransLine: Record "Transfer Line"; SuppressCommit: Boolean; var WhsePosting: Boolean; var ShouldRunPosting: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertShptEntryRelationOnAfterCalcWhseSplitSpecification(TransLine: Record "Transfer Line"; var TransShptLine: Record "Transfer Shipment Line"; TempHandlingSpecification2: Record "Tracking Specification" temporary; var TempWhseSplitSpecification: Record "Tracking Specification" temporary; WhsePosting: Boolean; WhseShip: Boolean; InvtPickPutaway: Boolean; var WhseSplitSpecification: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostWIPItemJnlLineOnBeforeRunWithCheck(var ItemJnlLine: Record "Item Journal Line"; var TransShptHeader: Record "Transfer Shipment Header"; var TransShptLine: Record "Transfer Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeCommit(var TransferHeader: Record "Transfer Header"; var TransferShipmentHeader: Record "Transfer Shipment Header"; PostedWhseShptHeader: Record "Posted Whse. Shipment Header"; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckDimComb(TransferHeader: Record "Transfer Header"; TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostWhseJnlLineOnBeforeSplitWhseJnlLine()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTransShipmentLine(TransLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterTransLineSetFiltersForShptLines(var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header"; Location: Record Location; WhseShip: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeInsertShipmentLines(var WhseShptHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeLockTables(var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; OriginalQuantity: Decimal; OriginalQuantityBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckHeaderShippingAdvice(var TransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilterTransferLine(var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransLineModify(var TransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnTransferTrackingOnBeforeReserveTransferToTransfer(var FromTransferLine: Record "Transfer Line"; var ToTransferLine: Record "Transfer Line"; TransferQty: Decimal)
    begin
    end;
}

