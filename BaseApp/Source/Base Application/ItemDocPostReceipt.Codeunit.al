codeunit 12460 "Item Doc.-Post Receipt"
{
    Permissions = TableData "Item Entry Relation" = i,
                  TableData "Value Entry Relation" = ri,
                  TableData "Item Receipt Header" = rimd;
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
        TestField("Document Type", "Document Type"::Receipt);

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
            if Location."Require Receive" or Location."Require Put-away" then
                Error(Text002, "Location Code");

            Window.Open(
              '#1#################################\\' +
              Text003);

            Window.Update(1, StrSubstNo(Text004, "No."));

            SourceCodeSetup.Get();
            SourceCode := SourceCodeSetup."Item Receipt";
            InvtSetup.Get();
            InvtSetup.TestField("Posted Item Receipt Nos.");
            InventoryPostingSetup.SetRange("Location Code", "Location Code");
            InventoryPostingSetup.FindFirst;

            NoSeriesLine.LockTable();
            if NoSeriesLine.FindLast then;
            if InvtSetup."Automatic Cost Posting" then begin
                GLEntry.LockTable();
                if GLEntry.FindLast then;
            end;

            // Insert receipt header
            ItemRcptHeader.LockTable();
            ItemRcptHeader.Init();
            ItemRcptHeader."Location Code" := "Location Code";
            ItemRcptHeader."Document Date" := "Document Date";
            ItemRcptHeader."Posting Date" := "Posting Date";
            ItemRcptHeader."Purchaser Code" := "Salesperson/Purchaser Code";
            ItemRcptHeader."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
            ItemRcptHeader."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
            ItemRcptHeader."Receipt No." := "No.";
            ItemRcptHeader."External Document No." := "External Document No.";
            ItemRcptHeader."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
            ItemRcptHeader."No. Series" := InvtSetup."Posted Item Receipt Nos.";
            ItemRcptHeader."No." :=
              NoSeriesMgt.GetNextNo(
                InvtSetup."Posted Item Receipt Nos.", "Posting Date", true);
            "Posting No." := ItemRcptHeader."No.";
            ItemRcptHeader."Posting Description" := "Posting Description";
            ItemRcptHeader.Correction := Correction;
            ItemRcptHeader."Dimension Set ID" := "Dimension Set ID";
            ItemRcptHeader.Insert();

            DocSignMgt.MoveDocSignToPostedDocSign(
              DocSign, DATABASE::"Item Document Header", "Document Type", "No.",
              DATABASE::"Item Receipt Header", ItemRcptHeader."No.");
            if InvtSetup."Copy Comments to Item Doc." then
                CopyCommentLines(4, 6, "No.", ItemRcptHeader."No.");

            // Insert receipt lines
            LineCount := 0;
            ItemRcptLine.LockTable();
            ItemDocLine.SetRange(Quantity);
            if ItemDocLine.Find('-') then begin
                repeat
                    LineCount := LineCount + 1;
                    Window.Update(2, LineCount);

                    if ItemDocLine."Item No." <> '' then begin
                        Item.Get(ItemDocLine."Item No.");
                        Item.TestField(Blocked, false);
                    end;

                    ItemRcptLine.Init();
                    ItemRcptLine."Document No." := ItemRcptHeader."No.";
                    ItemRcptLine."Posting Date" := ItemRcptHeader."Posting Date";
                    ItemRcptLine."Document Date" := ItemRcptHeader."Document Date";
                    ItemRcptLine."Line No." := ItemDocLine."Line No.";
                    ItemRcptLine."Item No." := ItemDocLine."Item No.";
                    ItemRcptLine.Description := ItemDocLine.Description;
                    ItemRcptLine.Quantity := ItemDocLine.Quantity;
                    ItemRcptLine."Unit Amount" := ItemDocLine."Unit Amount";
                    ItemRcptLine."Unit Cost" := ItemDocLine."Unit Cost";
                    ItemRcptLine.Amount := ItemDocLine.Amount;
                    ItemRcptLine."Indirect Cost %" := ItemDocLine."Indirect Cost %";
                    ItemRcptLine."Unit of Measure Code" := ItemDocLine."Unit of Measure Code";
                    ItemRcptLine."Shortcut Dimension 1 Code" := ItemDocLine."Shortcut Dimension 1 Code";
                    ItemRcptLine."Shortcut Dimension 2 Code" := ItemDocLine."Shortcut Dimension 2 Code";
                    ItemRcptLine."Gen. Bus. Posting Group" := ItemDocLine."Gen. Bus. Posting Group";
                    ItemRcptLine."Gen. Prod. Posting Group" := ItemDocLine."Gen. Prod. Posting Group";
                    ItemRcptLine."Inventory Posting Group" := ItemDocLine."Inventory Posting Group";
                    ItemRcptLine."Quantity (Base)" := ItemDocLine."Quantity (Base)";
                    ItemRcptLine."Qty. per Unit of Measure" := ItemDocLine."Qty. per Unit of Measure";
                    ItemRcptLine."Unit of Measure Code" := ItemDocLine."Unit of Measure Code";
                    ItemRcptLine."Gross Weight" := ItemDocLine."Gross Weight";
                    ItemRcptLine."Net Weight" := ItemDocLine."Net Weight";
                    ItemRcptLine."Unit Volume" := ItemDocLine."Unit Volume";
                    ItemRcptLine."Variant Code" := ItemDocLine."Variant Code";
                    ItemRcptLine."Units per Parcel" := ItemDocLine."Units per Parcel";
                    ItemRcptLine."Receipt No." := ItemDocLine."Document No.";
                    ItemRcptLine."Document Date" := ItemDocLine."Document Date";
                    ItemRcptLine."Location Code" := ItemDocLine."Location Code";
                    ItemRcptLine."Bin Code" := ItemDocLine."Bin Code";
                    ItemRcptLine."Item Category Code" := ItemDocLine."Item Category Code";
                    ItemRcptLine."Applies-to Entry" := ItemDocLine."Applies-to Entry";
                    ItemRcptLine."Applies-from Entry" := ItemDocLine."Applies-from Entry";
                    ItemRcptLine."Dimension Set ID" := ItemDocLine."Dimension Set ID";
                    ItemRcptLine.Insert();

                    PostItemJnlLine(ItemDocLine, ItemRcptHeader, ItemRcptLine);
                    ItemJnlPostLine.CollectValueEntryRelation(TempValueEntryRelation, ItemRcptLine.RowID1);
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
        Text003: Label 'Posting item receipt lines     #2######';
        Text004: Label 'Item Receipt %1';
        Text005: Label 'The combination of dimensions used in item receipt %1 is blocked. %2';
        Text006: Label 'The combination of dimensions used in item receipt %1, line no. %2 is blocked. %3';
        Text007: Label 'The dimensions used in item receipt %1, line no. %2 are invalid. %3';
        ItemRcptHeader: Record "Item Receipt Header";
        ItemRcptLine: Record "Item Receipt Line";
        ItemDocHeader: Record "Item Document Header";
        ItemDocLine: Record "Item Document Line";
        ItemJnlLine: Record "Item Journal Line";
        Location: Record Location;
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

    local procedure PostItemJnlLine(var ItemDocLine3: Record "Item Document Line"; ItemRcptHeader2: Record "Item Receipt Header"; ItemRcptLine2: Record "Item Receipt Line")
    var
        TempHandlingSpecification: Record "Tracking Specification" temporary;
        OriginalQuantity: Decimal;
        OriginalQuantityBase: Decimal;
    begin
        ItemJnlLine.Init();
        ItemJnlLine."Posting Date" := ItemRcptHeader2."Posting Date";
        ItemJnlLine."Document Date" := ItemRcptHeader2."Document Date";
        ItemJnlLine."Document No." := ItemRcptHeader2."No.";
        ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Item Receipt";
        ItemJnlLine."Document Line No." := ItemRcptLine2."Line No.";
        ItemJnlLine."External Document No." := ItemRcptHeader2."External Document No.";
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::"Positive Adjmt.";
        ItemJnlLine."Item No." := ItemRcptLine2."Item No.";
        ItemJnlLine.Description := ItemRcptLine2.Description;
        ItemJnlLine."Shortcut Dimension 1 Code" := ItemRcptLine2."Shortcut Dimension 1 Code";
        ItemJnlLine."Shortcut Dimension 2 Code" := ItemRcptLine2."Shortcut Dimension 2 Code";
        ItemJnlLine."Location Code" := ItemRcptHeader2."Location Code";

        if ItemRcptHeader2.Correction then begin
            ItemJnlLine."Red Storno" := true;

            ItemJnlLine.Quantity := -ItemRcptLine2.Quantity;
            ItemJnlLine."Invoiced Quantity" := -ItemRcptLine2.Quantity;
            ItemJnlLine."Quantity (Base)" := -ItemRcptLine2."Quantity (Base)";
            ItemJnlLine."Invoiced Qty. (Base)" := -ItemRcptLine2."Quantity (Base)";
            ItemJnlLine.Amount := -ItemRcptLine2.Amount;
        end
        else begin
            ItemJnlLine.Quantity := ItemRcptLine2.Quantity;
            ItemJnlLine."Invoiced Quantity" := ItemRcptLine2.Quantity;
            ItemJnlLine."Quantity (Base)" := ItemRcptLine2."Quantity (Base)";
            ItemJnlLine."Invoiced Qty. (Base)" := ItemRcptLine2."Quantity (Base)";
            ItemJnlLine.Amount := ItemRcptLine2.Amount;
        end;

        ItemJnlLine."Unit Amount" := ItemRcptLine2."Unit Amount";
        ItemJnlLine."Unit Cost" := ItemRcptLine2."Unit Cost";
        ItemJnlLine."Indirect Cost %" := ItemRcptLine2."Indirect Cost %";
        ItemJnlLine."Source Code" := SourceCode;
        ItemJnlLine."Gen. Bus. Posting Group" := ItemRcptLine2."Gen. Bus. Posting Group";
        ItemJnlLine."Gen. Prod. Posting Group" := ItemRcptLine2."Gen. Prod. Posting Group";
        ItemJnlLine."Inventory Posting Group" := ItemRcptLine2."Inventory Posting Group";
        ItemJnlLine."Unit of Measure Code" := ItemRcptLine2."Unit of Measure Code";
        ItemJnlLine."Qty. per Unit of Measure" := ItemRcptLine2."Qty. per Unit of Measure";
        ItemJnlLine."Variant Code" := ItemRcptLine2."Variant Code";
        ItemJnlLine."Bin Code" := ItemDocLine."Bin Code";
        ItemJnlLine."Item Category Code" := ItemRcptLine2."Item Category Code";
        ItemJnlLine."Applies-to Entry" := ItemRcptLine2."Applies-to Entry";
        ItemJnlLine."Applies-from Entry" := ItemRcptLine2."Applies-from Entry";

        ItemJnlLine."Bin Code" := ItemRcptLine2."Bin Code";
        ItemJnlLine."Dimension Set ID" := ItemRcptLine2."Dimension Set ID";

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

    [Scope('OnPrem')]
    procedure GetPostedItemReceipt(): Code[20]
    begin
        exit(ItemRcptHeader."No.");
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

