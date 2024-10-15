codeunit 12461 "Item Doc.-Post Shipment"
{
    Permissions = TableData "Item Entry Relation" = i,
                  TableData "Value Entry Relation" = ri,
                  TableData "Item Shipment Header" = rimd,
                  TableData "Item Shipment Line" = rimd;
    TableNo = "Item Document Header";

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
        TestField("Document Type", "Document Type"::Shipment);

        if Status = Status::Open then begin
            CODEUNIT.Run(CODEUNIT::"Release Item Document", Rec);
            Status := Status::Open;
            Modify;
            Commit();
            Status := Status::Released;
        end;
        ItemDocHeader := Rec;
        ItemDocHeader.SetHideValidationDialog(HideValidationDialog);

        with ItemDocHeader do begin
            TestField(Status, Status::Released);
            TestField("Posting Date");

            CheckDim;

            DocSignMgt.CheckDocSignatures(DATABASE::"Item Document Header", "Document Type", "No.");

            ItemDocLine.Reset();
            ItemDocLine.SetRange("Document Type", "Document Type");
            ItemDocLine.SetRange("Document No.", "No.");
            ItemDocLine.SetFilter(Quantity, '>0');
            if not ItemDocLine.Find('-') then
                Error(Text001);

            GetLocation("Location Code");
            if Location."Require Pick" or Location."Require Shipment" then
                Error(Text002, "Location Code");

            Window.Open(
              '#1#################################\\' +
              Text003);

            Window.Update(1, StrSubstNo(Text004, "No."));

            SourceCodeSetup.Get();
            SourceCode := SourceCodeSetup."Item Shipment";
            InvtSetup.Get();
            InvtSetup.TestField("Posted Item Shipment Nos.");
            InventoryPostingSetup.SetRange("Location Code", "Location Code");
            InventoryPostingSetup.FindFirst;

            NoSeriesLine.LockTable();
            if NoSeriesLine.FindLast then;
            if InvtSetup."Automatic Cost Posting" then begin
                GLEntry.LockTable();
                if GLEntry.FindLast then;
            end;

            // Insert shipment header
            ItemShptHeader.LockTable();
            ItemShptHeader.Init();
            ItemShptHeader."Location Code" := "Location Code";
            ItemShptHeader."Posting Date" := "Posting Date";
            ItemShptHeader."Document Date" := "Document Date";
            ItemShptHeader."Salesperson Code" := "Salesperson/Purchaser Code";
            ItemShptHeader."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
            ItemShptHeader."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
            ItemShptHeader."Shipment No." := "No.";
            ItemShptHeader."External Document No." := "External Document No.";
            ItemShptHeader."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
            ItemShptHeader."No. Series" := InvtSetup."Posted Item Shipment Nos.";
            ItemShptHeader."No." :=
              NoSeriesMgt.GetNextNo(
                InvtSetup."Posted Item Shipment Nos.", "Posting Date", true);
            "Posting No." := ItemShptHeader."No.";
            ItemShptHeader."Posting Description" := "Posting Description";
            ItemShptHeader.Correction := Correction;
            ItemShptHeader."Dimension Set ID" := "Dimension Set ID";
            ItemShptHeader.Insert();

            DocSignMgt.MoveDocSignToPostedDocSign(
              DocSign, DATABASE::"Item Document Header", "Document Type", "No.",
              DATABASE::"Item Shipment Header", ItemShptHeader."No.");
            if InvtSetup."Copy Comments to Item Doc." then
                CopyCommentLines(5, 7, "No.", ItemShptHeader."No.");

            // Insert shipment lines
            LineCount := 0;
            ItemShptLine.LockTable();
            ItemDocLine.SetRange(Quantity);
            if ItemDocLine.Find('-') then begin
                repeat
                    LineCount := LineCount + 1;
                    Window.Update(2, LineCount);

                    if ItemDocLine."Item No." <> '' then begin
                        Item.Get(ItemDocLine."Item No.");
                        Item.TestField(Blocked, false);
                    end;

                    ItemShptLine.Init();
                    ItemShptLine."Document No." := ItemShptHeader."No.";
                    ItemShptLine."Posting Date" := ItemShptHeader."Posting Date";
                    ItemShptLine."Document Date" := ItemShptHeader."Document Date";
                    ItemShptLine."Line No." := ItemDocLine."Line No.";
                    ItemShptLine."Item No." := ItemDocLine."Item No.";
                    ItemShptLine.Description := ItemDocLine.Description;
                    ItemShptLine.Quantity := ItemDocLine.Quantity;
                    ItemShptLine."Unit Amount" := ItemDocLine."Unit Amount";
                    ItemShptLine."Unit Cost" := ItemDocLine."Unit Cost";
                    ItemShptLine.Amount := ItemDocLine.Amount;
                    ItemShptLine."Indirect Cost %" := ItemDocLine."Indirect Cost %";
                    ItemShptLine."Unit of Measure Code" := ItemDocLine."Unit of Measure Code";
                    ItemShptLine."Shortcut Dimension 1 Code" := ItemDocLine."Shortcut Dimension 1 Code";
                    ItemShptLine."Shortcut Dimension 2 Code" := ItemDocLine."Shortcut Dimension 2 Code";
                    ItemShptLine."Gen. Bus. Posting Group" := ItemDocLine."Gen. Bus. Posting Group";
                    ItemShptLine."Gen. Prod. Posting Group" := ItemDocLine."Gen. Prod. Posting Group";
                    ItemShptLine."Inventory Posting Group" := ItemDocLine."Inventory Posting Group";
                    ItemShptLine."Quantity (Base)" := ItemDocLine."Quantity (Base)";
                    ItemShptLine."Qty. per Unit of Measure" := ItemDocLine."Qty. per Unit of Measure";
                    ItemShptLine."Unit of Measure Code" := ItemDocLine."Unit of Measure Code";
                    ItemShptLine."Gross Weight" := ItemDocLine."Gross Weight";
                    ItemShptLine."Net Weight" := ItemDocLine."Net Weight";
                    ItemShptLine."Unit Volume" := ItemDocLine."Unit Volume";
                    ItemShptLine."Variant Code" := ItemDocLine."Variant Code";
                    ItemShptLine."Units per Parcel" := ItemDocLine."Units per Parcel";
                    ItemShptLine."Location Code" := ItemDocLine."Location Code";
                    ItemShptLine."Bin Code" := ItemDocLine."Bin Code";
                    ItemShptLine."Item Category Code" := ItemDocLine."Item Category Code";
                    ItemShptLine."FA No." := ItemDocLine."FA No.";
                    ItemShptLine."Depreciation Book Code" := ItemDocLine."Depreciation Book Code";
                    ItemShptLine."Applies-to Entry" := ItemDocLine."Applies-to Entry";
                    ItemShptLine."Applies-from Entry" := ItemDocLine."Applies-from Entry";
                    ItemShptLine."Reason Code" := ItemDocLine."Reason Code";
                    ItemShptLine."Dimension Set ID" := ItemDocLine."Dimension Set ID";
                    ItemShptLine.Insert();

                    PostItemJnlLine(ItemDocLine, ItemShptHeader, ItemShptLine);
                    ItemJnlPostLine.CollectValueEntryRelation(TempValueEntryRelation, ItemShptLine.RowID1);
                until ItemDocLine.Next = 0;
            end;

            InvtSetup.Get();
            if InvtSetup."Automatic Cost Adjustment" <>
               InvtSetup."Automatic Cost Adjustment"::Never
            then begin
                InvtAdjmt.SetProperties(true, InvtSetup."Automatic Cost Posting");
                InvtAdjmt.MakeMultiLevelAdjmt;
            end;

            LockTable();
            Delete(true);

            InsertValueEntryRelation;
            Commit();
            Window.Close;
        end;
        UpdateAnalysisView.UpdateAll(0, true);
        UpdateItemAnalysisView.UpdateAll(0, true);
        Rec := ItemDocHeader;
    end;

    var
        Text001: Label 'There is nothing to post.';
        Text002: Label 'Warehouse handling is required for Location Code %1.';
        Text003: Label 'Posting item shipment lines     #2######';
        Text004: Label 'Item Shipment %1';
        Text005: Label 'The combination of dimensions used in item shipment %1 is blocked. %2';
        Text006: Label 'The combination of dimensions used in item shipment %1, line no. %2 is blocked. %3';
        Text007: Label 'The dimensions used in item shipment %1, line no. %2 are invalid. %3';
        ItemShptHeader: Record "Item Shipment Header";
        ItemShptLine: Record "Item Shipment Line";
        ItemDocHeader: Record "Item Document Header";
        ItemDocLine: Record "Item Document Line";
        Location: Record Location;
        ItemJnlLine: Record "Item Journal Line";
        TempValueEntryRelation: Record "Value Entry Relation" temporary;
        NoSeriesLine: Record "No. Series Line";
        GLEntry: Record "G/L Entry";
        DocSign: Record "Document Signature";
        WMSMgmt: Codeunit "WMS Management";
        WhseJnlPostLine: Codeunit "Whse. Jnl.-Register Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        DimMgt: Codeunit DimensionManagement;
        ReserveItemDocLine: Codeunit "Item Doc. Line-Reserve";
        DocSignMgt: Codeunit "Doc. Signature Management";
        SourceCode: Code[10];
        HideValidationDialog: Boolean;

    local procedure PostItemJnlLine(var ItemDocLine3: Record "Item Document Line"; ItemShptHeader2: Record "Item Shipment Header"; ItemShptLine2: Record "Item Shipment Line")
    var
        TempHandlingSpecification: Record "Tracking Specification" temporary;
        OriginalQuantity: Decimal;
        OriginalQuantityBase: Decimal;
    begin
        ItemJnlLine.Init();
        ItemJnlLine."Posting Date" := ItemShptHeader2."Posting Date";
        ItemJnlLine."Document Date" := ItemShptHeader2."Document Date";
        ItemJnlLine."Document No." := ItemShptHeader2."No.";
        ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Item Shipment";
        ItemJnlLine."Document Line No." := ItemShptLine2."Line No.";
        ItemJnlLine."External Document No." := ItemShptHeader2."External Document No.";
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::"Negative Adjmt.";
        ItemJnlLine."Item No." := ItemShptLine2."Item No.";
        ItemJnlLine.Description := ItemShptLine2.Description;
        ItemJnlLine."Shortcut Dimension 1 Code" := ItemShptLine2."Shortcut Dimension 1 Code";
        ItemJnlLine."Shortcut Dimension 2 Code" := ItemShptLine2."Shortcut Dimension 2 Code";
        ItemJnlLine."Location Code" := ItemShptHeader2."Location Code";

        if ItemShptHeader2.Correction then begin
            ItemJnlLine."Red Storno" := true;

            ItemJnlLine.Quantity := -ItemShptLine2.Quantity;
            ItemJnlLine."Invoiced Quantity" := -ItemShptLine2.Quantity;
            ItemJnlLine."Quantity (Base)" := -ItemShptLine2."Quantity (Base)";
            ItemJnlLine."Invoiced Qty. (Base)" := -ItemShptLine2."Quantity (Base)";
            ItemJnlLine.Amount := -ItemShptLine2.Amount;
        end
        else begin
            ItemJnlLine.Quantity := ItemShptLine2.Quantity;
            ItemJnlLine."Invoiced Quantity" := ItemShptLine2.Quantity;
            ItemJnlLine."Quantity (Base)" := ItemShptLine2."Quantity (Base)";
            ItemJnlLine."Invoiced Qty. (Base)" := ItemShptLine2."Quantity (Base)";
            ItemJnlLine.Amount := ItemShptLine2.Amount;
        end;
        ItemJnlLine."Unit Amount" := ItemShptLine2."Unit Amount";
        ItemJnlLine."Unit Cost" := ItemShptLine2."Unit Cost";
        ItemJnlLine."Indirect Cost %" := ItemShptLine2."Indirect Cost %";
        ItemJnlLine."Source Code" := SourceCode;
        ItemJnlLine."Gen. Bus. Posting Group" := ItemShptLine2."Gen. Bus. Posting Group";
        ItemJnlLine."Gen. Prod. Posting Group" := ItemShptLine2."Gen. Prod. Posting Group";
        ItemJnlLine."Inventory Posting Group" := ItemShptLine2."Inventory Posting Group";
        ItemJnlLine."Unit of Measure Code" := ItemShptLine2."Unit of Measure Code";
        ItemJnlLine."Qty. per Unit of Measure" := ItemShptLine2."Qty. per Unit of Measure";
        ItemJnlLine."Variant Code" := ItemShptLine2."Variant Code";
        ItemJnlLine."Item Category Code" := ItemShptLine2."Item Category Code";
        ItemJnlLine."FA No." := ItemShptLine2."FA No.";
        ItemJnlLine."Depreciation Book Code" := ItemShptLine2."Depreciation Book Code";
        ItemJnlLine."Applies-to Entry" := ItemShptLine2."Applies-to Entry";
        ItemJnlLine."Applies-from Entry" := ItemShptLine2."Applies-from Entry";

        ItemJnlLine."Bin Code" := ItemShptLine2."Bin Code";
        ItemJnlLine."Dimension Set ID" := ItemShptLine2."Dimension Set ID";

        ReserveItemDocLine.TransferItemDocToItemJnlLine(
          ItemDocLine, ItemJnlLine, ItemJnlLine.Quantity);

        OriginalQuantity := ItemJnlLine.Quantity;
        OriginalQuantityBase := ItemJnlLine."Quantity (Base)";

        ItemJnlPostLine.RunWithCheck(ItemJnlLine);

        ItemJnlPostLine.CollectTrackingSpecification(TempHandlingSpecification);
        PostWhseJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase, TempHandlingSpecification);
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
        ItemDocLine."Line No." := 0;
        CheckDimComb(ItemDocHeader, ItemDocLine);
        CheckDimValuePosting(ItemDocHeader, ItemDocLine);

        ItemDocLine.SetRange("Document Type", ItemDocHeader."Document Type");
        ItemDocLine.SetRange("Document No.", ItemDocHeader."No.");
        if ItemDocLine.FindFirst then begin
            CheckDimComb(ItemDocHeader, ItemDocLine);
            CheckDimValuePosting(ItemDocHeader, ItemDocLine);
        end;
    end;

    local procedure CheckDimComb(ItemDocHeader: Record "Item Document Header"; ItemDocLine: Record "Item Document Line")
    begin
        if ItemDocLine."Line No." = 0 then
            if not DimMgt.CheckDimIDComb(ItemDocHeader."Dimension Set ID") then
                Error(
                  Text005,
                  ItemDocHeader."No.", DimMgt.GetDimCombErr);
        if ItemDocLine."Line No." <> 0 then
            if not DimMgt.CheckDimIDComb(ItemDocLine."Dimension Set ID") then
                Error(
                  Text006,
                  ItemDocHeader."No.", ItemDocLine."Line No.", DimMgt.GetDimCombErr);
    end;

    local procedure CheckDimValuePosting(ItemDocHeader: Record "Item Document Header"; ItemDocLine: Record "Item Document Line")
    var
        TableIDArr: array[10] of Integer;
        NumberArr: array[10] of Code[20];
    begin
        TableIDArr[1] := DATABASE::Item;
        NumberArr[1] := ItemDocLine."Item No.";
        if ItemDocLine."Line No." = 0 then
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, ItemDocHeader."Dimension Set ID") then
                Error(
                  Text007,
                  ItemDocHeader."No.", ItemDocLine."Line No.", DimMgt.GetDimValuePostingErr);

        if ItemDocLine."Line No." <> 0 then
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, ItemDocLine."Dimension Set ID") then
                Error(
                  Text007,
                  ItemDocHeader."No.", ItemDocLine."Line No.", DimMgt.GetDimValuePostingErr);
    end;

    [Scope('OnPrem')]
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
            until TempValueEntryRelation.Next = 0;
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
        with ItemJnlLine do begin
            Quantity := OriginalQuantity;
            "Quantity (Base)" := OriginalQuantityBase;
            GetLocation("Location Code");
            if Location."Bin Mandatory" then
                if WMSMgmt.CreateWhseJnlLine(ItemJnlLine, 0, WhseJnlLine, false) then begin
                    WhseJnlLine."Source Type" := DATABASE::"Item Journal Line";
                    ItemTrackingMgt.SplitWhseJnlLine(WhseJnlLine, TempWhseJnlLine2, TempHandlingSpecification, false);
                    if TempWhseJnlLine2.FindSet then
                        repeat
                            WMSMgmt.CheckWhseJnlLine(TempWhseJnlLine2, 1, 0, false);
                            WhseJnlPostLine.Run(TempWhseJnlLine2);
                        until TempWhseJnlLine2.Next = 0;
                end;
        end;
    end;
}

