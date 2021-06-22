codeunit 5705 "TransferOrder-Post Receipt"
{
    Permissions = TableData "Item Entry Relation" = i;
    TableNo = "Transfer Header";

    trigger OnRun()
    var
        Item: Record Item;
        SourceCodeSetup: Record "Source Code Setup";
        InvtSetup: Record "Inventory Setup";
        ValueEntry: Record "Value Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemApplnEntry: Record "Item Application Entry";
        ItemReg: Record "Item Register";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        ReservMgt: Codeunit "Reservation Management";
        RecordLinkManagement: Codeunit "Record Link Management";
        Window: Dialog;
        LineCount: Integer;
        DeleteOne: Boolean;
    begin
        ReleaseDocument(Rec);
        TransHeader := Rec;
        TransHeader.SetHideValidationDialog(HideValidationDialog);

        OnBeforeTransferOrderPostReceipt(TransHeader, SuppressCommit);

        with TransHeader do begin
            CheckBeforePost;

            WhseReference := "Posting from Whse. Ref.";
            "Posting from Whse. Ref." := 0;

            CheckDim;
            CheckLines(TransHeader, TransLine);

            WhseReceive := TempWhseRcptHeader.FindFirst;
            InvtPickPutaway := WhseReference <> 0;
            if not (WhseReceive or InvtPickPutaway) then
                CheckWarehouse(TransLine);

            WhsePosting := IsWarehousePosting("Transfer-to Code");

            if GuiAllowed then begin
                Window.Open(
                  '#1#################################\\' +
                  Text003);

                Window.Update(1, StrSubstNo(Text004, "No."));
            end;

            SourceCodeSetup.Get();
            SourceCode := SourceCodeSetup.Transfer;
            InvtSetup.Get();
            InvtSetup.TestField("Posted Transfer Rcpt. Nos.");

            CheckInvtPostingSetup;
            OnAfterCheckInvtPostingSetup(TransHeader, TempWhseRcptHeader, SourceCode);

            LockTables(InvtSetup."Automatic Cost Posting");

            // Insert receipt header
            if WhseReceive then
                PostedWhseRcptHeader.LockTable();
            TransRcptHeader.LockTable();
            InsertTransRcptHeader(TransRcptHeader, TransHeader, InvtSetup."Posted Transfer Rcpt. Nos.");

            if InvtSetup."Copy Comments Order to Rcpt." then begin
                CopyCommentLines(1, 3, "No.", TransRcptHeader."No.");
                RecordLinkManagement.CopyLinks(Rec, TransRcptHeader);
            end;

            if WhseReceive then begin
                WhseRcptHeader.Get(TempWhseRcptHeader."No.");
                WhsePostRcpt.CreatePostedRcptHeader(PostedWhseRcptHeader, WhseRcptHeader, TransRcptHeader."No.", "Posting Date");
            end;

            // Insert receipt lines
            LineCount := 0;
            if WhseReceive then
                PostedWhseRcptLine.LockTable();
            if InvtPickPutaway then
                WhseRqst.LockTable();
            TransRcptLine.LockTable();
            TransLine.SetRange(Quantity);
            TransLine.SetRange("Qty. to Receive");
            if TransLine.Find('-') then
                repeat
                    LineCount := LineCount + 1;
                    if GuiAllowed then
                        Window.Update(2, LineCount);

                    if TransLine."Item No." <> '' then begin
                        Item.Get(TransLine."Item No.");
                        Item.TestField(Blocked, false);
                    end;

                    OnCheckTransLine(TransLine, TransHeader, Location, WhseReceive);

                    InsertTransRcptLine(TransRcptHeader."No.", TransRcptLine, TransLine);
                until TransLine.Next = 0;

            if InvtSetup."Automatic Cost Adjustment" <> InvtSetup."Automatic Cost Adjustment"::Never then begin
                InvtAdjmt.SetProperties(true, InvtSetup."Automatic Cost Posting");
                InvtAdjmt.MakeMultiLevelAdjmt;
            end;

            ValueEntry.LockTable();
            ItemLedgEntry.LockTable();
            ItemApplnEntry.LockTable();
            ItemReg.LockTable();
            TransLine.LockTable();
            if WhsePosting then
                WhseEntry.LockTable();

            TransLine.SetFilter(Quantity, '<>0');
            TransLine.SetFilter("Qty. to Receive", '<>0');
            if TransLine.Find('-') then
                repeat
                    TransLine.Validate("Quantity Received", TransLine."Quantity Received" + TransLine."Qty. to Receive");
                    TransLine.UpdateWithWarehouseShipReceive;
                    ReservMgt.SetReservSource(ItemJnlLine);
                    ReservMgt.SetItemTrackingHandling(1); // Allow deletion
                    ReservMgt.DeleteReservEntries(true, 0);
                    TransLine.Modify();
                    OnAfterTransLineUpdateQtyReceived(TransLine, SuppressCommit);
                until TransLine.Next = 0;

            if WhseReceive then
                WhseRcptLine.LockTable();
            LockTable();
            if WhseReceive then begin
                WhsePostRcpt.PostUpdateWhseDocuments(WhseRcptHeader);
                TempWhseRcptHeader.Delete();
            end;

            "Last Receipt No." := TransRcptHeader."No.";
            Modify;

            TransLine.SetRange(Quantity);
            TransLine.SetRange("Qty. to Receive");
            DeleteOne := ShouldDeleteOneTransferOrder(TransLine);
            OnBeforeDeleteOneTransferHeader(TransHeader, DeleteOne);
            if DeleteOne then
                DeleteOneTransferOrder(TransHeader, TransLine)
            else begin
                WhseTransferRelease.Release(TransHeader);
                ReserveTransLine.UpdateItemTrackingAfterPosting(TransHeader, 1);
            end;

            if not (InvtPickPutaway or SuppressCommit) then begin
                Commit();
                UpdateAnalysisView.UpdateAll(0, true);
                UpdateItemAnalysisView.UpdateAll(0, true);
            end;
            Clear(WhsePostRcpt);
            Clear(InvtAdjmt);
            if GuiAllowed then
                Window.Close;
        end;

        Rec := TransHeader;

        OnAfterTransferOrderPostReceipt(Rec, SuppressCommit, TransRcptHeader);
    end;

    var
        Text001: Label 'There is nothing to post.';
        Text002: Label 'Warehouse handling is required for Transfer order = %1, %2 = %3.', Comment = '1%=TransLine2."Document No."; 2%=TransLine2.FIELDCAPTION("Line No."); 3%=TransLine2."Line No.");';
        Text003: Label 'Posting transfer lines     #2######';
        Text004: Label 'Transfer Order %1';
        Text005: Label 'The combination of dimensions used in transfer order %1 is blocked. %2.';
        Text006: Label 'The combination of dimensions used in transfer order %1, line no. %2 is blocked. %3.';
        Text007: Label 'The dimensions that are used in transfer order %1, line no. %2 are not valid. %3.';
        Text008: Label 'Base Qty. to Receive must be 0.';
        TransRcptHeader: Record "Transfer Receipt Header";
        TransRcptLine: Record "Transfer Receipt Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        ItemJnlLine: Record "Item Journal Line";
        Location: Record Location;
        NewLocation: Record Location;
        WhseRqst: Record "Warehouse Request";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        TempWhseRcptHeader: Record "Warehouse Receipt Header" temporary;
        WhseRcptLine: Record "Warehouse Receipt Line";
        PostedWhseRcptHeader: Record "Posted Whse. Receipt Header";
        PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
        TempWhseSplitSpecification: Record "Tracking Specification" temporary;
        WhseEntry: Record "Warehouse Entry";
        TempItemEntryRelation2: Record "Item Entry Relation" temporary;
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        DimMgt: Codeunit DimensionManagement;
        WhseTransferRelease: Codeunit "Whse.-Transfer Release";
        ReserveTransLine: Codeunit "Transfer Line-Reserve";
        WhsePostRcpt: Codeunit "Whse.-Post Receipt";
        InvtAdjmt: Codeunit "Inventory Adjustment";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        SourceCode: Code[10];
        HideValidationDialog: Boolean;
        WhsePosting: Boolean;
        WhseReference: Integer;
        OriginalQuantity: Decimal;
        OriginalQuantityBase: Decimal;
        WhseReceive: Boolean;
        InvtPickPutaway: Boolean;
        SuppressCommit: Boolean;

    local procedure PostItemJnlLine(var TransLine3: Record "Transfer Line"; TransRcptHeader2: Record "Transfer Receipt Header"; TransRcptLine2: Record "Transfer Receipt Line")
    var
        IsHandled: Boolean;
    begin
        OnBeforePostItemJnlLine(TransRcptHeader2, IsHandled, TransRcptLine2);
        if IsHandled then
            exit;

        ItemJnlLine.Init();
        ItemJnlLine."Posting Date" := TransRcptHeader2."Posting Date";
        ItemJnlLine."Document Date" := TransRcptHeader2."Posting Date";
        ItemJnlLine."Document No." := TransRcptHeader2."No.";
        ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Transfer Receipt";
        ItemJnlLine."Document Line No." := TransRcptLine2."Line No.";
        ItemJnlLine."Order Type" := ItemJnlLine."Order Type"::Transfer;
        ItemJnlLine."Order No." := TransRcptHeader2."Transfer Order No.";
        ItemJnlLine."Order Line No." := TransLine3."Line No.";
        ItemJnlLine."External Document No." := TransRcptHeader2."External Document No.";
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Transfer;
        ItemJnlLine."Item No." := TransRcptLine2."Item No.";
        ItemJnlLine.Description := TransRcptLine2.Description;
        ItemJnlLine."Shortcut Dimension 1 Code" := TransRcptLine2."Shortcut Dimension 1 Code";
        ItemJnlLine."New Shortcut Dimension 1 Code" := TransRcptLine2."Shortcut Dimension 1 Code";
        ItemJnlLine."Shortcut Dimension 2 Code" := TransRcptLine2."Shortcut Dimension 2 Code";
        ItemJnlLine."New Shortcut Dimension 2 Code" := TransRcptLine2."Shortcut Dimension 2 Code";
        ItemJnlLine."Dimension Set ID" := TransRcptLine2."Dimension Set ID";
        ItemJnlLine."New Dimension Set ID" := TransRcptLine2."Dimension Set ID";
        ItemJnlLine."Location Code" := TransHeader."In-Transit Code";
        ItemJnlLine."New Location Code" := TransRcptHeader2."Transfer-to Code";
        ItemJnlLine.Quantity := TransRcptLine2.Quantity;
        ItemJnlLine."Invoiced Quantity" := TransRcptLine2.Quantity;
        ItemJnlLine."Quantity (Base)" := TransRcptLine2."Quantity (Base)";
        ItemJnlLine."Invoiced Qty. (Base)" := TransRcptLine2."Quantity (Base)";
        ItemJnlLine."Source Code" := SourceCode;
        ItemJnlLine."Gen. Prod. Posting Group" := TransRcptLine2."Gen. Prod. Posting Group";
        ItemJnlLine."Inventory Posting Group" := TransRcptLine2."Inventory Posting Group";
        ItemJnlLine."Unit of Measure Code" := TransRcptLine2."Unit of Measure Code";
        ItemJnlLine."Qty. per Unit of Measure" := TransRcptLine2."Qty. per Unit of Measure";
        ItemJnlLine."Variant Code" := TransRcptLine2."Variant Code";
        ItemJnlLine."New Bin Code" := TransLine."Transfer-To Bin Code";
        ItemJnlLine."Item Category Code" := TransLine."Item Category Code";
        if TransHeader."In-Transit Code" <> '' then begin
            if NewLocation.Code <> TransHeader."In-Transit Code" then
                NewLocation.Get(TransHeader."In-Transit Code");
            ItemJnlLine."Country/Region Code" := NewLocation."Country/Region Code";
        end;
        ItemJnlLine."Transaction Type" := TransRcptHeader2."Transaction Type";
        ItemJnlLine."Transport Method" := TransRcptHeader2."Transport Method";
        ItemJnlLine."Entry/Exit Point" := TransRcptHeader2."Entry/Exit Point";
        ItemJnlLine.Area := TransRcptHeader2.Area;
        ItemJnlLine."Transaction Specification" := TransRcptHeader2."Transaction Specification";
        ItemJnlLine."Shpt. Method Code" := TransRcptHeader2."Shipment Method Code";
        ItemJnlLine."Direct Transfer" := TransLine."Direct Transfer";
        WriteDownDerivedLines(TransLine3);
        ItemJnlPostLine.SetPostponeReservationHandling(true);

        OnBeforePostItemJournalLine(ItemJnlLine, TransLine3, TransRcptHeader2, TransRcptLine2, SuppressCommit);
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
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
                Error(
                  Text007,
                  TransHeader."No.", TransferLine."Line No.", DimMgt.GetDimValuePostingErr);

        if TransferLine."Line No." <> 0 then
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, TransferLine."Dimension Set ID") then
                Error(
                  Text007,
                  TransHeader."No.", TransferLine."Line No.", DimMgt.GetDimValuePostingErr);
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    local procedure WriteDownDerivedLines(var TransLine3: Record "Transfer Line")
    var
        TransLine4: Record "Transfer Line";
        T337: Record "Reservation Entry";
        TempDerivedSpecification: Record "Tracking Specification" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        QtyToReceive: Decimal;
        BaseQtyToReceive: Decimal;
        TrackingSpecificationExists: Boolean;
    begin
        TransLine4.SetRange("Document No.", TransLine3."Document No.");
        TransLine4.SetRange("Derived From Line No.", TransLine3."Line No.");
        if TransLine4.Find('-') then begin
            QtyToReceive := TransLine3."Qty. to Receive";
            BaseQtyToReceive := TransLine3."Qty. to Receive (Base)";

            T337.SetCurrentKey(
              "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
              "Source Batch Name", "Source Prod. Order Line");
            T337.SetRange("Source ID", TransLine3."Document No.");
            T337.SetRange("Source Ref. No.");
            T337.SetRange("Source Type", DATABASE::"Transfer Line");
            T337.SetRange("Source Subtype", 1);
            T337.SetRange("Source Batch Name", '');
            T337.SetRange("Source Prod. Order Line", TransLine3."Line No.");
            T337.SetFilter("Qty. to Handle (Base)", '<>0');

            TrackingSpecificationExists :=
              ItemTrackingMgt.SumUpItemTracking(T337, TempDerivedSpecification, true, false);

            repeat
                if TrackingSpecificationExists then begin
                    TempDerivedSpecification.SetRange("Source Ref. No.", TransLine4."Line No.");
                    if TempDerivedSpecification.FindFirst then begin
                        TransLine4."Qty. to Receive (Base)" := TempDerivedSpecification."Qty. to Handle (Base)";
                        TransLine4."Qty. to Receive" := TempDerivedSpecification."Qty. to Handle";
                    end else begin
                        TransLine4."Qty. to Receive (Base)" := 0;
                        TransLine4."Qty. to Receive" := 0;
                    end;
                end;
                if TransLine4."Qty. to Receive (Base)" <= BaseQtyToReceive then begin
                    ReserveTransLine.TransferTransferToItemJnlLine(
                      TransLine4, ItemJnlLine, TransLine4."Qty. to Receive (Base)", 1);
                    TransLine4."Quantity (Base)" :=
                      TransLine4."Quantity (Base)" - TransLine4."Qty. to Receive (Base)";
                    TransLine4.Quantity :=
                      TransLine4.Quantity - TransLine4."Qty. to Receive";
                    BaseQtyToReceive := BaseQtyToReceive - TransLine4."Qty. to Receive (Base)";
                    QtyToReceive := QtyToReceive - TransLine4."Qty. to Receive";
                end else begin
                    ReserveTransLine.TransferTransferToItemJnlLine(
                      TransLine4, ItemJnlLine, BaseQtyToReceive, 1);
                    TransLine4.Quantity := TransLine4.Quantity - QtyToReceive;
                    TransLine4."Quantity (Base)" := TransLine4."Quantity (Base)" - BaseQtyToReceive;
                    BaseQtyToReceive := 0;
                    QtyToReceive := 0;
                end;
                if TransLine4."Quantity (Base)" = 0 then
                    TransLine4.Delete
                else begin
                    TransLine4."Qty. to Ship" := TransLine4.Quantity;
                    TransLine4."Qty. to Ship (Base)" := TransLine4."Quantity (Base)";
                    TransLine4."Qty. to Receive" := TransLine4.Quantity;
                    TransLine4."Qty. to Receive (Base)" := TransLine4."Quantity (Base)";
                    TransLine4.ResetPostedQty;
                    TransLine4."Outstanding Quantity" := TransLine4.Quantity;
                    TransLine4."Outstanding Qty. (Base)" := TransLine4."Quantity (Base)";

                    OnWriteDownDerivedLinesOnBeforeTransLineModify(TransLine4, TransLine3);
                    TransLine4.Modify();
                end;
            until (TransLine4.Next = 0) or (BaseQtyToReceive = 0);
        end;

        if BaseQtyToReceive <> 0 then
            Error(Text008);
    end;

    local procedure InsertRcptEntryRelation(var TransRcptLine: Record "Transfer Receipt Line"): Integer
    var
        ItemEntryRelation: Record "Item Entry Relation";
        TempItemEntryRelation: Record "Item Entry Relation" temporary;
    begin
        TempItemEntryRelation2.Reset();
        TempItemEntryRelation2.DeleteAll();

        if ItemJnlPostLine.CollectItemEntryRelation(TempItemEntryRelation) then begin
            if TempItemEntryRelation.Find('-') then begin
                repeat
                    ItemEntryRelation := TempItemEntryRelation;
                    ItemEntryRelation.TransferFieldsTransRcptLine(TransRcptLine);
                    ItemEntryRelation.Insert();
                    TempItemEntryRelation2 := TempItemEntryRelation;
                    TempItemEntryRelation2.Insert();
                until TempItemEntryRelation.Next = 0;
                exit(0);
            end;
        end else
            exit(ItemJnlLine."Item Shpt. Entry No.");
    end;

    local procedure InsertTransRcptHeader(var TransRcptHeader: Record "Transfer Receipt Header"; TransHeader: Record "Transfer Header"; NoSeries: Code[20])
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
        Handled: Boolean;
    begin
        OnBeforeInsertTransRcptHeader(TransRcptHeader, TransHeader, SuppressCommit, Handled);
        if Handled then
            exit;

        TransRcptHeader.Init();
        TransRcptHeader.CopyFromTransferHeader(TransHeader);
        TransRcptHeader."No. Series" := NoSeries;
        TransRcptHeader."No." := NoSeriesMgt.GetNextNo(NoSeries, TransHeader."Posting Date", true);
        OnBeforeTransRcptHeaderInsert(TransRcptHeader, TransHeader);
        TransRcptHeader.Insert();
    end;

    local procedure InsertTransRcptLine(ReceiptNo: Code[20]; var TransRcptLine: Record "Transfer Receipt Line"; TransLine: Record "Transfer Line")
    begin
        TransRcptLine.Init();
        TransRcptLine."Document No." := ReceiptNo;
        TransRcptLine.CopyFromTransferLine(TransLine);
        OnBeforeInsertTransRcptLine(TransRcptLine, TransLine, SuppressCommit);
        TransRcptLine.Insert();
        OnAfterInsertTransRcptLine(TransRcptLine, TransLine, SuppressCommit);

        if TransLine."Qty. to Receive" > 0 then begin
            OriginalQuantity := TransLine."Qty. to Receive";
            OriginalQuantityBase := TransLine."Qty. to Receive (Base)";
            PostItemJnlLine(TransLine, TransRcptHeader, TransRcptLine);
            TransRcptLine."Item Rcpt. Entry No." := InsertRcptEntryRelation(TransRcptLine);
            TransRcptLine.Modify();
            SaveTempWhseSplitSpec(TransLine);
            if WhseReceive then begin
                WhseRcptLine.SetCurrentKey(
                  "No.", "Source Type", "Source Subtype", "Source No.", "Source Line No.");
                WhseRcptLine.SetRange("No.", WhseRcptHeader."No.");
                WhseRcptLine.SetRange("Source Type", DATABASE::"Transfer Line");
                WhseRcptLine.SetRange("Source No.", TransLine."Document No.");
                WhseRcptLine.SetRange("Source Line No.", TransLine."Line No.");
                if WhseRcptLine.FindFirst then begin
                    WhseRcptLine.TestField("Qty. to Receive", TransRcptLine.Quantity);
                    WhsePostRcpt.SetItemEntryRelation(PostedWhseRcptHeader, PostedWhseRcptLine, TempItemEntryRelation2);
                    WhsePostRcpt.CreatePostedRcptLine(
                      WhseRcptLine, PostedWhseRcptHeader, PostedWhseRcptLine, TempWhseSplitSpecification);
                end;
            end;
            if WhsePosting then
                PostWhseJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase, TempWhseSplitSpecification);
            OnAfterTransRcptLineModify(TransRcptLine, TransLine, SuppressCommit);
        end;
    end;

    local procedure CheckLines(TransHeader: Record "Transfer Header"; var TransLine: Record "Transfer Line")
    begin
        with TransHeader do begin
            TransLine.Reset();
            TransLine.SetRange("Document No.", "No.");
            TransLine.SetRange("Derived From Line No.", 0);
            TransLine.SetFilter(Quantity, '<>0');
            TransLine.SetFilter("Qty. to Receive", '<>0');
            if not TransLine.Find('-') then
                Error(Text001);
        end;
    end;

    local procedure CheckWarehouse(var TransLine: Record "Transfer Line")
    var
        TransLine2: Record "Transfer Line";
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        ShowError: Boolean;
    begin
        TransLine2.Copy(TransLine);
        if TransLine2.Find('-') then
            repeat
                GetLocation(TransLine2."Transfer-to Code");
                if Location."Require Receive" or Location."Require Put-away" then begin
                    if Location."Bin Mandatory" then
                        ShowError := true
                    else
                        if WhseValidateSourceLine.WhseLinesExist(
                             DATABASE::"Transfer Line",
                             1,// In
                             TransLine2."Document No.",
                             TransLine2."Line No.",
                             0,
                             TransLine2.Quantity)
                        then
                            ShowError := true;

                    if ShowError then
                        Error(
                          Text002,
                          TransLine2."Document No.",
                          TransLine2.FieldCaption("Line No."),
                          TransLine2."Line No.");
                end;
            until TransLine2.Next = 0;
    end;

    local procedure SaveTempWhseSplitSpec(TransLine: Record "Transfer Line")
    var
        TempHandlingSpecification: Record "Tracking Specification" temporary;
    begin
        TempWhseSplitSpecification.Reset();
        TempWhseSplitSpecification.DeleteAll();
        if ItemJnlPostLine.CollectTrackingSpecification(TempHandlingSpecification) then
            if TempHandlingSpecification.Find('-') then
                repeat
                    TempWhseSplitSpecification := TempHandlingSpecification;
                    TempWhseSplitSpecification."Entry No." := TempHandlingSpecification."Transfer Item Entry No.";
                    TempWhseSplitSpecification."Source Type" := DATABASE::"Transfer Line";
                    TempWhseSplitSpecification."Source Subtype" := 1;
                    TempWhseSplitSpecification."Source ID" := TransLine."Document No.";
                    TempWhseSplitSpecification."Source Ref. No." := TransLine."Line No.";
                    TempWhseSplitSpecification.Insert();
                until TempHandlingSpecification.Next = 0;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Location.GetLocationSetup(LocationCode, Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure IsWarehousePosting(LocationCode: Code[10]): Boolean
    begin
        GetLocation(LocationCode);
        if Location."Bin Mandatory" and not (WhseReceive or InvtPickPutaway) then
            exit(true);
        exit(false);
    end;

    local procedure PostWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; OriginalQuantity: Decimal; OriginalQuantityBase: Decimal; var TempHandlingSpecification: Record "Tracking Specification" temporary)
    var
        WhseJnlLine: Record "Warehouse Journal Line";
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WMSMgmt: Codeunit "WMS Management";
    begin
        with ItemJnlLine do begin
            Quantity := OriginalQuantity;
            "Quantity (Base)" := OriginalQuantityBase;
            GetLocation("New Location Code");
            if Location."Bin Mandatory" then
                if WMSMgmt.CreateWhseJnlLine(ItemJnlLine, 1, WhseJnlLine, true) then begin
                    WMSMgmt.SetTransferLine(TransLine, WhseJnlLine, 1, TransRcptHeader."No.");
                    ItemTrackingMgt.SplitWhseJnlLine(WhseJnlLine, TempWhseJnlLine2, TempHandlingSpecification, true);
                    if TempWhseJnlLine2.Find('-') then
                        repeat
                            WMSMgmt.CheckWhseJnlLine(TempWhseJnlLine2, 1, 0, true);
                            WhseJnlRegisterLine.RegisterWhseJnlLine(TempWhseJnlLine2);
                        until TempWhseJnlLine2.Next = 0;
                end;
        end;
    end;

    procedure SetWhseRcptHeader(var WhseRcptHeader2: Record "Warehouse Receipt Header")
    begin
        WhseRcptHeader := WhseRcptHeader2;
        TempWhseRcptHeader := WhseRcptHeader;
        TempWhseRcptHeader.Insert();
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
    local procedure OnBeforePostItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; TransferLine: Record "Transfer Line"; TransferReceiptHeader: Record "Transfer Receipt Header"; TransferReceiptLine: Record "Transfer Receipt Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferOrderPostReceipt(var TransferHeader: Record "Transfer Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertTransRcptLine(var TransRcptLine: Record "Transfer Receipt Line"; TransLine: Record "Transfer Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferOrderPostReceipt(var TransferHeader: Record "Transfer Header"; CommitIsSuppressed: Boolean; var TransferReceiptHeader: Record "Transfer Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransLineUpdateQtyReceived(var TransferLine: Record "Transfer Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransRcptLineModify(var TransferReceiptLine: Record "Transfer Receipt Line"; TransferLine: Record "Transfer Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDimValuePosting(TransferHeader: Record "Transfer Header"; TransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTransRcptHeader(var TransRcptHeader: Record "Transfer Receipt Header"; TransHeader: Record "Transfer Header"; CommitIsSuppressed: Boolean; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTransRcptLine(var TransRcptLine: Record "Transfer Receipt Line"; TransLine: Record "Transfer Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransRcptHeaderInsert(var TransferReceiptHeader: Record "Transfer Receipt Header"; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteOneTransferHeader(TransferHeader: Record "Transfer Header"; var DeleteOne: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLine(var TransferReceiptHeader: Record "Transfer Receipt Header"; var IsHandled: Boolean; TransferReceiptLine: Record "Transfer Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseDocument(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckInvtPostingSetup(var TransferHeader: Record "Transfer Header"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var SourceCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckTransLine(TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header"; Location: Record Location; WhseReceive: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWriteDownDerivedLinesOnBeforeTransLineModify(var TransferLine: Record "Transfer Line"; SourceTransferLine: Record "Transfer Line")
    begin
    end;
}

