codeunit 12469 "TransferOrder-Post Transfer"
{
    Permissions = TableData "Item Entry Relation" = i;
    TableNo = "Transfer Header";

    trigger OnRun()
    var
        Item: Record Item;
        SourceCodeSetup: Record "Source Code Setup";
        InvtSetup: Record "Inventory Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        UpdateAnalysisView: Codeunit "Update Analysis View";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        RecordLinkManagement: Codeunit "Record Link Management";
        Window: Dialog;
        LineCount: Integer;
    begin
        if Status = Status::Open then begin
            CODEUNIT.Run(CODEUNIT::"Release Transfer Document", Rec);
            Status := Status::Open;
            Modify;
            Commit;
            Status := Status::Released;
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
                  Text000,
                  "No.", FieldCaption("Transfer-from Code"), FieldCaption("Transfer-to Code"));
            TestField("In-Transit Code", '');
            TestField(Status, Status::Released);
            TestField("Posting Date");

            CheckDim;

            TransLine.Reset;
            TransLine.SetRange("Document No.", "No.");
            TransLine.SetRange("Derived From Line No.", 0);
            TransLine.SetFilter(Quantity, '<>%1', 0);
            if TransLine.FindSet then
                repeat
                    TransLine.TestField("Quantity Shipped", 0);
                    TransLine.TestField("Quantity Received", 0);
                until TransLine.Next = 0
            else
                Error(Text001);

            GetLocation("Transfer-from Code");
            if Location."Bin Mandatory" or Location."Require Shipment" then
                WhseShip := true;

            GetLocation("Transfer-to Code");
            if Location."Bin Mandatory" or Location."Require Receive" then
                WhseReceive := true;

            Window.Open(
              '#1#################################\\' +
              Text003);

            Window.Update(1, StrSubstNo(Text004, "No."));

            SourceCodeSetup.Get;
            SourceCode := SourceCodeSetup.Transfer;
            InvtSetup.Get;
            InvtSetup.TestField("Posted Direct Transfer Nos.");

            NoSeriesLine.LockTable;
            if NoSeriesLine.FindLast then;
            if InvtSetup."Automatic Cost Posting" then begin
                GLEntry.LockTable;
                if GLEntry.FindLast then;
            end;

            // Insert shipment header
            DirectTransHeader.LockTable;
            DirectTransHeader.Init;
            DirectTransHeader."Transfer-from Code" := "Transfer-from Code";
            DirectTransHeader."Transfer-from Name" := "Transfer-from Name";
            DirectTransHeader."Transfer-from Name 2" := "Transfer-from Name 2";
            DirectTransHeader."Transfer-from Address" := "Transfer-from Address";
            DirectTransHeader."Transfer-from Address 2" := "Transfer-from Address 2";
            DirectTransHeader."Transfer-from Post Code" := "Transfer-from Post Code";
            DirectTransHeader."Transfer-from City" := "Transfer-from City";
            DirectTransHeader."Transfer-from County" := "Transfer-from County";
            DirectTransHeader."Trsf.-from Country/Region Code" := "Trsf.-from Country/Region Code";
            DirectTransHeader."Transfer-from Contact" := "Transfer-from Contact";
            DirectTransHeader."Transfer-to Code" := "Transfer-to Code";
            DirectTransHeader."Transfer-to Name" := "Transfer-to Name";
            DirectTransHeader."Transfer-to Name 2" := "Transfer-to Name 2";
            DirectTransHeader."Transfer-to Address" := "Transfer-to Address";
            DirectTransHeader."Transfer-to Address 2" := "Transfer-to Address 2";
            DirectTransHeader."Transfer-to Post Code" := "Transfer-to Post Code";
            DirectTransHeader."Transfer-to City" := "Transfer-to City";
            DirectTransHeader."Transfer-to County" := "Transfer-to County";
            DirectTransHeader."Trsf.-to Country/Region Code" := "Trsf.-to Country/Region Code";
            DirectTransHeader."Transfer-to Contact" := "Transfer-to Contact";
            DirectTransHeader."Transfer Order Date" := "Posting Date";
            DirectTransHeader."Posting Date" := "Posting Date";
            DirectTransHeader."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
            DirectTransHeader."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
            DirectTransHeader."Dimension Set ID" := "Dimension Set ID";
            DirectTransHeader."Transfer Order No." := "No.";
            DirectTransHeader."External Document No." := "External Document No.";
            DirectTransHeader."No. Series" := InvtSetup."Posted Direct Transfer Nos.";
            DirectTransHeader."No." :=
              NoSeriesMgt.GetNextNo(
                InvtSetup."Posted Direct Transfer Nos.", "Posting Date", true);
            DirectTransHeader.Insert;

            DocSignMgt.MoveDocSignToPostedDocSign(
              DocSign, DATABASE::"Transfer Header", 0, "No.",
              DATABASE::"Direct Transfer Header", DirectTransHeader."No.");
            if InvtSetup."Copy Comments Order to Shpt." then begin
                CopyCommentLines(1, 2, "No.", DirectTransHeader."No.");
                RecordLinkManagement.CopyLinks(Rec, DirectTransHeader);
            end;

            // Insert shipment lines
            LineCount := 0;
            DirectTransLine.LockTable;
            TransLine.SetRange(Quantity);
            if TransLine.FindSet then begin
                repeat
                    LineCount := LineCount + 1;
                    Window.Update(2, LineCount);

                    if TransLine."Item No." <> '' then begin
                        Item.Get(TransLine."Item No.");
                        Item.TestField(Blocked, false);
                        if Item."Gross Weight Mandatory" then
                            TransLine.TestField("Gross Weight");
                        if Item."Unit Volume Mandatory" then
                            TransLine.TestField("Unit Volume");
                    end;

                    DirectTransLine.Init;
                    DirectTransLine."Document No." := DirectTransHeader."No.";
                    DirectTransLine."Line No." := TransLine."Line No.";
                    DirectTransLine."Item No." := TransLine."Item No.";
                    DirectTransLine.Description := TransLine.Description;
                    DirectTransLine.Quantity := TransLine."Qty. to Ship";
                    DirectTransLine."Unit of Measure" := TransLine."Unit of Measure";
                    DirectTransLine."Shortcut Dimension 1 Code" := TransLine."Shortcut Dimension 1 Code";
                    DirectTransLine."Shortcut Dimension 2 Code" := TransLine."Shortcut Dimension 2 Code";
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

                    DirectTransLine.Insert;
                until TransLine.Next = 0;
            end;

            InvtSetup.Get;
            if InvtSetup."Automatic Cost Adjustment" <>
               InvtSetup."Automatic Cost Adjustment"::Never
            then begin
                InvtAdjmt.SetProperties(true, InvtSetup."Automatic Cost Posting");
                InvtAdjmt.MakeMultiLevelAdjmt;
            end;

            LockTable;
            "Last Shipment No." := DirectTransHeader."No.";
            "Last Receipt No." := DirectTransHeader."No.";
            Modify;

            TransLine.SetRange(Quantity);
            DeleteOneTransferOrder(TransHeader, TransLine);

            Clear(InvtAdjmt);
            Window.Close;
        end;

        UpdateAnalysisView.UpdateAll(0, true);
        UpdateItemAnalysisView.UpdateAll(0, true);
        Rec := TransHeader;
    end;

    var
        Text000: Label 'Transfer order %1 cannot be posted because %2 and %3 are the same.';
        Text001: Label 'There is nothing to post.';
        Text003: Label 'Posting transfer lines     #2######';
        Text004: Label 'Transfer Order %1';
        Text005: Label 'The combination of dimensions used in transfer order %1 is blocked. %2';
        Text006: Label 'The combination of dimensions used in transfer order %1, line no. %2 is blocked. %3';
        Text007: Label 'The dimensions used in transfer order %1, line no. %2 are invalid. %3';
        DirectTransHeader: Record "Direct Transfer Header";
        DirectTransLine: Record "Direct Transfer Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        Location: Record Location;
        ItemJnlLine: Record "Item Journal Line";
        TempHandlingSpecification: Record "Tracking Specification" temporary;
        NoSeriesLine: Record "No. Series Line";
        GLEntry: Record "G/L Entry";
        DocSign: Record "Document Signature";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        DimMgt: Codeunit DimensionManagement;
        ReserveTransLine: Codeunit "Transfer Line-Reserve";
        InvtAdjmt: Codeunit "Inventory Adjustment";
        DocSignMgt: Codeunit "Doc. Signature Management";
        SourceCode: Code[10];
        HideValidationDialog: Boolean;
        WhseShip: Boolean;
        WhseReceive: Boolean;
        OriginalQuantity: Decimal;
        OriginalQuantityBase: Decimal;

    local procedure PostItemJnlLine(var TransLine3: Record "Transfer Line"; DirectTransHeader2: Record "Direct Transfer Header"; DirectTransLine2: Record "Direct Transfer Line")
    begin
        ItemJnlLine.Init;
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
          ItemJnlLine, ItemJnlLine."Quantity (Base)", 0, true);

        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
    end;

    local procedure CopyCommentLines(FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    var
        InvtCommentLine: Record "Inventory Comment Line";
        InvtCommentLine2: Record "Inventory Comment Line";
    begin
        InvtCommentLine.SetRange("Document Type", FromDocumentType);
        InvtCommentLine.SetRange("No.", FromNumber);
        if InvtCommentLine.FindSet then
            repeat
                InvtCommentLine2 := InvtCommentLine;
                InvtCommentLine2."Document Type" := InvtCommentLine2."Document Type"::"Posted Direct Transfer";
                InvtCommentLine2."No." := ToNumber;
                InvtCommentLine2.Insert;
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
                  TransHeader."No.", DimMgt.GetDimCombErr)
            else
                if not DimMgt.CheckDimIDComb(TransferLine."Dimension Set ID") then
                    Error(
                      Text006,
                      TransHeader."No.", TransferLine."Line No.", DimMgt.GetDimCombErr);
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
                Error(Text007, TransHeader."No.", TransferLine."Line No.", DimMgt.GetDimValuePostingErr);
    end;

    [Scope('OnPrem')]
    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    local procedure InsertShptEntryRelation(var TransMvmtLine: Record "Direct Transfer Line"): Integer
    var
        TempHandlingSpecification2: Record "Tracking Specification" temporary;
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        TempHandlingSpecification2.Reset;
        if ItemJnlPostLine.CollectTrackingSpecification(TempHandlingSpecification2) then begin
            TempHandlingSpecification2.SetRange("Buffer Status", 0);
            if TempHandlingSpecification2.Find('-') then begin
                repeat
                    ItemEntryRelation.Init;
                    ItemEntryRelation.InitFromTrackingSpec(TempHandlingSpecification2);
                    ItemEntryRelation.TransferFieldsDirectTransLine(DirectTransLine);
                    ItemEntryRelation.Insert;
                    TempHandlingSpecification := TempHandlingSpecification2;
                    TempHandlingSpecification.SetSource(
                      DATABASE::"Transfer Line", 0, DirectTransLine."Document No.", DirectTransLine."Line No.", '', DirectTransLine."Line No.");
                    TempHandlingSpecification."Buffer Status" := TempHandlingSpecification."Buffer Status"::MODIFY;
                    TempHandlingSpecification.Insert;
                until TempHandlingSpecification2.Next = 0;
                exit(0);
            end;
        end else
            exit(ItemJnlLine."Item Shpt. Entry No.");
    end;

    [Scope('OnPrem')]
    procedure TransferTracking(var FromTransLine: Record "Transfer Line"; var ToTransLine: Record "Transfer Line"; TransferQty: Decimal)
    var
        DummySpecification: Record "Tracking Specification";
    begin
        TempHandlingSpecification.Reset;
        TempHandlingSpecification.SetRange("Source Prod. Order Line", ToTransLine."Derived From Line No.");
        if TempHandlingSpecification.Find('-') then begin
            repeat
                ReserveTransLine.TransferTransferToTransfer(
                  FromTransLine, ToTransLine, -TempHandlingSpecification."Quantity (Base)", 1, TempHandlingSpecification);
                TransferQty += TempHandlingSpecification."Quantity (Base)";
            until TempHandlingSpecification.Next = 0;
            TempHandlingSpecification.DeleteAll;
        end;

        if TransferQty > 0 then
            ReserveTransLine.TransferTransferToTransfer(
              FromTransLine, ToTransLine, TransferQty, 1, DummySpecification);
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
                        until TempWhseJnlLine2.Next = 0;
                end;
        end;
    end;
}

