codeunit 5884 "Phys. Invt. Order-Post"
{
    Permissions = TableData "Item Entry Relation" = ri,
                  TableData "Pstd. Phys. Invt. Order Hdr" = rimd,
                  TableData "Pstd. Phys. Invt. Order Line" = rimd,
                  TableData "Pstd. Phys. Invt. Record Hdr" = rimd,
                  TableData "Pstd. Phys. Invt. Record Line" = rimd,
                  TableData "Pstd. Phys. Invt. Tracking" = rimd,
                  TableData "Pstd. Exp. Phys. Invt. Track" = rimd;
    TableNo = "Phys. Invt. Order Header";

    trigger OnRun()
    begin
        PhysInvtOrderHeader.Copy(Rec);
        Code;
        Rec := PhysInvtOrderHeader;

        OnAfterOnRun(Rec,PstdPhysInvtOrderHdr);
    end;

    var
        CheckingLinesMsg: Label 'Checking lines        #2######\', Comment = '%2 = counter';
        PostingLinesMsg: Label 'Posting lines         #3######', Comment = '%3 = counter';
        HeaderDimCombBlockedErr: Label 'The combination of dimensions used in phys. inventory order %1 is blocked. %2.', Comment = '%1 = Order No. %2 = error message';
        LineDimCombBlockedErr: Label 'The combination of dimensions used in  phys. inventory order %1, line no. %2 is blocked. %3.', Comment = '%1 = Order No. %2 = line no. %3 = error message';
        InvalidDimErr: Label 'The dimensions used in phys. inventory order %1, line no. %2 are invalid. %3.', Comment = '%1 = Order No. %2 = line no. %3 = error message';
        DifferenceErr: Label 'There is a difference between the values of the fields %1, %2 and %3. \Identified values in the line: %4 %5 %6 %7.', Comment = '%1,%2,%3 - quantities, %4 = text';
        NothingToPostErr: Label 'There is nothing to post.';
        CopyFromToMsg: Label '%1 %2 -> %3 %4', Comment = '%1,%2 = table captions, %2,%4 = Order No.';
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtOrderLine2: Record "Phys. Invt. Order Line";
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
        ExpPhysInvtTracking: Record "Exp. Phys. Invt. Tracking";
        PstdExpPhysInvtTrack: Record "Pstd. Exp. Phys. Invt. Track";
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        PhysInvtCommentLine: Record "Phys. Invt. Comment Line";
        PostedPhysInvtCommentLine: Record "Phys. Invt. Comment Line";
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        Location: Record Location;
        TempWhseTrackingSpecification: Record "Tracking Specification" temporary;
        DimManagement: Codeunit DimensionManagement;
        PhysInvtTrackingMgt: Codeunit "Phys. Invt. Tracking Mgt.";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        Window: Dialog;
        ErrorText: Text[250];
        SourceCode: Code[10];
        LineCount: Integer;
        ModifyHeader: Boolean;
        LinesToPost: Boolean;
        WhsePosting: Boolean;
        OriginalQuantityBase: Decimal;

    procedure "Code"()
    var
        SourceCodeSetup: Record "Source Code Setup";
        InventorySetup: Record "Inventory Setup";
        PhysInvtCountMgt: Codeunit "Phys. Invt. Count.-Management";
    begin
        with PhysInvtOrderHeader do begin
            TestField(Status, Status::Finished);
            TestField("Posting Date");

            Window.Open(
              '#1################################\\' +
              CheckingLinesMsg + PostingLinesMsg);
            Window.Update(1, StrSubstNo('%1 %2', TableCaption, "No."));

            LockTable();
            PhysInvtOrderLine.LockTable();

            ModifyHeader := false;
            if "Posting No." = '' then begin
                if "No. Series" <> '' then
                    TestField("Posting No. Series");
                if "No. Series" <> "Posting No. Series" then begin
                    "Posting No." := NoSeriesMgt.GetNextNo("Posting No. Series", "Posting Date", true);
                    ModifyHeader := true;
                end;
            end;

            if ModifyHeader then begin
                Modify;
                Commit();
            end;

            CheckDim;

            // Check phys. inventory order lines
            LinesToPost := false;
            LineCount := 0;
            PhysInvtOrderLine.Reset();
            PhysInvtOrderLine.SetRange("Document No.", "No.");
            if PhysInvtOrderLine.Find('-') then
                repeat
                    LineCount := LineCount + 1;
                    Window.Update(2, LineCount);
                    if not PhysInvtOrderLine.EmptyLine then begin
                        CheckOrderLine(PhysInvtOrderHeader, PhysInvtOrderLine, Item);

                        PhysInvtOrderLine.TestField("Entry Type");
                        if ((PhysInvtOrderLine."Entry Type" = PhysInvtOrderLine."Entry Type"::"Positive Adjmt.") and
                            (PhysInvtOrderLine."Quantity (Base)" <>
                             PhysInvtOrderLine."Pos. Qty. (Base)" - PhysInvtOrderLine."Neg. Qty. (Base)")) or
                           ((PhysInvtOrderLine."Entry Type" = PhysInvtOrderLine."Entry Type"::"Negative Adjmt.") and
                            (-PhysInvtOrderLine."Quantity (Base)" <>
                             PhysInvtOrderLine."Pos. Qty. (Base)" - PhysInvtOrderLine."Neg. Qty. (Base)"))
                        then
                            Error(
                              DifferenceErr,
                              PhysInvtOrderLine.FieldCaption("Pos. Qty. (Base)"),
                              PhysInvtOrderLine.FieldCaption("Neg. Qty. (Base)"),
                              PhysInvtOrderLine.FieldCaption("Quantity (Base)"),
                              PhysInvtOrderLine."Item No.",
                              PhysInvtOrderLine."Variant Code",
                              PhysInvtOrderLine."Location Code",
                              PhysInvtOrderLine."Bin Code");

                        if not LinesToPost then
                            LinesToPost := true;
                        if (PhysInvtOrderLine."Phys Invt Counting Period Type" <> PhysInvtOrderLine."Phys Invt Counting Period Type"::" ") and
                           (PhysInvtOrderLine."Phys Invt Counting Period Code" <> '')
                        then begin
                            PhysInvtCountMgt.InitTempItemSKUList;
                            PhysInvtCountMgt.AddToTempItemSKUList(PhysInvtOrderLine."Item No.", PhysInvtOrderLine."Location Code",
                              PhysInvtOrderLine."Variant Code", PhysInvtOrderLine."Phys Invt Counting Period Type");
                            PhysInvtCountMgt.UpdateItemSKUListPhysInvtCount;
                        end;
                    end;
                until PhysInvtOrderLine.Next = 0;
            if not LinesToPost then
                Error(NothingToPostErr);

            SourceCodeSetup.Get();
            SourceCode := SourceCodeSetup."Phys. Invt. Orders";

            InventorySetup.Get();

            // Insert posted order header
            InsertPostedHeader(PhysInvtOrderHeader);

            // Insert posted order lines
            LineCount := 0;
            PhysInvtOrderLine.Reset();
            PhysInvtOrderLine.SetRange("Document No.", "No.");
            PhysInvtOrderLine.SetRange("Entry Type", PhysInvtOrderLine."Entry Type"::"Negative Adjmt.");
            if PhysInvtOrderLine.FindSet then
                repeat
                    PostPhysInventoryOrderLine;
                until PhysInvtOrderLine.Next = 0;
            PhysInvtOrderLine.SetFilter("Entry Type", '<>%1', PhysInvtOrderLine."Entry Type"::"Negative Adjmt.");
            if PhysInvtOrderLine.FindSet then
                repeat
                    PostPhysInventoryOrderLine;
                until PhysInvtOrderLine.Next = 0;

            // Insert posted expected phys. invt. tracking Lines
            ExpPhysInvtTracking.Reset();
            ExpPhysInvtTracking.SetRange("Order No", "No.");
            if ExpPhysInvtTracking.Find('-') then
                repeat
                    PstdExpPhysInvtTrack.Init();
                    PstdExpPhysInvtTrack.TransferFields(ExpPhysInvtTracking);
                    PstdExpPhysInvtTrack."Order No" := PstdPhysInvtOrderHdr."No.";
                    PstdExpPhysInvtTrack.Insert();
                until ExpPhysInvtTracking.Next = 0;

            // Insert posted recording header and lines
            InsertPostedRecordings("No.", PstdPhysInvtOrderHdr."No.");

            // Insert posted comment Lines
            PhysInvtCommentLine.Reset();
            PhysInvtCommentLine.SetRange("Document Type", PhysInvtCommentLine."Document Type"::Order);
            PhysInvtCommentLine.SetRange("Order No.", "No.");
            PhysInvtCommentLine.SetRange("Recording No.", 0);
            if PhysInvtCommentLine.Find('-') then
                repeat
                    InsertPostedCommentLine(
                      PhysInvtCommentLine, PhysInvtCommentLine."Document Type"::"Posted Order", PstdPhysInvtOrderHdr."No.");
                until PhysInvtCommentLine.Next = 0;
            PhysInvtCommentLine.DeleteAll();

            PhysInvtCommentLine.Reset();
            PhysInvtCommentLine.SetRange("Document Type", PhysInvtCommentLine."Document Type"::Recording);
            PhysInvtCommentLine.SetRange("Order No.", "No.");
            if PhysInvtCommentLine.Find('-') then
                repeat
                    InsertPostedCommentLine(
                      PhysInvtCommentLine, PhysInvtCommentLine."Document Type"::"Posted Recording", PstdPhysInvtOrderHdr."No.");
                until PhysInvtCommentLine.Next = 0;
            PhysInvtCommentLine.DeleteAll();

            "Last Posting No." := "Posting No.";

            FinalizePost("No.");
        end;
    end;

    local procedure CheckOrderLine(PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var Item: Record Item)
    var
        IsHandled: Boolean;
    begin
        with PhysInvtOrderLine do begin
            CheckLine;
            Item.Get("Item No.");
            Item.TestField(Blocked, false);

            IsHandled := false;
            OnCheckOrderLineOnBeforeGetSamePhysInvtOrderLine(PhysInvtOrderHeader, PhysInvtOrderLine, PhysInvtOrderLine2, ErrorText, IsHandled);
            if PhysInvtOrderHeader.GetSamePhysInvtOrderLine(
                 "Item No.", "Variant Code", "Location Code", "Bin Code", ErrorText, PhysInvtOrderLine2) > 1
            then
                Error(ErrorText);
        end;
    end;

    local procedure CheckDim()
    begin
        PhysInvtOrderLine."Line No." := 0;
        CheckDimValuePosting(PhysInvtOrderLine);
        CheckDimComb(PhysInvtOrderLine);

        PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader."No.");
        if PhysInvtOrderLine.FindSet then
            repeat
                CheckDimComb(PhysInvtOrderLine);
                CheckDimValuePosting(PhysInvtOrderLine);
            until PhysInvtOrderLine.Next = 0;
    end;

    local procedure CheckDimComb(PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
        if PhysInvtOrderLine."Line No." = 0 then
            if not DimManagement.CheckDimIDComb(PhysInvtOrderHeader."Dimension Set ID") then
                Error(
                  HeaderDimCombBlockedErr,
                  PhysInvtOrderHeader."No.", DimManagement.GetDimCombErr);

        if PhysInvtOrderLine."Line No." <> 0 then
            if not DimManagement.CheckDimIDComb(PhysInvtOrderLine."Dimension Set ID") then
                Error(
                  LineDimCombBlockedErr,
                  PhysInvtOrderHeader."No.", PhysInvtOrderLine."Line No.", DimManagement.GetDimCombErr);
    end;

    local procedure CheckDimValuePosting(PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    var
        TableIDArr: array[10] of Integer;
        NumberArr: array[10] of Code[20];
    begin
        TableIDArr[1] := DATABASE::Item;
        NumberArr[1] := PhysInvtOrderLine."Item No.";
        if not DimManagement.CheckDimValuePosting(TableIDArr, NumberArr, PhysInvtOrderLine."Dimension Set ID") then
            Error(
              InvalidDimErr,
              PhysInvtOrderHeader."No.", PhysInvtOrderLine."Line No.", DimManagement.GetDimValuePostingErr);
    end;

    local procedure PostItemJnlLine(Positive: Boolean; Qty: Decimal)
    begin
        with ItemJnlLine do begin
            Init;
            "Posting Date" := PstdPhysInvtOrderHdr."Posting Date";
            "Document Date" := PstdPhysInvtOrderHdr."Posting Date";
            "Document No." := PstdPhysInvtOrderHdr."No.";
            if Positive then
                "Entry Type" := "Entry Type"::"Positive Adjmt."
            else
                "Entry Type" := "Entry Type"::"Negative Adjmt.";
            "Item No." := PhysInvtOrderLine."Item No.";
            "Variant Code" := PhysInvtOrderLine."Variant Code";
            Description := PhysInvtOrderLine.Description;
            "Item Category Code" := PhysInvtOrderLine."Item Category Code";
            "Location Code" := PhysInvtOrderLine."Location Code";
            "Bin Code" := PhysInvtOrderLine."Bin Code";
            "Shortcut Dimension 1 Code" := PhysInvtOrderLine."Shortcut Dimension 1 Code";
            "Shortcut Dimension 2 Code" := PhysInvtOrderLine."Shortcut Dimension 2 Code";
            "Dimension Set ID" := PhysInvtOrderLine."Dimension Set ID";
            Quantity := Qty;
            "Invoiced Quantity" := Quantity;
            "Quantity (Base)" := Quantity;
            "Invoiced Qty. (Base)" := Quantity;
            "Unit of Measure Code" := PhysInvtOrderLine."Base Unit of Measure Code";
            "Qty. per Unit of Measure" := 1;
            "Source Code" := SourceCode;
            "Gen. Prod. Posting Group" := PhysInvtOrderLine."Gen. Prod. Posting Group";
            "Gen. Bus. Posting Group" := PhysInvtOrderLine."Gen. Bus. Posting Group";
            "Inventory Posting Group" := PhysInvtOrderLine."Inventory Posting Group";
            "Qty. (Calculated)" := PhysInvtOrderLine."Qty. Expected (Base)";
            if Positive then
                "Qty. (Phys. Inventory)" :=
                  PhysInvtOrderLine."Qty. Recorded (Base)" + PhysInvtOrderLine."Neg. Qty. (Base)"
            else
                "Qty. (Phys. Inventory)" :=
                  PhysInvtOrderLine."Qty. Recorded (Base)" - PhysInvtOrderLine."Pos. Qty. (Base)";
            "Last Item Ledger Entry No." := PhysInvtOrderLine."Last Item Ledger Entry No.";
            "Phys. Inventory" := true;
            Validate("Unit Amount", PhysInvtOrderLine."Unit Amount");
            Validate("Unit Cost", PhysInvtOrderLine."Unit Cost");
            "Phys Invt Counting Period Code" := PhysInvtOrderLine."Phys Invt Counting Period Code";
            "Phys Invt Counting Period Type" := PhysInvtOrderLine."Phys Invt Counting Period Type";
            PhysInvtTrackingMgt.TransferResEntryToItemJnlLine(PhysInvtOrderLine, ItemJnlLine, Qty, Positive);

            OnBeforeItemJnlPostLine(ItemJnlLine,PhysInvtOrderLine);
            ItemJnlPostLine.RunWithCheck(ItemJnlLine);
        end;
    end;

    local procedure InsertPostedHeader(PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
        with PstdPhysInvtOrderHdr do begin
            LockTable();
            Init;
            TransferFields(PhysInvtOrderHeader);
            "Pre-Assigned No." := PhysInvtOrderHeader."No.";
            if PhysInvtOrderHeader."Posting No." <> '' then begin
                "No." := PhysInvtOrderHeader."Posting No.";
                Window.Update(
                  1, StrSubstNo(CopyFromToMsg, PhysInvtOrderHeader.TableCaption, PhysInvtOrderHeader."No.", TableCaption, "No."));
            end;
            "Source Code" := SourceCode;
            "User ID" := UserId;
            Insert;
        end;
    end;

    local procedure InsertPostedLine(PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr"; PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
        PstdPhysInvtOrderLine.Init();
        PstdPhysInvtOrderLine.TransferFields(PhysInvtOrderLine);
        PstdPhysInvtOrderLine."Document No." := PstdPhysInvtOrderHdr."No.";
        PstdPhysInvtOrderLine.Insert();
    end;

    local procedure InsertPostedCommentLine(PhysInvtCommentLine: Record "Phys. Invt. Comment Line"; DocType: Option; DocNo: Code[20])
    begin
        with PostedPhysInvtCommentLine do begin
            Init;
            TransferFields(PhysInvtCommentLine);
            "Document Type" := DocType;
            "Order No." := DocNo;
            Insert;
        end;
    end;

    local procedure InsertPostedRecordings(DocNo: Code[20]; PostedDocNo: Code[20])
    var
        PstdPhysInvtRecordHdr: Record "Pstd. Phys. Invt. Record Hdr";
        PstdPhysInvtRecordLine: Record "Pstd. Phys. Invt. Record Line";
    begin
        PhysInvtRecordHeader.Reset();
        PhysInvtRecordHeader.SetRange("Order No.", DocNo);
        if PhysInvtRecordHeader.Find('-') then
            repeat
                PstdPhysInvtRecordHdr.Init();
                PstdPhysInvtRecordHdr.TransferFields(PhysInvtRecordHeader);
                PstdPhysInvtRecordHdr."Order No." := PostedDocNo;
                PstdPhysInvtRecordHdr.Insert();

                PhysInvtRecordLine.Reset();
                PhysInvtRecordLine.SetRange("Order No.", PhysInvtRecordHeader."Order No.");
                PhysInvtRecordLine.SetRange("Recording No.", PhysInvtRecordHeader."Recording No.");
                if PhysInvtRecordLine.Find('-') then
                    repeat
                        PstdPhysInvtRecordLine.Init();
                        PstdPhysInvtRecordLine.TransferFields(PhysInvtRecordLine);
                        PstdPhysInvtRecordLine."Order No." := PostedDocNo;
                        PstdPhysInvtRecordLine.Insert();
                    until PhysInvtRecordLine.Next = 0;
                PhysInvtRecordLine.DeleteAll();
            until PhysInvtRecordHeader.Next = 0;
        PhysInvtRecordHeader.DeleteAll();
    end;

    local procedure InsertEntryRelation()
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        if WhsePosting then begin
            TempWhseTrackingSpecification.Reset();
            TempWhseTrackingSpecification.DeleteAll();
        end;

        TempTrackingSpecification.Reset();
        if ItemJnlPostLine.CollectTrackingSpecification(TempTrackingSpecification) then begin
            if TempTrackingSpecification.Find('-') then
                repeat
                    if WhsePosting then begin
                        TempWhseTrackingSpecification.Init();
                        TempWhseTrackingSpecification := TempTrackingSpecification;
                        TempWhseTrackingSpecification."Source Type" := DATABASE::"Phys. Invt. Order Line";
                        TempWhseTrackingSpecification."Source Subtype" := 0;
                        TempWhseTrackingSpecification."Source ID" := PhysInvtOrderLine."Document No.";
                        TempWhseTrackingSpecification."Source Ref. No." := PhysInvtOrderLine."Line No.";
                        TempWhseTrackingSpecification.Insert();
                    end;

                    ItemEntryRelation.Init();
                    ItemEntryRelation."Item Entry No." := TempTrackingSpecification."Entry No.";
                    ItemEntryRelation.CopyTrackingFromSpec(TempTrackingSpecification);
                    ItemEntryRelation."Source Type" := DATABASE::"Pstd. Phys. Invt. Order Line";
                    ItemEntryRelation."Source Subtype" := 0;
                    ItemEntryRelation."Source ID" := PstdPhysInvtOrderLine."Document No.";
                    ItemEntryRelation."Source Batch Name" := '';
                    ItemEntryRelation."Source Prod. Order Line" := 0;
                    ItemEntryRelation."Source Ref. No." := PstdPhysInvtOrderLine."Line No.";
                    ItemEntryRelation."Order No." := PstdPhysInvtOrderLine."Document No.";
                    ItemEntryRelation."Order Line No." := PstdPhysInvtOrderLine."Line No.";
                    OnInsertEntryRelationOnBeforeInsert(ItemEntryRelation, TempTrackingSpecification, PstdPhysInvtOrderLine);
                    ItemEntryRelation.Insert();
                until TempTrackingSpecification.Next = 0;
        end;
        TempTrackingSpecification.DeleteAll();
    end;

    local procedure FinalizePost(DocNo: Code[20])
    begin
        ExpPhysInvtTracking.Reset();
        ExpPhysInvtTracking.SetRange("Order No", DocNo);
        ExpPhysInvtTracking.DeleteAll();
        PhysInvtOrderLine.Reset();
        PhysInvtOrderLine.SetRange("Document No.", DocNo);
        PhysInvtOrderLine.DeleteAll();
        PhysInvtOrderHeader.Delete();
    end;

    local procedure PostWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; OriginalQuantity: Decimal; OriginalQuantityBase: Decimal; Positive: Boolean)
    var
        WhseJnlLine: Record "Warehouse Journal Line";
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WMSMgt: Codeunit "WMS Management";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
    begin
        with ItemJnlLine do begin
            Quantity := OriginalQuantity;
            "Quantity (Base)" := OriginalQuantityBase;
            if WMSMgt.CreateWhseJnlLine(ItemJnlLine, 1, WhseJnlLine, false) then begin
                WhseJnlLine.SetSource(
                  DATABASE::"Phys. Invt. Order Line", 0, PhysInvtOrderLine."Document No.", PhysInvtOrderLine."Line No.", 0);
                WhseJnlLine."Reference No." := PstdPhysInvtOrderHdr."No.";
                if Positive then
                    WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::"Positive Adjmt."
                else
                    WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::"Negative Adjmt.";

                ItemTrackingMgt.SplitWhseJnlLine(
                  WhseJnlLine, TempWhseJnlLine2, TempWhseTrackingSpecification, false);
                if TempWhseJnlLine2.Find('-') then
                    repeat
                        WMSMgt.CheckWhseJnlLine(TempWhseJnlLine2, 1, 0, false);
                        WhseJnlRegisterLine.Run(TempWhseJnlLine2);
                        Clear(WhseJnlRegisterLine);
                    until TempWhseJnlLine2.Next = 0;
            end;
        end;
    end;

    local procedure PostPhysInventoryOrderLine()
    begin
        LineCount := LineCount + 1;
        Window.Update(3, LineCount);

        InsertPostedLine(PstdPhysInvtOrderHdr, PhysInvtOrderLine);

        if not PhysInvtOrderLine.EmptyLine then begin
            if (PhysInvtOrderLine."Location Code" = '') or
               ((PhysInvtOrderLine."Pos. Qty. (Base)" = 0) and (PhysInvtOrderLine."Neg. Qty. (Base)" = 0))
            then begin
                WhsePosting := false
            end else begin
                Location.Get(PhysInvtOrderLine."Location Code");
                Location.TestField("Directed Put-away and Pick", false);
                WhsePosting := Location."Bin Mandatory";
            end;

            if (PhysInvtOrderLine."Pos. Qty. (Base)" <> 0) or
               (PhysInvtOrderLine."Neg. Qty. (Base)" = 0)
            then begin
                OriginalQuantityBase := PhysInvtOrderLine."Pos. Qty. (Base)";
                PostItemJnlLine(
                  true,// Positive
                  PhysInvtOrderLine."Pos. Qty. (Base)");
                InsertEntryRelation;
                if WhsePosting then
                    PostWhseJnlLine(
                      ItemJnlLine, OriginalQuantityBase, OriginalQuantityBase, true); // Positive
            end;

            if PhysInvtOrderLine."Neg. Qty. (Base)" <> 0 then begin
                OriginalQuantityBase := PhysInvtOrderLine."Neg. Qty. (Base)";
                PostItemJnlLine(
                  false,// Negative
                  PhysInvtOrderLine."Neg. Qty. (Base)");
                InsertEntryRelation;
                if WhsePosting then
                    PostWhseJnlLine(
                      ItemJnlLine, OriginalQuantityBase, OriginalQuantityBase, false); // Negative
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemJnlPostLine(var ItemJournalLine: Record "Item Journal Line"; PhysInvtOrderLine: Record "Phys. Invt. Order Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckOrderLineOnBeforeGetSamePhysInvtOrderLine(PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var PhysInvtOrderLine2: Record "Phys. Invt. Order Line"; var ErrorText: Text[250]; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertEntryRelationOnBeforeInsert(var ItemEntryRelation: Record "Item Entry Relation"; TrackingSpecification: Record "Tracking Specification"; PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line")
    begin
    end;
}

