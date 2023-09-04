codeunit 5856 "TransferOrder-Post Transfer"
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
        SourceCodeSetup: Record "Source Code Setup";
        InvtCommentLine: Record "Inventory Comment Line";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        RecordLinkManagement: Codeunit "Record Link Management";
        ReleaseTransferDocument: Codeunit "Release Transfer Document";
        Window: Dialog;
        LineCount: Integer;
    begin
        if TransferHeader2.Status = TransferHeader2.Status::Open then begin
            ReleaseTransferDocument.Release(TransferHeader2);
            TransferHeader2.Status := TransferHeader2.Status::Open;
            TransferHeader2.Modify();
            if not (SuppressCommit or PreviewMode) then
                Commit();
            TransferHeader2.Status := TransferHeader2.Status::Released;
        end;
        TransHeader := TransferHeader2;
        TransHeader.SetHideValidationDialog(HideValidationDialog);

        OnRunOnAfterTransHeaderSetHideValidationDialog(TransHeader, TransferHeader2, HideValidationDialog);

        with TransHeader do begin
            CheckBeforeTransferPost();
            CheckDim();

            WhseReference := "Posting from Whse. Ref.";
            "Posting from Whse. Ref." := 0;

            WhseShip := TempWhseShptHeader.FindFirst();
            InvtPickPutaway := WhseReference <> 0;

            TransLine.Reset();
            TransLine.SetRange("Document No.", "No.");
            TransLine.SetRange("Derived From Line No.", 0);
            TransLine.SetFilter(Quantity, '<>%1', 0);
            if TransLine.FindSet() then
                repeat
                    if not WhseShip then
                        TransLine.TestField("Qty. to Ship");
                    TransLine.TestField("Quantity Shipped", 0);
                    TransLine.TestField("Quantity Received", 0);
                    TransLine.CheckDirectTransferQtyToShip()
                until TransLine.Next() = 0
            else
                Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());

            GetLocation("Transfer-from Code");
            if Location."Bin Mandatory" and not (WhseShip or InvtPickPutaway) then
                WhsePosting := true;

            // Require Receipt is not supported here, only Bin Mandatory
            GetLocation("Transfer-to Code");
            Location.TestField("Require Receive", false);
            if Location."Bin Mandatory" then
                WhseReceive := true;

            Window.Open('#1#################################\\' + PostingLinesMsg);

            Window.Update(1, StrSubstNo(PostingDocumentTxt, "No."));

            SourceCodeSetup.Get();
            SourceCode := SourceCodeSetup.Transfer;
            InventorySetup.Get();
            InventorySetup.TestField("Posted Direct Trans. Nos.");

            if InventorySetup."Automatic Cost Posting" then begin
                GLEntry.LockTable();
                if GLEntry.FindLast() then;
            end;

            InsertDirectTransHeader(TransHeader, DirectTransHeader);
            if InventorySetup."Copy Comments Order to Shpt." then begin
                InvtCommentLine.CopyCommentLines(
                    "Inventory Comment Document Type"::"Transfer Order", "No.",
                    "Inventory Comment Document Type"::"Posted Direct Transfer", DirectTransHeader."No.");
                RecordLinkManagement.CopyLinks(TransferHeader2, DirectTransHeader);
            end;

            if WhseShip then begin
                WhseShptHeader.Get(TempWhseShptHeader."No.");
                WhsePostShipment.CreatePostedShptHeader(PostedWhseShptHeader, WhseShptHeader, DirectTransHeader."No.", "Posting Date");
            end;

            // Insert shipment lines
            LineCount := 0;
            if WhseShip then
                PostedWhseShptLine.LockTable();
            if InvtPickPutaway then
                WhseRqst.LockTable();
            DirectTransLine.LockTable();
            TransLine.SetRange(Quantity);
            if TransLine.FindSet() then
                repeat
                    LineCount := LineCount + 1;
                    Window.Update(2, LineCount);

                    if TransLine."Item No." <> '' then begin
                        Item.Get(TransLine."Item No.");
                        Item.TestField(Blocked, false);
                    end;

                    InsertDirectTransLine(DirectTransHeader, TransLine);
                until TransLine.Next() = 0;

            MakeInventoryAdjustment();

            LockTable();
            if WhseShip then
                WhseShptLine.LockTable();

            if WhseShip then begin
                WhsePostShipment.PostUpdateWhseDocuments(WhseShptHeader);
                TempWhseShptHeader.Delete();
            end;

            "Last Shipment No." := DirectTransHeader."No.";
            "Last Receipt No." := DirectTransHeader."No.";
            Modify();

            TransLine.SetRange(Quantity);
            if not PreviewMode then
                DeleteOneTransferOrder(TransHeader, TransLine);
            Window.Close();
        end;

        UpdateAnalysisView.UpdateAll(0, true);
        UpdateItemAnalysisView.UpdateAll(0, true);
        TransferHeader2 := TransHeader;

        OnAfterTransferOrderPostTransfer(TransferHeader2, SuppressCommit, DirectTransHeader, InvtPickPutAway);
    end;

    var
        DirectTransHeader: Record "Direct Trans. Header";
        DirectTransLine: Record "Direct Trans. Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        Location: Record Location;
        InventorySetup: Record "Inventory Setup";
        ItemJnlLine: Record "Item Journal Line";
        WhseRqst: Record "Warehouse Request";
        PostedWhseShptHeader: Record "Posted Whse. Shipment Header";
        PostedWhseShptLine: Record "Posted Whse. Shipment Line";
        TempWhseSplitSpecification: Record "Tracking Specification" temporary;
        TempHandlingSpecification: Record "Tracking Specification" temporary;
        TempWhseShptHeader: Record "Warehouse Shipment Header" temporary;
        GLEntry: Record "G/L Entry";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        DimMgt: Codeunit DimensionManagement;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        ReserveTransLine: Codeunit "Transfer Line-Reserve";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
        SourceCode: Code[10];
        HideValidationDialog: Boolean;
        InvtPickPutaway: Boolean;
        SuppressCommit: Boolean;
        PreviewMode: Boolean;
        WhseReceive: Boolean;
        WhseShip: Boolean;
        WhsePosting: Boolean;
        WhseReference: Integer;
        OriginalQuantity: Decimal;
        OriginalQuantityBase: Decimal;
        PostingLinesMsg: Label 'Posting transfer lines #2######', Comment = '#2 - line counter';
        PostingDocumentTxt: Label 'Transfer Order %1', Comment = '%1 - document number';
        DimCombBlockedErr: Label 'The combination of dimensions used in transfer order %1 is blocked. %2', Comment = '%1 - document number, %2 - error message';
        DimCombLineBlockedErr: Label 'The combination of dimensions used in transfer order %1, line no. %2 is blocked. %3', Comment = '%1 - document number, %2 = line number, %3 - error message';
        DimInvalidErr: Label 'The dimensions used in transfer order %1, line no. %2 are invalid. %3', Comment = '%1 - document number, %2 = line number, %3 - error message';

    local procedure PostItemJnlLine(var TransLine3: Record "Transfer Line"; DirectTransHeader2: Record "Direct Trans. Header"; DirectTransLine2: Record "Direct Trans. Line")
    begin
        CreateItemJnlLine(TransLine3, DirectTransHeader2, DirectTransLine2);
        ReserveTransLine.TransferTransferToItemJnlLine(TransLine3,
          ItemJnlLine, ItemJnlLine."Quantity (Base)", "Transfer Direction"::Outbound, true);

        ItemJnlPostLine.RunWithCheck(ItemJnlLine);

        OnAfterPostItemJnlLine(TransLine3, DirectTransHeader2, DirectTransLine2, ItemJnlLine, ItemJnlPostLine);
    end;

    local procedure CreateItemJnlLine(TransLine3: Record "Transfer Line"; DirectTransHeader2: Record "Direct Trans. Header"; DirectTransLine2: Record "Direct Trans. Line")
    begin
        with ItemJnlLine do begin
            Init();
            "Posting Date" := DirectTransHeader2."Posting Date";
            "Document Date" := DirectTransHeader2."Posting Date";
            "Document No." := DirectTransHeader2."No.";
            "Document Type" := "Document Type"::"Direct Transfer";
            "Document Line No." := DirectTransLine2."Line No.";
            "Order Type" := "Order Type"::Transfer;
            "Order No." := DirectTransHeader2."Transfer Order No.";
            "External Document No." := DirectTransHeader2."External Document No.";
            "Entry Type" := "Entry Type"::Transfer;
            "Item No." := DirectTransLine2."Item No.";
            Description := DirectTransLine2.Description;
            "Shortcut Dimension 1 Code" := DirectTransLine2."Shortcut Dimension 1 Code";
            "New Shortcut Dimension 1 Code" := DirectTransLine2."Shortcut Dimension 1 Code";
            "Shortcut Dimension 2 Code" := DirectTransLine2."Shortcut Dimension 2 Code";
            "New Shortcut Dimension 2 Code" := DirectTransLine2."Shortcut Dimension 2 Code";
            "Dimension Set ID" := DirectTransLine2."Dimension Set ID";
            "New Dimension Set ID" := DirectTransLine2."Dimension Set ID";
            "Location Code" := DirectTransHeader2."Transfer-from Code";
            "New Location Code" := DirectTransHeader2."Transfer-to Code";
            Quantity := DirectTransLine2.Quantity;
            "Invoiced Quantity" := DirectTransLine2.Quantity;
            "Quantity (Base)" := DirectTransLine2."Quantity (Base)";
            "Invoiced Qty. (Base)" := DirectTransLine2."Quantity (Base)";
            "Source Code" := SourceCode;
            "Gen. Prod. Posting Group" := DirectTransLine2."Gen. Prod. Posting Group";
            "Inventory Posting Group" := DirectTransLine2."Inventory Posting Group";
            "Unit of Measure Code" := DirectTransLine2."Unit of Measure Code";
            "Qty. per Unit of Measure" := DirectTransLine2."Qty. per Unit of Measure";
            "Variant Code" := DirectTransLine2."Variant Code";
            "Bin Code" := TransLine3."Transfer-from Bin Code";
            "New Bin Code" := TransLine3."Transfer-To Bin Code";
            "Country/Region Code" := DirectTransHeader2."Trsf.-from Country/Region Code";
            "Item Category Code" := TransLine3."Item Category Code";
        end;

        OnAfterCreateItemJnlLine(ItemJnlLine, TransLine3, DirectTransHeader2, DirectTransLine2);
    end;

    local procedure InsertDirectTransHeader(TransferHeader: Record "Transfer Header"; var DirectTransHeader: Record "Direct Trans. Header")
    begin
        DirectTransHeader.LockTable();
        DirectTransHeader.Init();
        DirectTransHeader."Transfer-from Code" := TransferHeader."Transfer-from Code";
        DirectTransHeader."Transfer-from Name" := TransferHeader."Transfer-from Name";
        DirectTransHeader."Transfer-from Name 2" := TransferHeader."Transfer-from Name 2";
        DirectTransHeader."Transfer-from Address" := TransferHeader."Transfer-from Address";
        DirectTransHeader."Transfer-from Address 2" := TransferHeader."Transfer-from Address 2";
        DirectTransHeader."Transfer-from Post Code" := TransferHeader."Transfer-from Post Code";
        DirectTransHeader."Transfer-from City" := TransferHeader."Transfer-from City";
        DirectTransHeader."Transfer-from County" := TransferHeader."Transfer-from County";
        DirectTransHeader."Trsf.-from Country/Region Code" := TransferHeader."Trsf.-from Country/Region Code";
        DirectTransHeader."Transfer-from Contact" := TransferHeader."Transfer-from Contact";
        DirectTransHeader."Transfer-to Code" := TransferHeader."Transfer-to Code";
        DirectTransHeader."Transfer-to Name" := TransferHeader."Transfer-to Name";
        DirectTransHeader."Transfer-to Name 2" := TransferHeader."Transfer-to Name 2";
        DirectTransHeader."Transfer-to Address" := TransferHeader."Transfer-to Address";
        DirectTransHeader."Transfer-to Address 2" := TransferHeader."Transfer-to Address 2";
        DirectTransHeader."Transfer-to Post Code" := TransferHeader."Transfer-to Post Code";
        DirectTransHeader."Transfer-to City" := TransferHeader."Transfer-to City";
        DirectTransHeader."Transfer-to County" := TransferHeader."Transfer-to County";
        DirectTransHeader."Trsf.-to Country/Region Code" := TransferHeader."Trsf.-to Country/Region Code";
        DirectTransHeader."Transfer-to Contact" := TransferHeader."Transfer-to Contact";
        DirectTransHeader."Transfer Order Date" := TransferHeader."Posting Date";
        DirectTransHeader."Posting Date" := TransferHeader."Posting Date";
        DirectTransHeader."Shortcut Dimension 1 Code" := TransferHeader."Shortcut Dimension 1 Code";
        DirectTransHeader."Shortcut Dimension 2 Code" := TransferHeader."Shortcut Dimension 2 Code";
        DirectTransHeader."Dimension Set ID" := TransferHeader."Dimension Set ID";
        DirectTransHeader."Transfer Order No." := TransferHeader."No.";
        DirectTransHeader."External Document No." := TransferHeader."External Document No.";
        DirectTransHeader."No. Series" := InventorySetup."Posted Direct Trans. Nos.";
        OnInsertDirectTransHeaderOnBeforeGetNextNo(DirectTransHeader, TransferHeader);
        DirectTransHeader."No." :=
            NoSeriesMgt.GetNextNo(DirectTransHeader."No. Series", TransferHeader."Posting Date", true);
        OnInsertDirectTransHeaderOnBeforeDirectTransHeaderInsert(DirectTransHeader, TransferHeader);
        DirectTransHeader.Insert();

        OnAfterInsertDirectTransHeader(DirectTransHeader, TransferHeader);
    end;

    local procedure InsertDirectTransLine(DirectTransHeader: Record "Direct Trans. Header"; TransLine: Record "Transfer Line")
    var
        IsHandled: Boolean;
    begin
        OnBeforeInsertDirectTransLine(TransLine);
        DirectTransLine.Init();
        DirectTransLine."Document No." := DirectTransHeader."No.";
        DirectTransLine.CopyFromTransferLine(TransLine);

        OnInsertDirectTransLineOnAfterPopulateDirectTransLine(DirectTransLine, DirectTransHeader, TransLine);
        if TransLine.Quantity > 0 then begin
            OriginalQuantity := TransLine.Quantity;
            OriginalQuantityBase := TransLine."Quantity (Base)";
            PostItemJnlLine(TransLine, DirectTransHeader, DirectTransLine);
            DirectTransLine."Item Shpt. Entry No." := InsertShptEntryRelation(DirectTransLine);
            if WhseShip then begin
                WhseShptLine.SetCurrentKey("No.", "Source Type", "Source Subtype", "Source No.", "Source Line No.");
                WhseShptLine.SetRange("No.", WhseShptHeader."No.");
                WhseShptLine.SetRange("Source Type", DATABASE::"Transfer Line");
                WhseShptLine.SetRange("Source No.", TransLine."Document No.");
                WhseShptLine.SetRange("Source Line No.", TransLine."Line No.");
                if WhseShptLine.FindFirst() then begin
                    WhseShptLine.TestField("Qty. to Ship", TransLine.Quantity);
                    WhsePostShipment.CreatePostedShptLine(
                        WhseShptLine, PostedWhseShptHeader, PostedWhseShptLine, TempWhseSplitSpecification);
                end;
            end;
            if WhsePosting then
                PostWhseJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase, TempHandlingSpecification, 0);
            if WhseReceive then
                PostWhseJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase, TempHandlingSpecification, 1);
        end;
        IsHandled := false;
        OnInsertDirectTransLineOnBeforeDirectTransHeaderInsert(DirectTransHeader, TransLine, IsHandled);
        if not IsHandled then
            DirectTransLine.Insert();
        OnAfterInsertDirectTransLine(DirectTransLine, DirectTransHeader, TransLine)
    end;

    local procedure CheckDim()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDim(TransHeader, TransLine);
        if IsHandled then
            exit;

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
                Error(DimCombBlockedErr, TransHeader."No.", DimMgt.GetDimCombErr())
            else
                if not DimMgt.CheckDimIDComb(TransferLine."Dimension Set ID") then
                    Error(DimCombLineBlockedErr, TransHeader."No.", TransferLine."Line No.", DimMgt.GetDimCombErr());
    end;

    local procedure CheckDimValuePosting(TransferHeader: Record "Transfer Header"; TransferLine: Record "Transfer Line")
    var
        TableIDArr: array[10] of Integer;
        NumberArr: array[10] of Code[20];
    begin
        TableIDArr[1] := DATABASE::Item;
        NumberArr[1] := TransferLine."Item No.";
        if TransferLine."Line No." = 0 then
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, TransferHeader."Dimension Set ID") then
                Error(DimInvalidErr, TransHeader."No.", TransferLine."Line No.", DimMgt.GetDimValuePostingErr());
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    local procedure InsertShptEntryRelation(var DirectTransLine: Record "Direct Trans. Line") Result: Integer
    var
        TempHandlingSpecification2: Record "Tracking Specification" temporary;
        ItemEntryRelation: Record "Item Entry Relation";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WhseSplitSpecification: Boolean;
    begin
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
                    if WhseSplitSpecification then
                        if ItemTrackingMgt.GetWhseItemTrkgSetup(DirectTransLine."Item No.") then begin
                            TempWhseSplitSpecification := TempHandlingSpecification2;
                            TempWhseSplitSpecification."Source Type" := DATABASE::"Transfer Line";
                            TempWhseSplitSpecification."Source ID" := TransLine."Document No.";
                            TempWhseSplitSpecification."Source Ref. No." := TransLine."Line No.";
                            TempWhseSplitSpecification.Insert();
                        end;

                    ItemEntryRelation.Init();
                    ItemEntryRelation.InitFromTrackingSpec(TempHandlingSpecification2);
                    ItemEntryRelation.TransferFieldsDirectTransLine(DirectTransLine);
                    ItemEntryRelation.Insert();
                    TempHandlingSpecification := TempHandlingSpecification2;
                    TempHandlingSpecification.SetSource(
                        DATABASE::"Transfer Line", 0, DirectTransLine."Document No.", DirectTransLine."Line No.", '', DirectTransLine."Line No.");
                    TempHandlingSpecification."Buffer Status" := TempHandlingSpecification."Buffer Status"::MODIFY;
                    TempHandlingSpecification.Insert();
                until TempHandlingSpecification2.Next() = 0;
                Result := 0;
            end;
        end else
            Result := ItemJnlLine."Item Shpt. Entry No.";

        OnAfterInsertShptEntryRelation(ItemEntryRelation, DirectTransLine, Result);
    end;

    procedure TransferTracking(var FromTransLine: Record "Transfer Line"; var ToTransLine: Record "Transfer Line"; TransferQty: Decimal)
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
                  FromTransLine, ToTransLine, -TempHandlingSpecification."Quantity (Base)", "Transfer Direction"::Inbound, TempHandlingSpecification);
                TransferQty += TempHandlingSpecification."Quantity (Base)";
            until TempHandlingSpecification.Next() = 0;
            TempHandlingSpecification.DeleteAll();
        end;

        if TransferQty > 0 then
            ReserveTransLine.TransferTransferToTransfer(
              FromTransLine, ToTransLine, TransferQty, "Transfer Direction"::Inbound, DummySpecification);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Location.GetLocationSetup(LocationCode, Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    procedure SetWhseShptHeader(var WhseShptHeader2: Record "Warehouse Shipment Header")
    begin
        WhseShptHeader := WhseShptHeader2;
        TempWhseShptHeader := WhseShptHeader;
        TempWhseShptHeader.Insert();
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    internal procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    local procedure PostWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; OriginalQuantity: Decimal; OriginalQuantityBase: Decimal; var TempHandlingSpecification: Record "Tracking Specification" temporary; Direction: Integer)
    var
        WhseJnlLine: Record "Warehouse Journal Line";
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WMSMgmt: Codeunit "WMS Management";
        WhseJnlPostLine: Codeunit "Whse. Jnl.-Register Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostWhseJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase, TempHandlingSpecification, Direction, IsHandled);
        if IsHandled then
            exit;

        with ItemJnlLine do begin
            Quantity := OriginalQuantity;
            "Quantity (Base)" := OriginalQuantityBase;
            if Direction = 0 then
                GetLocation("Location Code")
            else
                GetLocation("New Location Code");
            if Location."Bin Mandatory" then
                if WMSMgmt.CreateWhseJnlLine(ItemJnlLine, 1, WhseJnlLine, Direction = 1) then begin
                    WMSMgmt.SetTransferLine(TransLine, WhseJnlLine, Direction, DirectTransHeader."No.");
                    WhseJnlLine."Source No." := DirectTransHeader."No.";
                    if Direction = 1 then
                        WhseJnlLine."To Bin Code" := "New Bin Code";
                    OnPostWhseJnlLineOnBeforeSplitWhseJnlLine(WhseJnlLine, TempWhseJnlLine2);
                    ItemTrackingMgt.SplitWhseJnlLine(
                      WhseJnlLine, TempWhseJnlLine2, TempHandlingSpecification, true);
                    if TempWhseJnlLine2.Find('-') then
                        repeat
                            WMSMgmt.CheckWhseJnlLine(TempWhseJnlLine2, 1, 0, Direction = 1);
                            WhseJnlPostLine.Run(TempWhseJnlLine2);
                        until TempWhseJnlLine2.Next() = 0;
                end;
        end;
    end;

    local procedure MakeInventoryAdjustment()
    var
        InvtAdjmtHandler: Codeunit "Inventory Adjustment Handler";
    begin
        if InventorySetup.AutomaticCostAdjmtRequired() then
            InvtAdjmtHandler.MakeInventoryAdjustment(true, InventorySetup."Automatic Cost Posting");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Shipment Line", 'OnAfterValidateQtyToShip', '', false, false)]
    local procedure WarehouseShipmentLineOnValidateQtyToShip(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
        if WarehouseShipmentLine."Qty. to Ship (Base)" <> 0 then
            CheckDirectTransferQtyToShip(WarehouseShipmentLine);
    end;

    local procedure CheckDirectTransferQtyToShip(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
        if WarehouseShipmentLine."Source Type" <> Database::"Transfer Line" then
            exit;

        if WarehouseShipmentLine.CheckDirectTransfer(false, false) then
            WarehouseShipmentLine.TestField("Qty. to Ship (Base)", WarehouseShipmentLine."Qty. Outstanding (Base)");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; TransLine: Record "Transfer Line"; DirectTransHeader: Record "Direct Trans. Header"; DirectTransLine: Record "Direct Trans. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertDirectTransHeader(var DirectTransHeader: Record "Direct Trans. Header"; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertDirectTransLine(var DirectTransLine: Record "Direct Trans. Line"; DirectTransHeader: Record "Direct Trans. Header"; TransLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertShptEntryRelation(var ItemEntryRelation: Record "Item Entry Relation"; var DirectTransLine: Record "Direct Trans. Line"; var Result: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItemJnlLine(var TransferLine3: Record "Transfer Line"; DirectTransHeader2: Record "Direct Trans. Header"; DirectTransLine2: Record "Direct Trans. Line"; ItemJournalLine: Record "Item Journal Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDim(var TransferHeader: Record "Transfer Header"; var TransferLife: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertDirectTransLine(TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; OriginalQuantity: Decimal; OriginalQuantityBase: Decimal; var TempHandlingSpecification: Record "Tracking Specification" temporary; Direction: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferTracking(var FromTransLine: Record "Transfer Line"; var ToTransLine: Record "Transfer Line"; TransferQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertDirectTransLineOnAfterPopulateDirectTransLine(var DirectTransLine: Record "Direct Trans. Line"; DirectTransHeader: Record "Direct Trans. Header"; TransLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertDirectTransHeaderOnBeforeDirectTransHeaderInsert(var DirectTransHeader: Record "Direct Trans. Header"; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertDirectTransHeaderOnBeforeGetNextNo(var DirectTransHeader: Record "Direct Trans. Header"; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertDirectTransLineOnBeforeDirectTransHeaderInsert(var DirectTransHeader: Record "Direct Trans. Header"; TransLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostWhseJnlLineOnBeforeSplitWhseJnlLine(var WhseJnlLine: Record "Warehouse Journal Line"; var TempWhseJnlLine2: Record "Warehouse Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterTransHeaderSetHideValidationDialog(var TransHeader: Record "Transfer Header"; var Rec: Record "Transfer Header"; var HideValidationDialog: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferOrderPostTransfer(var TransferHeader: Record "Transfer Header"; var SuppressCommit: Boolean; var DirectTransHeader: Record "Direct Trans. Header"; InvtPickPutAway: Boolean)
    begin
    end;
}

