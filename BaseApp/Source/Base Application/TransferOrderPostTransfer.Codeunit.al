codeunit 5856 "TransferOrder-Post Transfer"
{
    Permissions = TableData "Item Entry Relation" = i;
    TableNo = "Transfer Header";

    trigger OnRun()
    var
        Item: Record Item;
        SourceCodeSetup: Record "Source Code Setup";
        InvtCommentLine: Record "Inventory Comment Line";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        RecordLinkManagement: Codeunit "Record Link Management";
        Window: Dialog;
        LineCount: Integer;
    begin
        if Rec.Status = Rec.Status::Open then begin
            CODEUNIT.Run(CODEUNIT::"Release Transfer Document", Rec);
            Rec.Status := Rec.Status::Open;
            Rec.Modify();
            Commit();
            Rec.Status := Rec.Status::Released;
        end;
        TransHeader := Rec;
        TransHeader.SetHideValidationDialog(HideValidationDialog);

        with TransHeader do begin
            TestField("Transfer-from Code");
            TestField("Transfer-to Code");
            TestField("Direct Transfer");
            if ("Transfer-from Code" <> '') and
               ("Transfer-from Code" = "Transfer-to Code")
            then
                Error(
                  SameLocationErr,
                  "No.", FieldCaption("Transfer-from Code"), FieldCaption("Transfer-to Code"));
            TestField("In-Transit Code", '');
            TestField(Status, Status::Released);
            TestField("Posting Date");

            CheckDim();

            TransLine.Reset();
            TransLine.SetRange("Document No.", "No.");
            TransLine.SetRange("Derived From Line No.", 0);
            TransLine.SetFilter(Quantity, '<>%1', 0);
            if TransLine.FindSet() then
                repeat
                    TransLine.TestField("Quantity Shipped", 0);
                    TransLine.TestField("Quantity Received", 0);
                until TransLine.Next() = 0
            else
                Error(NothingToPostErr);

            GetLocation("Transfer-from Code");
            if Location."Bin Mandatory" or Location."Require Shipment" then
                WhseShip := true;

            GetLocation("Transfer-to Code");
            if Location."Bin Mandatory" or Location."Require Receive" then
                WhseReceive := true;

            Window.Open('#1#################################\\' + PostingLinesMsg);

            Window.Update(1, StrSubstNo(PostingDocumentTxt, "No."));

            SourceCodeSetup.Get();
            SourceCode := SourceCodeSetup.Transfer;
            InvtSetup.Get();
            InvtSetup.TestField("Posted Direct Trans. Nos.");

            NoSeriesLine.LockTable();
            if NoSeriesLine.FindLast() then;
            if InvtSetup."Automatic Cost Posting" then begin
                GLEntry.LockTable();
                if GLEntry.FindLast() then;
            end;

            InsertDirectTransHeader(TransHeader, DirectTransHeader);
            if InvtSetup."Copy Comments Order to Shpt." then begin
                InvtCommentLine.CopyCommentLines(
                    "Inventory Comment Document Type"::"Transfer Order", "No.",
                    "Inventory Comment Document Type"::"Posted Direct Transfer", DirectTransHeader."No.");
                RecordLinkManagement.CopyLinks(Rec, DirectTransHeader);
            end;

            // Insert shipment lines
            LineCount := 0;
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
            "Last Shipment No." := DirectTransHeader."No.";
            "Last Receipt No." := DirectTransHeader."No.";
            Modify();

            TransLine.SetRange(Quantity);
            DeleteOneTransferOrder(TransHeader, TransLine);
            Window.Close();
        end;

        UpdateAnalysisView.UpdateAll(0, true);
        UpdateItemAnalysisView.UpdateAll(0, true);
        Rec := TransHeader;
    end;

    var
        DirectTransHeader: Record "Direct Trans. Header";
        DirectTransLine: Record "Direct Trans. Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        Location: Record Location;
        InvtSetup: Record "Inventory Setup";
        ItemJnlLine: Record "Item Journal Line";
        TempHandlingSpecification: Record "Tracking Specification" temporary;
        NoSeriesLine: Record "No. Series Line";
        GLEntry: Record "G/L Entry";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        DimMgt: Codeunit DimensionManagement;
        ReserveTransLine: Codeunit "Transfer Line-Reserve";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        SourceCode: Code[10];
        HideValidationDialog: Boolean;
        WhseShip: Boolean;
        WhseReceive: Boolean;
        OriginalQuantity: Decimal;
        OriginalQuantityBase: Decimal;
        SameLocationErr: Label 'Transfer order %1 cannot be posted because %2 and %3 are the same.', Comment = '%1 - order number, %2 - location from, %3 - location to';
        NothingToPostErr: Label 'There is nothing to post.';
        PostingLinesMsg: Label 'Posting transfer lines #2######', Comment = '#2 - line counter';
        PostingDocumentTxt: Label 'Transfer Order %1', Comment = '%1 - document number';
        DimCombBlockedErr: Label 'The combination of dimensions used in transfer order %1 is blocked. %2', Comment = '%1 - document number, %2 - error message';
        DimCombLineBlockedErr: Label 'The combination of dimensions used in transfer order %1, line no. %2 is blocked. %3', Comment = '%1 - document number, %2 = line number, %3 - error message';
        DimInvalidErr: Label 'The dimensions used in transfer order %1, line no. %2 are invalid. %3', Comment = '%1 - document number, %2 = line number, %3 - error message';

    local procedure PostItemJnlLine(var TransLine3: Record "Transfer Line"; DirectTransHeader2: Record "Direct Trans. Header"; DirectTransLine2: Record "Direct Trans. Line")
    begin
        ItemJnlLine.Init();
        ItemJnlLine."Posting Date" := DirectTransHeader2."Posting Date";
        ItemJnlLine."Document Date" := DirectTransHeader2."Posting Date";
        ItemJnlLine."Document No." := DirectTransHeader2."No.";
        ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Direct Transfer";
        ItemJnlLine."Document Line No." := DirectTransLine2."Line No.";
        ItemJnlLine."Order Type" := ItemJnlLine."Order Type"::Transfer;
        ItemJnlLine."Order No." := DirectTransHeader2."Transfer Order No.";
        ItemJnlLine."External Document No." := DirectTransHeader2."External Document No.";
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Transfer;
        ItemJnlLine."Item No." := DirectTransLine2."Item No.";
        ItemJnlLine.Description := DirectTransLine2.Description;
        ItemJnlLine."Shortcut Dimension 1 Code" := DirectTransLine2."Shortcut Dimension 1 Code";
        ItemJnlLine."New Shortcut Dimension 1 Code" := DirectTransLine2."Shortcut Dimension 1 Code";
        ItemJnlLine."Shortcut Dimension 2 Code" := DirectTransLine2."Shortcut Dimension 2 Code";
        ItemJnlLine."New Shortcut Dimension 2 Code" := DirectTransLine2."Shortcut Dimension 2 Code";
        ItemJnlLine."Dimension Set ID" := DirectTransLine2."Dimension Set ID";
        ItemJnlLine."New Dimension Set ID" := DirectTransLine2."Dimension Set ID";
        ItemJnlLine."Location Code" := DirectTransHeader2."Transfer-from Code";
        ItemJnlLine."New Location Code" := DirectTransHeader2."Transfer-to Code";
        ItemJnlLine.Quantity := DirectTransLine2.Quantity;
        ItemJnlLine."Invoiced Quantity" := DirectTransLine2.Quantity;
        ItemJnlLine."Quantity (Base)" := DirectTransLine2."Quantity (Base)";
        ItemJnlLine."Invoiced Qty. (Base)" := DirectTransLine2."Quantity (Base)";
        ItemJnlLine."Source Code" := SourceCode;
        ItemJnlLine."Gen. Prod. Posting Group" := DirectTransLine2."Gen. Prod. Posting Group";
        ItemJnlLine."Inventory Posting Group" := DirectTransLine2."Inventory Posting Group";
        ItemJnlLine."Unit of Measure Code" := DirectTransLine2."Unit of Measure Code";
        ItemJnlLine."Qty. per Unit of Measure" := DirectTransLine2."Qty. per Unit of Measure";
        ItemJnlLine."Variant Code" := DirectTransLine2."Variant Code";
        ItemJnlLine."Bin Code" := TransLine3."Transfer-from Bin Code";
        ItemJnlLine."New Bin Code" := TransLine3."Transfer-To Bin Code";
        ItemJnlLine."Country/Region Code" := DirectTransHeader2."Trsf.-from Country/Region Code";
        ItemJnlLine."Item Category Code" := TransLine3."Item Category Code";

        ReserveTransLine.TransferTransferToItemJnlLine(TransLine3,
          ItemJnlLine, ItemJnlLine."Quantity (Base)", "Transfer Direction"::Outbound, true);

        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
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
        DirectTransHeader."No. Series" := InvtSetup."Posted Direct Trans. Nos.";
        DirectTransHeader."No." :=
            NoSeriesMgt.GetNextNo(InvtSetup."Posted Direct Trans. Nos.", TransferHeader."Posting Date", true);
        DirectTransHeader.Insert();
    end;

    local procedure InsertDirectTransLine(DirectTransHeader: Record "Direct Trans. Header"; TransLine: Record "Transfer Line")
    begin
        DirectTransLine.Init();
        DirectTransLine."Document No." := DirectTransHeader."No.";
        DirectTransLine."Line No." := TransLine."Line No.";
        DirectTransLine."Item No." := TransLine."Item No.";
        DirectTransLine.Description := TransLine.Description;
        DirectTransLine.Quantity := TransLine."Qty. to Ship";
        DirectTransLine."Unit of Measure" := TransLine."Unit of Measure";
        DirectTransLine."Shortcut Dimension 1 Code" := TransLine."Shortcut Dimension 1 Code";
        DirectTransLine."Shortcut Dimension 2 Code" := TransLine."Shortcut Dimension 2 Code";
        DirectTransLine."Dimension Set ID" := TransLine."Dimension Set ID";
        DirectTransLine."Gen. Prod. Posting Group" := TransLine."Gen. Prod. Posting Group";
        DirectTransLine."Inventory Posting Group" := TransLine."Inventory Posting Group";
        DirectTransLine.Quantity := TransLine.Quantity;
        DirectTransLine."Quantity (Base)" := TransLine."Quantity (Base)";
        DirectTransLine."Qty. per Unit of Measure" := TransLine."Qty. per Unit of Measure";
        DirectTransLine."Unit of Measure Code" := TransLine."Unit of Measure Code";
        DirectTransLine."Gross Weight" := TransLine."Gross Weight";
        DirectTransLine."Net Weight" := TransLine."Net Weight";
        DirectTransLine."Unit Volume" := TransLine."Unit Volume";
        DirectTransLine."Variant Code" := TransLine."Variant Code";
        DirectTransLine."Units per Parcel" := TransLine."Units per Parcel";
        DirectTransLine."Description 2" := TransLine."Description 2";
        DirectTransLine."Transfer Order No." := TransLine."Document No.";
        DirectTransLine."Transfer-from Code" := TransLine."Transfer-from Code";
        DirectTransLine."Transfer-to Code" := TransLine."Transfer-to Code";
        DirectTransLine."Transfer-from Bin Code" := TransLine."Transfer-from Bin Code";
        DirectTransLine."Item Category Code" := TransLine."Item Category Code";
        if TransLine.Quantity > 0 then begin
            OriginalQuantity := TransLine.Quantity;
            OriginalQuantityBase := TransLine."Quantity (Base)";
            PostItemJnlLine(TransLine, DirectTransHeader, DirectTransLine);
            DirectTransLine."Item Shpt. Entry No." := InsertShptEntryRelation(DirectTransLine);
            if WhseShip then
                PostWhseJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase, TempHandlingSpecification, 0);
            if WhseReceive then
                PostWhseJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase, TempHandlingSpecification, 1);
        end;
        DirectTransLine.Insert();
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

    local procedure InsertShptEntryRelation(var DirectTransLine: Record "Direct Trans. Line"): Integer
    var
        TempHandlingSpecification2: Record "Tracking Specification" temporary;
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        TempHandlingSpecification2.Reset();
        if ItemJnlPostLine.CollectTrackingSpecification(TempHandlingSpecification2) then begin
            TempHandlingSpecification2.SetRange("Buffer Status", 0);
            if TempHandlingSpecification2.Find('-') then begin
                repeat
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
                exit(0);
            end;
        end else
            exit(ItemJnlLine."Item Shpt. Entry No.");
    end;

    procedure TransferTracking(var FromTransLine: Record "Transfer Line"; var ToTransLine: Record "Transfer Line"; TransferQty: Decimal)
    var
        DummySpecification: Record "Tracking Specification";
    begin
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

    local procedure PostWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; OriginalQuantity: Decimal; OriginalQuantityBase: Decimal; var TempHandlingSpecification: Record "Tracking Specification" temporary; Direction: Integer)
    var
        WhseJnlLine: Record "Warehouse Journal Line";
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WMSMgmt: Codeunit "WMS Management";
        WhseJnlPostLine: Codeunit "Whse. Jnl.-Register Line";
    begin
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
        if InvtSetup.AutomaticCostAdjmtRequired() then
            InvtAdjmtHandler.MakeInventoryAdjustment(true, InvtSetup."Automatic Cost Posting");
    end;
}

