codeunit 5850 "Invt. Doc.-Post Receipt"
{
    Permissions = TableData "Item Entry Relation" = ri,
                  TableData "Value Entry Relation" = ri,
                  TableData "Invt. Receipt Header" = rimd,
                  TableData "Invt. Receipt Line" = rimd;
    TableNo = "Invt. Document Header";

    trigger OnRun()
    var
        Item: Record Item;
        SourceCodeSetup: Record "Source Code Setup";
        InvtSetup: Record "Inventory Setup";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        UpdateAnalysisView: Codeunit "Update Analysis View";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        InvtAdjmtHandler: Codeunit "Inventory Adjustment Handler";
        Window: Dialog;
        LineCount: Integer;
        HideProgressWindow: Boolean;
        SuppressCommit: Boolean;
    begin
        OnBeforeOnRun(Rec, SuppressCommit, HideProgressWindow);

        Rec.TestField("Document Type", Rec."Document Type"::Receipt);

        InvtDocHeader := Rec;
        InvtDocHeader.SetHideValidationDialog(HideValidationDialog);

        with InvtDocHeader do begin
            CheckInvtDocumentHeaderMandatoryFields(InvtDocHeader);

            CheckDim();

            SetInvtDocumentLineFiltersFromDocument(InvtDocLine, InvtDocHeader);
            if not InvtDocLine.Find('-') then
                Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());

            GetLocation("Location Code");
            if Location."Require Receive" or Location."Require Put-away" then
                Error(WarehouseHandlingRequiredErr, "Location Code");

            if not HideProgressWindow then begin
                Window.Open('#1#################################\\' + PostingLinesMsg);

                Window.Update(1, StrSubstNo(PostingDocumentTxt, "No."));
            end;

            SourceCodeSetup.Get();
            SourceCode := SourceCodeSetup."Invt. Receipt";
            InvtSetup.Get();
            InvtSetup.TestField("Posted Invt. Receipt Nos.");
            InventoryPostingSetup.SetRange("Location Code", "Location Code");
            if InventoryPostingSetup.IsEmpty() then
                error(InventoryPostingSetupMissingErr, "Location Code");

            if Status = Status::Open then begin
                CODEUNIT.Run(CODEUNIT::"Release Invt. Document", InvtDocHeader);
                Status := Status::Open;
                Modify();
                if not (SuppressCommit or PreviewMode) then
                    Commit();
                Status := Status::Released;
                OnRunOnAfterSetStatusReleased(InvtDocHeader, InvtDocLine, SuppressCommit);
            end;

            TestField(Status, Status::Released);

            NoSeriesLine.LockTable();
            if NoSeriesLine.FindLast() then;
            if InvtSetup."Automatic Cost Posting" then begin
                GLEntry.LockTable();
                if GLEntry.FindLast() then;
            end;

            // Insert receipt header
            InvtRcptHeader.LockTable();
            InvtRcptHeader.Init();
            OnRunOnAfterInvtRcptHeaderInit(InvtRcptHeader, InvtDocHeader);
            InvtRcptHeader."Location Code" := "Location Code";
            InvtRcptHeader."Document Date" := "Document Date";
            InvtRcptHeader."Posting Date" := "Posting Date";
            InvtRcptHeader."Purchaser Code" := "Salesperson/Purchaser Code";
            InvtRcptHeader."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
            InvtRcptHeader."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
            InvtRcptHeader."Receipt No." := "No.";
            InvtRcptHeader."External Document No." := "External Document No.";
            InvtRcptHeader."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
            if "No. Series" = "Posting No. Series" then
                InvtRcptHeader."No." := "No."
            else begin
                if "Posting No." = '' then
                    "Posting No." := NoSeriesMgt.GetNextNo("Posting No. Series", "Posting Date", true);
                InvtRcptHeader."No." := "Posting No.";
            end;
            InvtRcptHeader."No. Series" := "Posting No. Series";
            InvtRcptHeader."Posting Description" := "Posting Description";
            InvtRcptHeader.Correction := Correction;
            InvtRcptHeader."Dimension Set ID" := "Dimension Set ID";
            OnRunOnBeforeInvtRcptHeaderInsert(InvtRcptHeader, InvtDocHeader);
            InvtRcptHeader.Insert();
            OnRunOnAfterInvtRcptHeaderInsert(InvtRcptHeader, InvtDocHeader);

            if InvtSetup."Copy Comments to Invt. Doc." then
                CopyCommentLines(
                    "Inventory Comment Document Type"::"Inventory Receipt",
                    "Inventory Comment Document Type"::"Posted Inventory Receipt",
                    "No.", InvtRcptHeader."No.");

            // Insert receipt lines
            LineCount := 0;
            InvtRcptLine.LockTable();
            InvtDocLine.SetRange(Quantity);
            OnRunOnBeforeInvtDocLineFind(InvtDocLine, InvtDocHeader);
            if InvtDocLine.Find('-') then
                repeat
                    LineCount := LineCount + 1;
                    if not HideProgressWindow then
                        Window.Update(2, LineCount);

                    if InvtDocLine."Item No." <> '' then begin
                        Item.Get(InvtDocLine."Item No.");
                        Item.TestField(Blocked, false);
                    end;

                    InvtRcptLine.Init();
                    OnRunOnAfterInvtRcptLineInit(InvtRcptLine, InvtDocLine, InvtRcptHeader, InvtDocHeader);
                    InvtRcptLine."Document No." := InvtRcptHeader."No.";
                    InvtRcptLine."Posting Date" := InvtRcptHeader."Posting Date";
                    InvtRcptLine."Document Date" := InvtRcptHeader."Document Date";
                    InvtRcptLine."Line No." := InvtDocLine."Line No.";
                    InvtRcptLine."Item No." := InvtDocLine."Item No.";
                    InvtRcptLine.Description := InvtDocLine.Description;
                    InvtRcptLine.Quantity := InvtDocLine.Quantity;
                    InvtRcptLine."Unit Amount" := InvtDocLine."Unit Amount";
                    InvtRcptLine."Unit Cost" := InvtDocLine."Unit Cost";
                    InvtRcptLine.Amount := InvtDocLine.Amount;
                    InvtRcptLine."Indirect Cost %" := InvtDocLine."Indirect Cost %";
                    InvtRcptLine."Unit of Measure Code" := InvtDocLine."Unit of Measure Code";
                    InvtRcptLine."Shortcut Dimension 1 Code" := InvtDocLine."Shortcut Dimension 1 Code";
                    InvtRcptLine."Shortcut Dimension 2 Code" := InvtDocLine."Shortcut Dimension 2 Code";
                    InvtRcptLine."Gen. Bus. Posting Group" := InvtDocLine."Gen. Bus. Posting Group";
                    InvtRcptLine."Gen. Prod. Posting Group" := InvtDocLine."Gen. Prod. Posting Group";
                    InvtRcptLine."Inventory Posting Group" := InvtDocLine."Inventory Posting Group";
                    InvtRcptLine."Quantity (Base)" := InvtDocLine."Quantity (Base)";
                    InvtRcptLine."Qty. per Unit of Measure" := InvtDocLine."Qty. per Unit of Measure";
                    InvtRcptLine."Qty. Rounding Precision" := InvtDocLine."Qty. Rounding Precision";
                    InvtRcptLine."Qty. Rounding Precision (Base)" := InvtDocLine."Qty. Rounding Precision (Base)";
                    InvtRcptLine."Unit of Measure Code" := InvtDocLine."Unit of Measure Code";
                    InvtRcptLine."Gross Weight" := InvtDocLine."Gross Weight";
                    InvtRcptLine."Net Weight" := InvtDocLine."Net Weight";
                    InvtRcptLine."Unit Volume" := InvtDocLine."Unit Volume";
                    InvtRcptLine."Variant Code" := InvtDocLine."Variant Code";
                    InvtRcptLine."Units per Parcel" := InvtDocLine."Units per Parcel";
                    InvtRcptLine."Receipt No." := InvtDocLine."Document No.";
                    InvtRcptLine."Document Date" := InvtDocLine."Document Date";
                    InvtRcptLine."Location Code" := InvtDocLine."Location Code";
                    InvtRcptLine."Bin Code" := InvtDocLine."Bin Code";
                    InvtRcptLine."Item Category Code" := InvtDocLine."Item Category Code";
                    InvtRcptLine."Applies-to Entry" := InvtDocLine."Applies-to Entry";
                    InvtRcptLine."Applies-from Entry" := InvtDocLine."Applies-from Entry";
                    InvtRcptLine."Dimension Set ID" := InvtDocLine."Dimension Set ID";
                    InvtRcptLine."Reason Code" := InvtDocLine."Reason Code";
                    OnRunOnBeforeInvtRcptLineInsert(InvtRcptLine, InvtDocLine);
                    InvtRcptLine.Insert();
                    OnRunOnAfterInvtRcptLineInsert(InvtRcptLine, InvtDocLine, InvtRcptHeader, InvtDocHeader);

                    PostItemJnlLine(InvtRcptHeader, InvtRcptLine);
                    ItemJnlPostLine.CollectValueEntryRelation(TempValueEntryRelation, InvtRcptLine.RowID1());
                until InvtDocLine.Next() = 0;

            OnRunOnAfterInvtDocPost(InvtDocHeader, InvtDocLine);

            InvtSetup.Get();
            if InvtSetup.AutomaticCostAdjmtRequired() then
                InvtAdjmtHandler.MakeInventoryAdjustment(true, InvtSetup."Automatic Cost Posting");

            LockTable();
            Delete(true);

            InsertValueEntryRelation();
            OnRunOnBeforeCommitPostInvtRcptDoc(InvtDocHeader, InvtDocLine, InvtRcptHeader, InvtRcptLine, ItemJnlLine, SuppressCommit);
            if not (SuppressCommit or PreviewMode) then
                Commit();
            OnRunOnAfterCommitPostInvtRcptDoc(InvtDocHeader, InvtDocLine, InvtRcptHeader, InvtRcptLine, ItemJnlLine, SuppressCommit);
            if not HideProgressWindow then
                Window.Close();
        end;

        UpdateAnalysisView.UpdateAll(0, true);
        UpdateItemAnalysisView.UpdateAll(0, true);
        Rec := InvtDocHeader;

        OnAfterOnRun(Rec, InvtDocHeader, InvtDocLine, InvtRcptHeader, InvtRcptLine);
    end;

    var
        InvtRcptHeader: Record "Invt. Receipt Header";
        InvtRcptLine: Record "Invt. Receipt Line";
        InvtDocHeader: Record "Invt. Document Header";
        InvtDocLine: Record "Invt. Document Line";
        ItemJnlLine: Record "Item Journal Line";
        Location: Record Location;
        TempValueEntryRelation: Record "Value Entry Relation" temporary;
        NoSeriesLine: Record "No. Series Line";
        GLEntry: Record "G/L Entry";
        WMSMgmt: Codeunit "WMS Management";
        WhseJnlPostLine: Codeunit "Whse. Jnl.-Register Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        DimMgt: Codeunit DimensionManagement;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        ReserveInvtDocLine: Codeunit "Invt. Doc. Line-Reserve";
        SourceCode: Code[10];
        HideValidationDialog: Boolean;
        PreviewMode: Boolean;
        WarehouseHandlingRequiredErr: Label 'Warehouse handling is required for Location Code %1.', Comment = '%1 - location code';
        PostingLinesMsg: Label 'Posting item receipt lines     #2######', Comment = '#2 - line counter';
        PostingDocumentTxt: Label 'Item Receipt %1', Comment = '%1 - document number';
        DimCombBlockedErr: Label 'The combination of dimensions used in item receipt %1 is blocked. %2', Comment = '%1 - document number, %2 - error message';
        DimCombLineBlockedErr: Label 'The combination of dimensions used in item receipt %1, line no. %2 is blocked. %3', Comment = '%1 - document number, %2 = line number, %3 - error message';
        DimInvalidErr: Label 'The dimensions used in item receipt %1, line no. %2 are invalid. %3', Comment = '%1 - document number, %2 = line number, %3 - error message';
        InventoryPostingSetupMissingErr: Label 'Inventory posting setup missing for location code %1.', Comment = '%1 - location code';

    local procedure CheckInvtDocumentHeaderMandatoryFields(var InvtDocumentHeader: Record "Invt. Document Header")
    begin
        OnBeforeCheckInvtDocumentHeaderMandatoryFields(InvtDocumentHeader);

        InvtDocumentHeader.TestField("No.");
        InvtDocumentHeader.TestField("Posting Date");

        OnAfterCheckInvtDocumentHeaderMandatoryFields(InvtDocumentHeader);
    end;

    local procedure SetInvtDocumentLineFiltersFromDocument(var InvtDocumentLine: Record "Invt. Document Line"; InvtDocumentHeader: Record "Invt. Document Header")
    begin
        InvtDocumentLine.Reset();
        InvtDocumentLine.SetRange("Document Type", InvtDocumentHeader."Document Type");
        InvtDocumentLine.SetRange("Document No.", InvtDocumentHeader."No.");
        InvtDocumentLine.SetFilter(Quantity, '>0');

        OnAfterSetInvtDocumentLineFiltersFromDocument(InvtDocumentLine, InvtDocumentHeader);
    end;

    local procedure PostItemJnlLine(InvtRcptHeader2: Record "Invt. Receipt Header"; InvtRcptLine2: Record "Invt. Receipt Line")
    var
        TempHandlingSpecification: Record "Tracking Specification" temporary;
        OriginalQuantity: Decimal;
        OriginalQuantityBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemJnlLine(InvtRcptHeader2, InvtRcptLine2, IsHandled);
        if IsHandled then
            exit;

        ItemJnlLine.Init();
        OnPostItemJnlLineOnAfterItemJnlLineInit(ItemJnlLine, InvtRcptHeader2, InvtRcptLine2);
        ItemJnlLine."Posting Date" := InvtRcptHeader2."Posting Date";
        ItemJnlLine."Document Date" := InvtRcptHeader2."Document Date";
        ItemJnlLine."Document No." := InvtRcptHeader2."No.";
        ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Inventory Receipt";
        ItemJnlLine."Document Line No." := InvtRcptLine2."Line No.";
        ItemJnlLine."External Document No." := InvtRcptHeader2."External Document No.";
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::"Positive Adjmt.";
        ItemJnlLine."Item No." := InvtRcptLine2."Item No.";
        ItemJnlLine.Description := InvtRcptLine2.Description;
        ItemJnlLine."Shortcut Dimension 1 Code" := InvtRcptLine2."Shortcut Dimension 1 Code";
        ItemJnlLine."Shortcut Dimension 2 Code" := InvtRcptLine2."Shortcut Dimension 2 Code";
        ItemJnlLine."Location Code" := InvtRcptHeader2."Location Code";

        if InvtRcptHeader2.Correction then begin
            ItemJnlLine.Quantity := -InvtRcptLine2.Quantity;
            ItemJnlLine."Invoiced Quantity" := -InvtRcptLine2.Quantity;
            ItemJnlLine."Quantity (Base)" := -InvtRcptLine2."Quantity (Base)";
            ItemJnlLine."Invoiced Qty. (Base)" := -InvtRcptLine2."Quantity (Base)";
            ItemJnlLine.Amount := -InvtRcptLine2.Amount;
        end
        else begin
            ItemJnlLine.Quantity := InvtRcptLine2.Quantity;
            ItemJnlLine."Invoiced Quantity" := InvtRcptLine2.Quantity;
            ItemJnlLine."Quantity (Base)" := InvtRcptLine2."Quantity (Base)";
            ItemJnlLine."Invoiced Qty. (Base)" := InvtRcptLine2."Quantity (Base)";
            ItemJnlLine.Amount := InvtRcptLine2.Amount;
        end;
        OnAfterFillItemJournalLineQtyFromInvtShipmentLine(ItemJnlLine, InvtRcptLine2, InvtRcptHeader2);

        ItemJnlLine."Unit Amount" := InvtRcptLine2."Unit Amount";
        ItemJnlLine."Unit Cost" := InvtRcptLine2."Unit Cost";
        ItemJnlLine."Indirect Cost %" := InvtRcptLine2."Indirect Cost %";
        ItemJnlLine."Source Code" := SourceCode;
        ItemJnlLine."Gen. Bus. Posting Group" := InvtRcptLine2."Gen. Bus. Posting Group";
        ItemJnlLine."Gen. Prod. Posting Group" := InvtRcptLine2."Gen. Prod. Posting Group";
        ItemJnlLine."Inventory Posting Group" := InvtRcptLine2."Inventory Posting Group";
        ItemJnlLine."Unit of Measure Code" := InvtRcptLine2."Unit of Measure Code";
        ItemJnlLine."Qty. per Unit of Measure" := InvtRcptLine2."Qty. per Unit of Measure";
        ItemJnlLine."Qty. Rounding Precision" := InvtRcptLine2."Qty. Rounding Precision";
        ItemJnlLine."Qty. Rounding Precision (Base)" := InvtRcptLine2."Qty. Rounding Precision (Base)";
        ItemJnlLine."Variant Code" := InvtRcptLine2."Variant Code";
        ItemJnlLine."Bin Code" := InvtDocLine."Bin Code";
        ItemJnlLine."Item Category Code" := InvtRcptLine2."Item Category Code";
        ItemJnlLine."Applies-to Entry" := InvtRcptLine2."Applies-to Entry";
        ItemJnlLine."Applies-from Entry" := InvtRcptLine2."Applies-from Entry";

        ItemJnlLine."Bin Code" := InvtRcptLine2."Bin Code";
        ItemJnlLine."Dimension Set ID" := InvtRcptLine2."Dimension Set ID";
        ItemJnlLine."Reason Code" := InvtRcptLine2."Reason Code";

        OnPostItemJnlLineOnBeforeTransferInvtDocToItemJnlLine(InvtDocLine, ItemJnlLine, InvtRcptHeader2, InvtRcptLine2);
        ReserveInvtDocLine.TransferInvtDocToItemJnlLine(InvtDocLine, ItemJnlLine, ItemJnlLine.Quantity);

        OriginalQuantity := ItemJnlLine.Quantity;
        OriginalQuantityBase := ItemJnlLine."Quantity (Base)";

        OnPostItemJnlLineOnBeforeItemJnlPostLineRunWithCheck(ItemJnlLine, InvtRcptHeader2, InvtRcptLine2);
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);

        ItemJnlPostLine.CollectTrackingSpecification(TempHandlingSpecification);
        PostWhseJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase, TempHandlingSpecification);

        OnAfterPostItemJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase, TempHandlingSpecification, InvtRcptHeader2, InvtRcptLine2);
    end;

    local procedure CopyCommentLines(FromDocumentType: Enum "Inventory Comment Document Type"; ToDocumentType: Enum "Inventory Comment Document Type"; FromNumber: Code[20]; ToNumber: Code[20])
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
            until InvtCommentLine.Next() = 0;
    end;

    local procedure CheckDim()
    begin
        InvtDocLine."Line No." := 0;
        CheckDimComb(InvtDocHeader, InvtDocLine);
        CheckDimValuePosting(InvtDocHeader, InvtDocLine);

        InvtDocLine.SetRange("Document Type", InvtDocHeader."Document Type");
        InvtDocLine.SetRange("Document No.", InvtDocHeader."No.");
        if InvtDocLine.FindFirst() then begin
            CheckDimComb(InvtDocHeader, InvtDocLine);
            CheckDimValuePosting(InvtDocHeader, InvtDocLine);
        end;
    end;

    local procedure CheckDimComb(InvtDocHeader: Record "Invt. Document Header"; InvtDocLine: Record "Invt. Document Line")
    begin
        if InvtDocLine."Line No." = 0 then
            if not DimMgt.CheckDimIDComb(InvtDocHeader."Dimension Set ID") then
                Error(DimCombBlockedErr, InvtDocHeader."No.", DimMgt.GetDimCombErr());
        if InvtDocLine."Line No." <> 0 then
            if not DimMgt.CheckDimIDComb(InvtDocLine."Dimension Set ID") then
                Error(DimCombLineBlockedErr, InvtDocHeader."No.", InvtDocLine."Line No.", DimMgt.GetDimCombErr());
    end;

    local procedure CheckDimValuePosting(InvtDocHeader: Record "Invt. Document Header"; InvtDocLine: Record "Invt. Document Line")
    var
        TableIDArr: array[10] of Integer;
        NumberArr: array[10] of Code[20];
    begin
        TableIDArr[1] := DATABASE::Item;
        NumberArr[1] := InvtDocLine."Item No.";
        if InvtDocLine."Line No." = 0 then
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, InvtDocHeader."Dimension Set ID") then
                Error(DimInvalidErr, InvtDocHeader."No.", InvtDocLine."Line No.", DimMgt.GetDimValuePostingErr());

        if InvtDocLine."Line No." <> 0 then
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, InvtDocLine."Dimension Set ID") then
                Error(DimInvalidErr, InvtDocHeader."No.", InvtDocLine."Line No.", DimMgt.GetDimValuePostingErr());
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    internal procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    local procedure InsertValueEntryRelation()
    var
        ValueEntryRelation: Record "Value Entry Relation";
    begin
        TempValueEntryRelation.Reset();
        if TempValueEntryRelation.Find('-') then begin
            repeat
                ValueEntryRelation := TempValueEntryRelation;
                ValueEntryRelation.Insert();
            until TempValueEntryRelation.Next() = 0;
            TempValueEntryRelation.DeleteAll();
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

    procedure GetPostedItemReceipt(): Code[20]
    begin
        exit(InvtRcptHeader."No.");
    end;

    local procedure PostWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; OriginalQuantity: Decimal; OriginalQuantityBase: Decimal; var TempHandlingSpecification: Record "Tracking Specification" temporary)
    var
        WhseJnlLine: Record "Warehouse Journal Line";
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        OnBeforePostWhseJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase, TempHandlingSpecification);
        ItemJnlLine.Quantity := OriginalQuantity;
        ItemJnlLine."Quantity (Base)" := OriginalQuantityBase;
        GetLocation(ItemJnlLine."Location Code");
        if Location."Bin Mandatory" then
            if WMSMgmt.CreateWhseJnlLine(ItemJnlLine, 0, WhseJnlLine, false) then begin
                WhseJnlLine."Source Type" := DATABASE::"Item Journal Line";
                ItemTrackingMgt.SplitWhseJnlLine(WhseJnlLine, TempWhseJnlLine2, TempHandlingSpecification, false);
                if TempWhseJnlLine2.FindSet() then
                    repeat
                        WMSMgmt.CheckWhseJnlLine(TempWhseJnlLine2, 1, 0, false);
                        WhseJnlPostLine.Run(TempWhseJnlLine2);
                    until TempWhseJnlLine2.Next() = 0;
            end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckInvtDocumentHeaderMandatoryFields(var InvtDocumentHeader: Record "Invt. Document Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetInvtDocumentLineFiltersFromDocument(var InvtDocumentLine: Record "Invt. Document Line"; InvtDocumentHeader: Record "Invt. Document Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItemJnlLine(ItemJournalLine: Record "Item Journal Line"; OriginalQuantity: Decimal; OriginalQuantityBase: Decimal; TrackingSpecification: Record "Tracking Specification"; InvtReceiptHeader: Record "Invt. Receipt Header"; InvtReceiptLine: Record "Invt. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var InvtDocumentHeader: Record "Invt. Document Header"; InvtDocumentHeader2: Record "Invt. Document Header"; var InvtDocumentLine: Record "Invt. Document Line"; InvtReceiptHeader: Record "Invt. Receipt Header"; InvtReceiptLine: Record "Invt. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillItemJournalLineQtyFromInvtShipmentLine(var ItemJournalLine: Record "Item Journal Line"; InvtReceiptLine: Record "Invt. Receipt Line"; InvtReceiptHeader: Record "Invt. Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var InvtDocumentHeader: Record "Invt. Document Header"; var SuppressCommit: Boolean; var HideProgressWindow: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostWhseJnlLine(ItemJournalLine: Record "Item Journal Line"; OriginalQuantity: Decimal; OriginalQuantityBase: Decimal; var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckInvtDocumentHeaderMandatoryFields(var InvtDocumentHeader: Record "Invt. Document Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLine(InvtReceiptHeader: Record "Invt. Receipt Header"; InvtReceiptLine: Record "Invt. Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterSetStatusReleased(var InvtDocumentHeader: Record "Invt. Document Header"; var InvtDocumentLine: Record "Invt. Document Line"; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnAfterItemJnlLineInit(var ItemJournalLine: Record "Item Journal Line"; InvtReceiptHeader: Record "Invt. Receipt Header"; InvtReceiptLine: Record "Invt. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnBeforeTransferInvtDocToItemJnlLine(var InvtDocumentLine: Record "Invt. Document Line"; var ItemJournalLine: Record "Item Journal Line"; InvtReceiptHeader: Record "Invt. Receipt Header"; InvtReceiptLine: Record "Invt. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterInvtRcptHeaderInit(var InvtReceiptHeader: Record "Invt. Receipt Header"; InvtDocumentHeader: Record "Invt. Document Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterInvtRcptHeaderInsert(var InvtReceiptHeader: Record "Invt. Receipt Header"; InvtDocumentHeader: Record "Invt. Document Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterInvtRcptLineInit(var InvtReceiptLine: Record "Invt. Receipt Line"; InvtDocumentLine: Record "Invt. Document Line"; var InvtShipmentHeader: Record "Invt. Receipt Header"; InvtDocumentHeader: Record "Invt. Document Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterCommitPostInvtRcptDoc(var InvtDocumentHeader: Record "Invt. Document Header"; var InvtDocumentLine: Record "Invt. Document Line"; InvtReceiptHeader: Record "Invt. Receipt Header"; InvtReceiptLine: Record "Invt. Receipt Line"; ItemJournalLine: Record "Item Journal Line"; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterInvtRcptLineInsert(var InvtReceiptLine: Record "Invt. Receipt Line"; InvtDocumentLine: Record "Invt. Document Line"; var InvtReceiptHeader: Record "Invt. Receipt Header"; InvtDocumentHeader: Record "Invt. Document Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeInvtDocLineFind(var InvtDocumentLine: Record "Invt. Document Line"; InvtDocumentHeader: Record "Invt. Document Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterInvtDocPost(InvtDocumentHeader: Record "Invt. Document Header"; InvtDocumentLine: Record "Invt. Document Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeCommitPostInvtRcptDoc(var InvtDocumentHeader: Record "Invt. Document Header"; var InvtDocumentLine: Record "Invt. Document Line"; InvtReceiptHeader: Record "Invt. Receipt Header"; InvtReceiptLine: Record "Invt. Receipt Line"; ItemJournalLine: Record "Item Journal Line"; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnBeforeItemJnlPostLineRunWithCheck(var ItemJnlLine: Record "Item Journal Line"; InvtRcptHeader2: Record "Invt. Receipt Header"; InvtRcptLine2: Record "Invt. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeInvtRcptHeaderInsert(var InvtRcptHeader: Record "Invt. Receipt Header"; InvtDocHeader: Record "Invt. Document Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeInvtRcptLineInsert(var InvtRcptLine: Record "Invt. Receipt Line"; InvtDocLine: Record "Invt. Document Line")
    begin
    end;
}

