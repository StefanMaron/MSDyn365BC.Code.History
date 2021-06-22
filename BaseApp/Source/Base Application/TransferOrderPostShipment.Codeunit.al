codeunit 5704 "TransferOrder-Post Shipment"
{
    Permissions = TableData "Item Entry Relation" = i;
    TableNo = "Transfer Header";

    trigger OnRun()
    var
        Item: Record Item;
        SourceCodeSetup: Record "Source Code Setup";
        InvtSetup: Record "Inventory Setup";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        RecordLinkManagement: Codeunit "Record Link Management";
        Window: Dialog;
        LineCount: Integer;
        NextLineNo: Integer;
    begin
        ReleaseDocument(Rec);
        TransHeader := Rec;
        TransHeader.SetHideValidationDialog(HideValidationDialog);

        OnBeforeTransferOrderPostShipment(TransHeader, SuppressCommit);

        with TransHeader do begin
            CheckBeforePost;

            WhseReference := "Posting from Whse. Ref.";
            "Posting from Whse. Ref." := 0;

            if "Shipping Advice" = "Shipping Advice"::Complete then
                if not GetShippingAdvice then
                    Error(Text008);

            CheckDim;
            CheckLines(TransHeader, TransLine);

            WhseShip := TempWhseShptHeader.FindFirst;
            InvtPickPutaway := WhseReference <> 0;
            CheckItemInInventoryAndWarehouse(TransLine, not (WhseShip or InvtPickPutaway));

            GetLocation("Transfer-from Code");
            if Location."Bin Mandatory" and not (WhseShip or InvtPickPutaway) then
                WhsePosting := true;

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

            CheckInvtPostingSetup;
            OnAfterCheckInvtPostingSetup(TransHeader, TempWhseShptHeader, SourceCode);

            LockTables(InvtSetup."Automatic Cost Posting");

            // Insert shipment header
            PostedWhseShptHeader.LockTable();
            TransShptHeader.LockTable();
            InsertTransShptHeader(TransShptHeader, TransHeader, InvtSetup."Posted Transfer Shpt. Nos.");

            if InvtSetup."Copy Comments Order to Shpt." then begin
                CopyCommentLines(1, 2, "No.", TransShptHeader."No.");
                RecordLinkManagement.CopyLinks(Rec, TransShptHeader);
            end;

            if WhseShip then begin
                WhseShptHeader.Get(TempWhseShptHeader."No.");
                WhsePostShpt.CreatePostedShptHeader(PostedWhseShptHeader, WhseShptHeader, TransShptHeader."No.", "Posting Date");
            end;

            // Insert shipment lines
            LineCount := 0;
            if WhseShip then
                PostedWhseShptLine.LockTable();
            if InvtPickPutaway then
                WhseRqst.LockTable();
            TransShptLine.LockTable();
            TransLine.SetRange(Quantity);
            TransLine.SetRange("Qty. to Ship");
            if TransLine.Find('-') then
                repeat
                    LineCount := LineCount + 1;
                    if GuiAllowed then
                        Window.Update(2, LineCount);

                    if TransLine."Item No." <> '' then begin
                        Item.Get(TransLine."Item No.");
                        Item.TestField(Blocked, false);
                    end;

                    OnCheckTransLine(TransLine, TransHeader, Location, WhseShip);

                    InsertTransShptLine(TransShptHeader);
                until TransLine.Next = 0;

            InvtSetup.Get();
            if InvtSetup."Automatic Cost Adjustment" <> InvtSetup."Automatic Cost Adjustment"::Never then begin
                InvtAdjmt.SetProperties(true, InvtSetup."Automatic Cost Posting");
                InvtAdjmt.MakeMultiLevelAdjmt;
                OnAfterInvtAdjmt(TransHeader, TransShptHeader);
            end;

            if WhseShip then
                WhseShptLine.LockTable();
            TransLine.LockTable();

            OnBeforeCopyTransLines(TransHeader);

            TransLine.SetFilter(Quantity, '<>0');
            TransLine.SetFilter("Qty. to Ship", '<>0');
            if TransLine.Find('-') then begin
                NextLineNo := AssignLineNo(TransLine."Document No.");
                repeat
                    CopyTransLine(TransLine2, TransLine, NextLineNo, TransHeader);
                    TransferTracking(TransLine, TransLine2, TransLine."Qty. to Ship (Base)");
                    TransLine.Validate("Quantity Shipped", TransLine."Quantity Shipped" + TransLine."Qty. to Ship");

                    OnBeforeUpdateWithWarehouseShipReceive(TransLine);
                    TransLine.UpdateWithWarehouseShipReceive;
                    TransLine.Modify();
                    OnAfterTransLineModify(TransLine);
                until TransLine.Next = 0;
            end;

            if WhseShip then
                WhseShptLine.LockTable();
            LockTable();
            if WhseShip then begin
                WhsePostShpt.PostUpdateWhseDocuments(WhseShptHeader);
                TempWhseShptHeader.Delete();
            end;

            "Last Shipment No." := TransShptHeader."No.";
            Modify;

            FinalizePosting(TransHeader, TransLine);

            OnRunOnBeforeCommit(TransHeader, TransShptHeader);
            if not (InvtPickPutaway or "Direct Transfer" or SuppressCommit) then begin
                Commit();
                UpdateAnalysisView.UpdateAll(0, true);
                UpdateItemAnalysisView.UpdateAll(0, true);
            end;
            Clear(WhsePostShpt);
            Clear(InvtAdjmt);

            if GuiAllowed then
                Window.Close;
        end;

        Rec := TransHeader;

        OnAfterTransferOrderPostShipment(Rec, SuppressCommit, TransShptHeader);
    end;

    var
        Text001: Label 'There is nothing to post.';
        Text002: Label 'Warehouse handling is required for Transfer order = %1, %2 = %3.';
        Text003: Label 'Posting transfer lines     #2######';
        Text004: Label 'Transfer Order %1';
        Text005: Label 'The combination of dimensions used in transfer order %1 is blocked. %2';
        Text006: Label 'The combination of dimensions used in transfer order %1, line no. %2 is blocked. %3';
        Text007: Label 'The dimensions that are used in transfer order %1, line no. %2 are not valid. %3.';
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
        InvtAdjmt: Codeunit "Inventory Adjustment";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        SourceCode: Code[10];
        HideValidationDialog: Boolean;
        WhseShip: Boolean;
        WhsePosting: Boolean;
        InvtPickPutaway: Boolean;
        WhseReference: Integer;
        OriginalQuantity: Decimal;
        OriginalQuantityBase: Decimal;
        Text008: Label 'This order must be a complete shipment.';
        Text009: Label 'Item %1 is not in inventory.';
        SuppressCommit: Boolean;

    local procedure PostItem(var TransferLine: Record "Transfer Line"; TransShptHeader2: Record "Transfer Shipment Header"; TransShptLine2: Record "Transfer Shipment Line"; WhseShip: Boolean; WhseShptHeader2: Record "Warehouse Shipment Header")
    var
        IsHandled: Boolean;
    begin
        OnBeforePostItem(TransShptHeader2, IsHandled);
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
            Init;
            CopyDocumentFields(
              "Document Type"::"Transfer Shipment", TransShptHeader2."No.", "External Document No.", SourceCode, '');
            "Posting Date" := TransShptHeader2."Posting Date";
            "Document Date" := TransShptHeader2."Posting Date";
            "Document Line No." := TransShptLine2."Line No.";
            "Order Type" := "Order Type"::Transfer;
            "Order No." := TransShptHeader2."Transfer Order No.";
            "Order Line No." := TransferLine."Line No.";
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
        end;

        OnAfterCreateItemJnlLine(ItemJnlLine, TransferLine, TransShptHeader2, TransShptLine2);
    end;

    local procedure ReserveItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; var TransferLine: Record "Transfer Line"; WhseShip: Boolean; WhseShptHeader2: Record "Warehouse Shipment Header")
    begin
        if WhseShip and (WhseShptHeader2."Document Status" = WhseShptHeader2."Document Status"::"Partially Picked") then
            ReserveTransLine.TransferWhseShipmentToItemJnlLine(
              TransferLine, ItemJnlLine, WhseShptHeader2, ItemJnlLine."Quantity (Base)")
        else
            ReserveTransLine.TransferTransferToItemJnlLine(
              TransferLine, ItemJnlLine, ItemJnlLine."Quantity (Base)", 0);
    end;

    local procedure CopyCommentLines(FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    var
        InvtCommentLine: Record "Inventory Comment Line";
        InvtCommentLine2: Record "Inventory Comment Line";
    begin
        InvtCommentLine.SetRange("Document Type", FromDocumentType);
        InvtCommentLine.SetRange("No.", FromNumber);
        if InvtCommentLine.Find('-') then
            repeat
                InvtCommentLine2 := InvtCommentLine;
                InvtCommentLine2."Document Type" := ToDocumentType;
                InvtCommentLine2."No." := ToNumber;
                InvtCommentLine2.Insert();
            until InvtCommentLine.Next = 0;
    end;

    local procedure CheckDim()
    begin
        TransLine."Line No." := 0;
        CheckDimComb(TransHeader, TransLine);
        CheckDimValuePosting(TransHeader, TransLine);

        TransLine.SetRange("Document No.", TransHeader."No.");
        if TransLine.FindFirst then begin
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
                  TransHeader."No.", DimMgt.GetDimCombErr);
        if TransferLine."Line No." <> 0 then
            if not DimMgt.CheckDimIDComb(TransferLine."Dimension Set ID") then
                Error(
                  Text006,
                  TransHeader."No.", TransferLine."Line No.", DimMgt.GetDimCombErr);
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
        if TransferLine."Line No." = 0 then
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, TransferHeader."Dimension Set ID") then
                Error(Text007, TransHeader."No.", TransferLine."Line No.", DimMgt.GetDimValuePostingErr);

        if TransferLine."Line No." <> 0 then
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, TransferLine."Dimension Set ID") then
                Error(Text007, TransHeader."No.", TransferLine."Line No.", DimMgt.GetDimValuePostingErr);
    end;

    local procedure FinalizePosting(var TransHeader: Record "Transfer Header"; var TransLine: Record "Transfer Line")
    var
        DeleteOne: Boolean;
    begin
        TransLine.SetRange(Quantity);
        TransLine.SetRange("Qty. to Ship");
        DeleteOne := TransHeader.ShouldDeleteOneTransferOrder(TransLine);
        OnBeforeDeleteOneTransferOrder(TransHeader, DeleteOne);
        if DeleteOne then
            TransHeader.DeleteOneTransferOrder(TransHeader, TransLine)
        else begin
            WhseTransferRelease.Release(TransHeader);
            ReserveTransLine.UpdateItemTrackingAfterPosting(TransHeader, 0);
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
        if TransLine3.FindLast then
            exit(TransLine3."Line No." + 10000);
    end;

    local procedure InsertShptEntryRelation(var TransShptLine: Record "Transfer Shipment Line"): Integer
    var
        TempHandlingSpecification2: Record "Tracking Specification" temporary;
        ItemEntryRelation: Record "Item Entry Relation";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
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
                    if WhsePosting or WhseShip or InvtPickPutaway then begin
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
                until TempHandlingSpecification2.Next = 0;
                OnAfterInsertShptEntryRelation(TransLine, WhseShip, 0, SuppressCommit);
                exit(0);
            end;
        end else begin
            OnAfterInsertShptEntryRelation(TransLine, WhseShip, ItemJnlLine."Item Shpt. Entry No.", SuppressCommit);
            exit(ItemJnlLine."Item Shpt. Entry No.");
        end;
    end;

    local procedure InsertTransShptHeader(var TransShptHeader: Record "Transfer Shipment Header"; TransHeader: Record "Transfer Header"; NoSeries: Code[20])
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        TransShptHeader.Init();
        TransShptHeader.CopyFromTransferHeader(TransHeader);
        TransShptHeader."No. Series" := NoSeries;
        OnBeforeGenNextNo(TransShptHeader, TransHeader);
        if TransShptHeader."No." = '' then
            TransShptHeader."No." := NoSeriesMgt.GetNextNo(NoSeries, TransHeader."Posting Date", true);
        OnBeforeInsertTransShptHeader(TransShptHeader, TransHeader, SuppressCommit);
        TransShptHeader.Insert();
        OnAfterInsertTransShptHeader(TransHeader, TransShptHeader);
    end;

    local procedure InsertTransShptLine(TransShptHeader: Record "Transfer Shipment Header")
    var
        TransShptLine: Record "Transfer Shipment Line";
    begin
        TransShptLine.Init();
        TransShptLine."Document No." := TransShptHeader."No.";
        TransShptLine.CopyFromTransferLine(TransLine);
        if TransLine."Qty. to Ship" > 0 then begin
            OriginalQuantity := TransLine."Qty. to Ship";
            OriginalQuantityBase := TransLine."Qty. to Ship (Base)";
            PostItem(TransLine, TransShptHeader, TransShptLine, WhseShip, WhseShptHeader);
            TransShptLine."Item Shpt. Entry No." := InsertShptEntryRelation(TransShptLine);
            if WhseShip then begin
                WhseShptLine.SetCurrentKey(
                  "No.", "Source Type", "Source Subtype", "Source No.", "Source Line No.");
                WhseShptLine.SetRange("No.", WhseShptHeader."No.");
                WhseShptLine.SetRange("Source Type", DATABASE::"Transfer Line");
                WhseShptLine.SetRange("Source No.", TransLine."Document No.");
                WhseShptLine.SetRange("Source Line No.", TransLine."Line No.");
                if WhseShptLine.FindFirst then begin
                    WhseShptLine.TestField("Qty. to Ship", TransShptLine.Quantity);
                    WhsePostShpt.CreatePostedShptLine(
                      WhseShptLine, PostedWhseShptHeader, PostedWhseShptLine, TempWhseSplitSpecification);
                    OnInsertTransShptLineOnAfterCreatePostedShptLine(WhseShptLine, PostedWhseShptLine);
                end;
            end;
            if WhsePosting then
                PostWhseJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase);
        end;
        OnBeforeInsertTransShptLine(TransShptLine, TransLine, SuppressCommit);
        TransShptLine.Insert();
        OnAfterInsertTransShptLine(TransShptLine, TransLine, SuppressCommit);
    end;

    local procedure TransferTracking(var FromTransLine: Record "Transfer Line"; var ToTransLine: Record "Transfer Line"; TransferQty: Decimal)
    var
        DummySpecification: Record "Tracking Specification";
    begin
        TempHandlingSpecification.Reset();
        TempHandlingSpecification.SetRange("Source Prod. Order Line", ToTransLine."Derived From Line No.");
        if TempHandlingSpecification.Find('-') then begin
            repeat
                ReserveTransLine.TransferTransferToTransfer(
                  FromTransLine, ToTransLine, -TempHandlingSpecification."Quantity (Base)", 1, TempHandlingSpecification);
                TransferQty += TempHandlingSpecification."Quantity (Base)";
            until TempHandlingSpecification.Next = 0;
            TempHandlingSpecification.DeleteAll();
        end;

        if TransferQty > 0 then
            ReserveTransLine.TransferTransferToTransfer(
              FromTransLine, ToTransLine, TransferQty, 1, DummySpecification);
    end;

    local procedure CheckWarehouse(TransLine: Record "Transfer Line")
    var
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        ShowError: Boolean;
    begin
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
    begin
        with ItemJnlLine do begin
            Quantity := OriginalQuantity;
            "Quantity (Base)" := OriginalQuantityBase;
            GetLocation("Location Code");
            if Location."Bin Mandatory" then
                if WMSMgmt.CreateWhseJnlLine(ItemJnlLine, 1, WhseJnlLine, false) then begin
                    WMSMgmt.SetTransferLine(TransLine, WhseJnlLine, 0, TransShptHeader."No.");
                    ItemTrackingMgt.SplitWhseJnlLine(
                      WhseJnlLine, TempWhseJnlLine2, TempWhseSplitSpecification, true);
                    if TempWhseJnlLine2.Find('-') then
                        repeat
                            WMSMgmt.CheckWhseJnlLine(TempWhseJnlLine2, 1, 0, true);
                            WhseJnlRegisterLine.RegisterWhseJnlLine(TempWhseJnlLine2);
                        until TempWhseJnlLine2.Next = 0;
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
            until TransLine.Next = 0;
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
    begin
        TransLine2.CopyFilters(TransLine);
        TransLine2.FindSet;
        repeat
            CheckItemInInventory(TransLine2);
            if NeedCheckWarehouse then
                CheckWarehouse(TransLine2);
        until TransLine2.Next = 0;
    end;

    local procedure CheckLines(TransHeader: Record "Transfer Header"; var TransLine: Record "Transfer Line")
    begin
        with TransHeader do begin
            TransLine.Reset();
            TransLine.SetRange("Document No.", "No.");
            TransLine.SetRange("Derived From Line No.", 0);
            TransLine.SetFilter(Quantity, '<>0');
            TransLine.SetFilter("Qty. to Ship", '<>0');
            if TransLine.IsEmpty then
                Error(Text001);
        end;
    end;

    local procedure LockTables(AutoCostPosting: Boolean)
    var
        GLEntry: Record "G/L Entry";
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.LockTable();
        if NoSeriesLine.FindLast then;
        if AutoCostPosting then begin
            GLEntry.LockTable();
            if GLEntry.FindLast then;
        end;
    end;

    local procedure CopyTransLine(var NewTransferLine: Record "Transfer Line"; TransferLine: Record "Transfer Line"; var NextLineNo: Integer; TransferHeader: Record "Transfer Header")
    begin
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
        NewTransferLine.ResetPostedQty;
        NewTransferLine."Outstanding Quantity" := NewTransferLine.Quantity;
        NewTransferLine."Outstanding Qty. (Base)" := NewTransferLine."Quantity (Base)";
        OnBeforeNewTransferLineInsert(NewTransferLine, TransferLine);
        NewTransferLine.Insert();
    end;

    local procedure ReleaseDocument(var TransferHeader: Record "Transfer Header")
    begin
        OnBeforeReleaseDocument(TransferHeader);

        if TransferHeader.Status = TransferHeader.Status::Open then begin
            CODEUNIT.Run(CODEUNIT::"Release Transfer Document", TransferHeader);
            TransferHeader.Status := TransferHeader.Status::Open;
            TransferHeader.Modify();
            if not SuppressCommit then
                Commit();
            TransferHeader.Status := TransferHeader.Status::Released;
        end;
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; TransferLine: Record "Transfer Line"; TransferShipmentHeader: Record "Transfer Shipment Header"; TransferShipmentLine: Record "Transfer Shipment Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferOrderPostShipment(var TransferHeader: Record "Transfer Header"; CommitIsSuppressed: Boolean)
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
    local procedure OnAfterInvtAdjmt(var TransferHeader: Record "Transfer Header"; var TransferShipmentHeader: Record "Transfer Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransLineModify(var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferOrderPostShipment(var TransferHeader: Record "Transfer Header"; CommitIsSuppressed: Boolean; var TransferShipmentHeader: Record "Transfer Shipment Header")
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
    local procedure OnAfterInsertTransShptLine(var TransShptLine: Record "Transfer Shipment Line"; TransLine: Record "Transfer Line"; CommitIsSuppressed: Boolean)
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
    local procedure OnBeforeCopyTransLines(TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTransShptLine(var TransShptLine: Record "Transfer Shipment Line"; TransLine: Record "Transfer Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteOneTransferOrder(TransferHeader: Record "Transfer Header"; var DeleteOne: Boolean)
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
    local procedure OnBeforeNewTransferLineInsert(var NewTransferLine: Record "Transfer Line"; TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItem(var TransferShipmentHeader: Record "Transfer Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseDocument(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateWithWarehouseShipReceive(TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckTransLine(TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header"; Location: Record Location; WhseShip: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTransShptLineOnAfterCreatePostedShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var PostedWhseShipmentLine: Record "Posted Whse. Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeCommit(var TransferHeader: Record "Transfer Header"; TransferShipmentHeader: Record "Transfer Shipment Header")
    begin
    end;
}

