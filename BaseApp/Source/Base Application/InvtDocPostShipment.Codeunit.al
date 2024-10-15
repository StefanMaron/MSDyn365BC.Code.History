codeunit 5851 "Invt. Doc.-Post Shipment"
{
    Permissions = TableData "Item Entry Relation" = i,
                  TableData "Value Entry Relation" = ri,
                  TableData "Invt. Shipment Header" = imd,
                  TableData "Invt. Shipment Line" = imd;
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
        InvtAdjmt: Codeunit "Inventory Adjustment";
        Window: Dialog;
        LineCount: Integer;
    begin
        Rec.TestField("Document Type", "Document Type"::Shipment);

        InvtDocHeader := Rec;
        InvtDocHeader.SetHideValidationDialog(HideValidationDialog);

        with InvtDocHeader do begin
            InvtDocHeader.TestField("No.");
            InvtDocHeader.TestField("Posting Date");

            CheckDim();

            InvtDocLine.Reset();
            InvtDocLine.SetRange("Document Type", "Document Type");
            InvtDocLine.SetRange("Document No.", "No.");
            InvtDocLine.SetFilter(Quantity, '>0');
            if not InvtDocLine.Find('-') then
                Error(NothingToPostErr);

            GetLocation("Location Code");
            if Location."Require Pick" or Location."Require Shipment" then
                Error(WarehouseHandlingRequiredErr, "Location Code");

            Window.Open('#1#################################\\' + PostingLinesMsg);

            Window.Update(1, StrSubstNo(PostingDocumentTxt, "No."));

            SourceCodeSetup.Get();
            SourceCode := SourceCodeSetup."Invt. Shipment";
            InvtSetup.Get();
            InvtSetup.TestField("Posted Invt. Shipment Nos.");
            InventoryPostingSetup.SetRange("Location Code", "Location Code");
            if InventoryPostingSetup.IsEmpty() then
                error(InventoryPostingSetupMissingErr, "Location Code");

            if Status = Status::Open then begin
                CODEUNIT.Run(CODEUNIT::"Release Invt. Document", InvtDocHeader);
                Status := Status::Open;
                Modify();
                Commit();
                Status := Status::Released;
            end;

            TestField(Status, Status::Released);

            NoSeriesLine.LockTable();
            if NoSeriesLine.FindLast() then;
            if InvtSetup."Automatic Cost Posting" then begin
                GLEntry.LockTable();
                if GLEntry.FindLast() then;
            end;

            // Insert shipment header
            InvtShptHeader.LockTable();
            InvtShptHeader.Init();
            InvtShptHeader."Location Code" := "Location Code";
            InvtShptHeader."Posting Date" := "Posting Date";
            InvtShptHeader."Document Date" := "Document Date";
            InvtShptHeader."Salesperson Code" := "Salesperson/Purchaser Code";
            InvtShptHeader."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
            InvtShptHeader."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
            InvtShptHeader."Shipment No." := "No.";
            InvtShptHeader."External Document No." := "External Document No.";
            InvtShptHeader."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
            InvtShptHeader."No. Series" := InvtSetup."Posted Invt. Shipment Nos.";
            InvtShptHeader."No." :=
              NoSeriesMgt.GetNextNo(
                InvtSetup."Posted Invt. Shipment Nos.", "Posting Date", true);
            "Posting No." := InvtShptHeader."No.";
            InvtShptHeader."Posting Description" := "Posting Description";
            InvtShptHeader.Correction := Correction;
            InvtShptHeader."Dimension Set ID" := "Dimension Set ID";
            OnRunOnBeforeInvtShptHeaderInsert(InvtShptHeader, InvtDocHeader);
            InvtShptHeader.Insert();

            if InvtSetup."Copy Comments to Invt. Doc." then
                CopyCommentLines(
                    "Inventory Comment Document Type"::"Inventory Shipment",
                    "Inventory Comment Document Type"::"Posted Inventory Shipment",
                    "No.", InvtShptHeader."No.");

            // Insert shipment lines
            LineCount := 0;
            InvtShptLine.LockTable();
            InvtDocLine.SetRange(Quantity);
            if InvtDocLine.Find('-') then
                repeat
                    LineCount := LineCount + 1;
                    Window.Update(2, LineCount);

                    if InvtDocLine."Item No." <> '' then begin
                        Item.Get(InvtDocLine."Item No.");
                        Item.TestField(Blocked, false);
                    end;

                    InvtShptLine.Init();
                    InvtShptLine."Document No." := InvtShptHeader."No.";
                    InvtShptLine."Posting Date" := InvtShptHeader."Posting Date";
                    InvtShptLine."Document Date" := InvtShptHeader."Document Date";
                    InvtShptLine."Line No." := InvtDocLine."Line No.";
                    InvtShptLine."Item No." := InvtDocLine."Item No.";
                    InvtShptLine.Description := InvtDocLine.Description;
                    InvtShptLine.Quantity := InvtDocLine.Quantity;
                    InvtShptLine."Unit Amount" := InvtDocLine."Unit Amount";
                    InvtShptLine."Unit Cost" := InvtDocLine."Unit Cost";
                    InvtShptLine.Amount := InvtDocLine.Amount;
                    InvtShptLine."Indirect Cost %" := InvtDocLine."Indirect Cost %";
                    InvtShptLine."Unit of Measure Code" := InvtDocLine."Unit of Measure Code";
                    InvtShptLine."Shortcut Dimension 1 Code" := InvtDocLine."Shortcut Dimension 1 Code";
                    InvtShptLine."Shortcut Dimension 2 Code" := InvtDocLine."Shortcut Dimension 2 Code";
                    InvtShptLine."Gen. Bus. Posting Group" := InvtDocLine."Gen. Bus. Posting Group";
                    InvtShptLine."Gen. Prod. Posting Group" := InvtDocLine."Gen. Prod. Posting Group";
                    InvtShptLine."Inventory Posting Group" := InvtDocLine."Inventory Posting Group";
                    InvtShptLine."Quantity (Base)" := InvtDocLine."Quantity (Base)";
                    InvtShptLine."Qty. per Unit of Measure" := InvtDocLine."Qty. per Unit of Measure";
                    InvtShptLine."Unit of Measure Code" := InvtDocLine."Unit of Measure Code";
                    InvtShptLine."Gross Weight" := InvtDocLine."Gross Weight";
                    InvtShptLine."Net Weight" := InvtDocLine."Net Weight";
                    InvtShptLine."Unit Volume" := InvtDocLine."Unit Volume";
                    InvtShptLine."Variant Code" := InvtDocLine."Variant Code";
                    InvtShptLine."Units per Parcel" := InvtDocLine."Units per Parcel";
                    InvtShptLine."Location Code" := InvtDocLine."Location Code";
                    InvtShptLine."Bin Code" := InvtDocLine."Bin Code";
                    InvtShptLine."Item Category Code" := InvtDocLine."Item Category Code";
                    InvtShptLine."FA No." := InvtDocLine."FA No.";
                    InvtShptLine."Depreciation Book Code" := InvtDocLine."Depreciation Book Code";
                    InvtShptLine."Applies-to Entry" := InvtDocLine."Applies-to Entry";
                    InvtShptLine."Applies-from Entry" := InvtDocLine."Applies-from Entry";
                    InvtShptLine."Reason Code" := InvtDocLine."Reason Code";
                    InvtShptLine."Dimension Set ID" := InvtDocLine."Dimension Set ID";
                    OnRunOnBeforeInvtShptLineInsert(InvtShptLine, InvtDocLine);
                    InvtShptLine.Insert();

                    PostItemJnlLine(InvtShptHeader, InvtShptLine);
                    ItemJnlPostLine.CollectValueEntryRelation(TempValueEntryRelation, InvtShptLine.RowID1());
                until InvtDocLine.Next() = 0;

            InvtSetup.Get();
            if InvtSetup."Automatic Cost Adjustment" <>
               InvtSetup."Automatic Cost Adjustment"::Never
            then begin
                InvtAdjmt.SetProperties(true, InvtSetup."Automatic Cost Posting");
                InvtAdjmt.MakeMultiLevelAdjmt();
            end;

            LockTable();
            Delete(true);

            InsertValueEntryRelation();
            Commit();
            Window.Close();
        end;

        UpdateAnalysisView.UpdateAll(0, true);
        UpdateItemAnalysisView.UpdateAll(0, true);
        Rec := InvtDocHeader;
    end;

    var
        InvtShptHeader: Record "Invt. Shipment Header";
        InvtShptLine: Record "Invt. Shipment Line";
        InvtDocHeader: Record "Invt. Document Header";
        InvtDocLine: Record "Invt. Document Line";
        Location: Record Location;
        ItemJnlLine: Record "Item Journal Line";
        TempValueEntryRelation: Record "Value Entry Relation" temporary;
        NoSeriesLine: Record "No. Series Line";
        GLEntry: Record "G/L Entry";
        WMSMgmt: Codeunit "WMS Management";
        WhseJnlPostLine: Codeunit "Whse. Jnl.-Register Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        DimMgt: Codeunit DimensionManagement;
        ReserveInvtDocLine: Codeunit "Invt. Doc. Line-Reserve";
        SourceCode: Code[10];
        HideValidationDialog: Boolean;
        NothingToPostErr: Label 'There is nothing to post.';
        WarehouseHandlingRequiredErr: Label 'Warehouse handling is required for Location Code %1.', Comment = '%1 - location code';
        PostingLinesMsg: Label 'Posting item shipment lines     #2######', Comment = '#2 - line counter';
        PostingDocumentTxt: Label 'Item Shipment %1', Comment = '%1 - document number';
        DimCombBlockedErr: Label 'The combination of dimensions used in item shipment %1 is blocked. %2', Comment = '%1 - document number, %2 - error message';
        DimCombLineBlockedErr: Label 'The combination of dimensions used in item shipment %1, line no. %2 is blocked. %3', Comment = '%1 - document number, %2 = line number, %3 - error message';
        DimInvalidErr: Label 'The dimensions used in item shipment %1, line no. %2 are invalid. %3', Comment = '%1 - document number, %2 = line number, %3 - error message';
        InventoryPostingSetupMissingErr: Label 'Inventory posting setup missing for location code %1.', Comment = '%1 - location code';

    local procedure PostItemJnlLine(InvtShptHeader2: Record "Invt. Shipment Header"; InvtShptLine2: Record "Invt. Shipment Line")
    var
        TempHandlingSpecification: Record "Tracking Specification" temporary;
        OriginalQuantity: Decimal;
        OriginalQuantityBase: Decimal;
    begin
        ItemJnlLine.Init();
        ItemJnlLine."Posting Date" := InvtShptHeader2."Posting Date";
        ItemJnlLine."Document Date" := InvtShptHeader2."Document Date";
        ItemJnlLine."Document No." := InvtShptHeader2."No.";
        ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Inventory Shipment";
        ItemJnlLine."Document Line No." := InvtShptLine2."Line No.";
        ItemJnlLine."External Document No." := InvtShptHeader2."External Document No.";
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::"Negative Adjmt.";
        ItemJnlLine."Item No." := InvtShptLine2."Item No.";
        ItemJnlLine.Description := InvtShptLine2.Description;
        ItemJnlLine."Shortcut Dimension 1 Code" := InvtShptLine2."Shortcut Dimension 1 Code";
        ItemJnlLine."Shortcut Dimension 2 Code" := InvtShptLine2."Shortcut Dimension 2 Code";
        ItemJnlLine."Location Code" := InvtShptHeader2."Location Code";

        if InvtShptHeader2.Correction then begin
            ItemJnlLine.Quantity := -InvtShptLine2.Quantity;
            ItemJnlLine."Invoiced Quantity" := -InvtShptLine2.Quantity;
            ItemJnlLine."Quantity (Base)" := -InvtShptLine2."Quantity (Base)";
            ItemJnlLine."Invoiced Qty. (Base)" := -InvtShptLine2."Quantity (Base)";
            ItemJnlLine.Amount := -InvtShptLine2.Amount;
        end
        else begin
            ItemJnlLine.Quantity := InvtShptLine2.Quantity;
            ItemJnlLine."Invoiced Quantity" := InvtShptLine2.Quantity;
            ItemJnlLine."Quantity (Base)" := InvtShptLine2."Quantity (Base)";
            ItemJnlLine."Invoiced Qty. (Base)" := InvtShptLine2."Quantity (Base)";
            ItemJnlLine.Amount := InvtShptLine2.Amount;
        end;
        ItemJnlLine."Unit Amount" := InvtShptLine2."Unit Amount";
        ItemJnlLine."Unit Cost" := InvtShptLine2."Unit Cost";
        ItemJnlLine."Indirect Cost %" := InvtShptLine2."Indirect Cost %";
        ItemJnlLine."Source Code" := SourceCode;
        ItemJnlLine."Gen. Bus. Posting Group" := InvtShptLine2."Gen. Bus. Posting Group";
        ItemJnlLine."Gen. Prod. Posting Group" := InvtShptLine2."Gen. Prod. Posting Group";
        ItemJnlLine."Inventory Posting Group" := InvtShptLine2."Inventory Posting Group";
        ItemJnlLine."Unit of Measure Code" := InvtShptLine2."Unit of Measure Code";
        ItemJnlLine."Qty. per Unit of Measure" := InvtShptLine2."Qty. per Unit of Measure";
        ItemJnlLine."Variant Code" := InvtShptLine2."Variant Code";
        ItemJnlLine."Item Category Code" := InvtShptLine2."Item Category Code";
        ItemJnlLine."Applies-to Entry" := InvtShptLine2."Applies-to Entry";
        ItemJnlLine."Applies-from Entry" := InvtShptLine2."Applies-from Entry";

        ItemJnlLine."Bin Code" := InvtShptLine2."Bin Code";
        ItemJnlLine."Dimension Set ID" := InvtShptLine2."Dimension Set ID";

        ReserveInvtDocLine.TransferInvtDocToItemJnlLine(InvtDocLine, ItemJnlLine, ItemJnlLine.Quantity);

        OriginalQuantity := ItemJnlLine.Quantity;
        OriginalQuantityBase := ItemJnlLine."Quantity (Base)";
        OnPostItemJnlLineOnBeforeItemJnlPostLineRunWithCheck(ItemJnlLine, InvtShptHeader2, InvtShptLine2);
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);

        ItemJnlPostLine.CollectTrackingSpecification(TempHandlingSpecification);
        PostWhseJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase, TempHandlingSpecification);
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

    local procedure PostWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; OriginalQuantity: Decimal; OriginalQuantityBase: Decimal; var TempHandlingSpecification: Record "Tracking Specification" temporary)
    var
        WhseJnlLine: Record "Warehouse Journal Line";
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
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
    local procedure OnPostItemJnlLineOnBeforeItemJnlPostLineRunWithCheck(var ItemJnlLine: Record "Item Journal Line"; InvtShptHeader2: Record "Invt. Shipment Header"; InvtShptLine2: Record "Invt. Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeInvtShptHeaderInsert(var InvtShptHeader: Record "Invt. Shipment Header"; InvtDocHeader: Record "Invt. Document Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeInvtShptLineInsert(var InvtShptLine: Record "Invt. Shipment Line"; InvtDocLine: Record "Invt. Document Line")
    begin
    end;
}

