codeunit 900 "Assembly-Post"
{
    Permissions = TableData "Posted Assembly Header" = im,
                  TableData "Posted Assembly Line" = im,
                  TableData "Item Entry Relation" = i;
    TableNo = "Assembly Header";

    trigger OnRun()
    var
        AssemblyHeader: Record "Assembly Header";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        SavedSuppressCommit: Boolean;
    begin
        OnBeforeOnRun(Rec, SuppressCommit);

        // Replace posting date if called from batch posting
        ValidatePostingDate(Rec);

        SavedSuppressCommit := SuppressCommit;
        ClearAll();
        SuppressCommit := SavedSuppressCommit;

        AssemblyHeader := Rec;

        if IsAsmToOrder then
            TestField("Assemble to Order", false);

        OpenWindow("Document Type");
        Window.Update(1, StrSubstNo('%1 %2', "Document Type", "No."));

        InitPost(AssemblyHeader);
        Post(AssemblyHeader, ItemJnlPostLine, ResJnlPostLine, WhseJnlRegisterLine, false);
        FinalizePost(AssemblyHeader);
        if not SuppressCommit then
            Commit();

        Window.Close();
        Rec := AssemblyHeader;

        OnAfterOnRun(AssemblyHeader, SuppressCommit);
    end;

    var
        GLEntry: Record "G/L Entry";
        GLSetup: Record "General Ledger Setup";
        AssembledItem: Record Item;
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        ResJnlPostLine: Codeunit "Res. Jnl.-Post Line";
        UndoPostingMgt: Codeunit "Undo Posting Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        Window: Dialog;
        PostingDate: Date;
        SourceCode: Code[10];
        PostingDateExists: Boolean;
        ReplacePostingDate: Boolean;
        Text001: Label 'is not within your range of allowed posting dates.', Comment = 'starts with "Posting Date"';
        Text002: Label 'The combination of dimensions used in %1 %2 is blocked. %3.', Comment = '%1 = Document Type, %2 = Document No.';
        Text003: Label 'The combination of dimensions used in %1 %2, line no. %3 is blocked. %4.', Comment = '%1 = Document Type, %2 = Document No.';
        Text004: Label 'The dimensions that are used in %1 %2 are not valid. %3.', Comment = '%1 = Document Type, %2 = Document No.';
        Text005: Label 'The dimensions that are used in %1 %2, line no. %3, are not valid. %4.', Comment = '%1 = Document Type, %2 = Document No.';
        Text006: Label 'There is nothing to post.';
        Text007: Label 'Posting lines              #2######';
        GLSetupRead: Boolean;
        Text008: Label 'Posting %1';
        Text009: Label '%1 should be blank for comment text: %2.';
        ShowProgress: Boolean;
        Text010: Label 'Undoing %1';
        Text011: Label 'Posted assembly order %1 cannot be restored because the number of lines in assembly order %2 has changed.', Comment = '%1=Posted Assembly Order No. field value,%2=Assembly Header Document No field value';
        SuppressCommit: Boolean;

    local procedure InitPost(var AssemblyHeader: Record "Assembly Header")
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        OnBeforeInitPost(AssemblyHeader, SuppressCommit);

        with AssemblyHeader do begin
            TestField("Document Type");
            TestField("Posting Date");
            PostingDate := "Posting Date";
            if GenJnlCheckLine.DateNotAllowed("Posting Date") then
                FieldError("Posting Date", Text001);
            TestField("Item No.");
            CheckDim(AssemblyHeader);
            if not IsOrderPostable(AssemblyHeader) then
                Error(Text006);

            if "Posting No." = '' then
                if "Document Type" = "Document Type"::Order then begin
                    TestField("Posting No. Series");
                    "Posting No." := NoSeriesMgt.GetNextNo("Posting No. Series", "Posting Date", true);
                    Modify();
                    if not GenJnlPostPreview.IsActive and not SuppressCommit then
                        Commit();
                end;

            if Status = Status::Open then begin
                CODEUNIT.Run(CODEUNIT::"Release Assembly Document", AssemblyHeader);
                TestField(Status, Status::Released);
                Status := Status::Open;
                if not GenJnlPostPreview.IsActive then begin
                    Modify();
                    if not SuppressCommit then
                        Commit();
                end;
                Status := Status::Released;
            end;

            GetSourceCode(IsAsmToOrder);
        end;

        OnAfterInitPost(AssemblyHeader, SuppressCommit);
    end;

    local procedure Post(var AssemblyHeader: Record "Assembly Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var ResJnlPostLine: Codeunit "Res. Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line"; NeedUpdateUnitCost: Boolean)
    var
        AssemblyLine: Record "Assembly Line";
        PostedAssemblyHeader: Record "Posted Assembly Header";
        AssemblySetup: Record "Assembly Setup";
        AssemblyCommentLine: Record "Assembly Comment Line";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        OnBeforePost(AssemblyHeader);

        with AssemblyHeader do begin
            SuspendStatusCheck(true);
            LockTables(AssemblyLine, AssemblyHeader);

            // Insert posted assembly header
            if "Document Type" = "Document Type"::Order then begin
                PostedAssemblyHeader.Init();
                PostedAssemblyHeader.TransferFields(AssemblyHeader);

                PostedAssemblyHeader."No." := "Posting No.";
                PostedAssemblyHeader."Order No. Series" := "No. Series";
                PostedAssemblyHeader."Order No." := "No.";
                PostedAssemblyHeader."Source Code" := SourceCode;
                PostedAssemblyHeader."User ID" := UserId;
                PostedAssemblyHeader.Insert();

                AssemblySetup.Get();
                if AssemblySetup."Copy Comments when Posting" then begin
                    CopyCommentLines(
                      "Document Type", AssemblyCommentLine."Document Type"::"Posted Assembly",
                      "No.", PostedAssemblyHeader."No.");
                    RecordLinkManagement.CopyLinks(AssemblyHeader, PostedAssemblyHeader);
                    OnPostOnAfterCopyComments(AssemblyHeader, PostedAssemblyHeader);
                end;
            end;

            AssembledItem.Get("Item No.");
            TestField("Document Type", "Document Type"::Order);
            PostLines(AssemblyHeader, AssemblyLine, PostedAssemblyHeader, ItemJnlPostLine, ResJnlPostLine, WhseJnlRegisterLine);
            PostHeader(AssemblyHeader, PostedAssemblyHeader, ItemJnlPostLine, WhseJnlRegisterLine, NeedUpdateUnitCost);
        end;

        OnAfterPost(AssemblyHeader);
    end;

    local procedure FinalizePost(AssemblyHeader: Record "Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
        AssemblyCommentLine: Record "Assembly Comment Line";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
    begin
        OnBeforeFinalizePost(AssemblyHeader);

        MakeInvtAdjmt();

        with AssemblyHeader do begin
            // Delete header and lines
            AssemblyLine.Reset();
            AssemblyLine.SetRange("Document Type", "Document Type");
            AssemblyLine.SetRange("Document No.", "No.");
            if "Remaining Quantity (Base)" = 0 then begin
                if HasLinks then
                    DeleteLinks();
                DeleteWhseRequest(AssemblyHeader);
                Delete;
                if AssemblyLine.Find('-') then
                    repeat
                        if AssemblyLine.HasLinks then
                            DeleteLinks();
                        AssemblyLineReserve.SetDeleteItemTracking(true);
                        AssemblyLineReserve.DeleteLine(AssemblyLine);
                    until AssemblyLine.Next() = 0;
                AssemblyLine.DeleteAll();
                AssemblyCommentLine.SetCurrentKey("Document Type", "Document No.");
                AssemblyCommentLine.SetRange("Document Type", "Document Type");
                AssemblyCommentLine.SetRange("Document No.", "No.");
                if not AssemblyCommentLine.IsEmpty() then
                    AssemblyCommentLine.DeleteAll();
            end;
        end;

        OnAfterFinalizePost(AssemblyHeader);
    end;

    local procedure OpenWindow(DocType: Option)
    var
        AsmHeader: Record "Assembly Header";
    begin
        AsmHeader."Document Type" := DocType;
        if AsmHeader."Document Type" = AsmHeader."Document Type"::Order then
            Window.Open(
              '#1#################################\\' +
              Text007 + '\\' +
              StrSubstNo(Text008, AsmHeader."Document Type"));
        ShowProgress := true;
    end;

    procedure SetPostingDate(NewReplacePostingDate: Boolean; NewPostingDate: Date)
    begin
        PostingDateExists := true;
        ReplacePostingDate := NewReplacePostingDate;
        PostingDate := NewPostingDate;
    end;

    local procedure ValidatePostingDate(var AssemblyHeader: Record "Assembly Header")
    var
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        BatchPostParameterTypes: Codeunit "Batch Post Parameter Types";
    begin
        if not PostingDateExists then
            PostingDateExists :=
              BatchProcessingMgt.GetParameterBoolean(
                AssemblyHeader.RecordId, BatchPostParameterTypes.ReplacePostingDate, ReplacePostingDate) and
              BatchProcessingMgt.GetParameterDate(AssemblyHeader.RecordId, BatchPostParameterTypes.PostingDate, PostingDate);

        if PostingDateExists and (ReplacePostingDate or (AssemblyHeader."Posting Date" = 0D)) then
            AssemblyHeader."Posting Date" := PostingDate;
    end;

    local procedure CheckDim(AssemblyHeader: Record "Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine."Line No." := 0;
        CheckDimValuePosting(AssemblyHeader, AssemblyLine);
        CheckDimComb(AssemblyHeader, AssemblyLine);

        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetFilter(Type, '<>%1', AssemblyLine.Type::" ");
        if AssemblyLine.Find('-') then
            repeat
                if AssemblyHeader."Quantity to Assemble" <> 0 then begin
                    CheckDimComb(AssemblyHeader, AssemblyLine);
                    CheckDimValuePosting(AssemblyHeader, AssemblyLine);
                end;
            until AssemblyLine.Next() = 0;
    end;

    local procedure CheckDimComb(AssemblyHeader: Record "Assembly Header"; AssemblyLine: Record "Assembly Line")
    begin
        if AssemblyLine."Line No." = 0 then
            if not DimMgt.CheckDimIDComb(AssemblyHeader."Dimension Set ID") then
                Error(Text002, AssemblyHeader."Document Type", AssemblyHeader."No.", DimMgt.GetDimCombErr);

        if AssemblyLine."Line No." <> 0 then
            if not DimMgt.CheckDimIDComb(AssemblyLine."Dimension Set ID") then
                Error(Text003, AssemblyHeader."Document Type", AssemblyHeader."No.", AssemblyLine."Line No.", DimMgt.GetDimCombErr);
    end;

    local procedure CheckDimValuePosting(AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line")
    var
        TableIDArr: array[10] of Integer;
        NumberArr: array[10] of Code[20];
    begin
        if AssemblyLine."Line No." = 0 then begin
            TableIDArr[1] := DATABASE::Item;
            NumberArr[1] := AssemblyHeader."Item No.";
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, AssemblyHeader."Dimension Set ID") then
                Error(
                  Text004,
                  AssemblyHeader."Document Type", AssemblyHeader."No.", DimMgt.GetDimValuePostingErr);
        end else begin
            TableIDArr[1] := DimMgt.TypeToTableID4(AssemblyLine.Type);
            NumberArr[1] := AssemblyLine."No.";
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, AssemblyLine."Dimension Set ID") then
                Error(
                  Text005,
                  AssemblyHeader."Document Type", AssemblyHeader."No.", AssemblyLine."Line No.", DimMgt.GetDimValuePostingErr);
        end;
    end;

    local procedure IsOrderPostable(AssemblyHeader: Record "Assembly Header"): Boolean
    var
        AssemblyLine: Record "Assembly Line";
    begin
        if AssemblyHeader."Document Type" <> AssemblyHeader."Document Type"::Order then
            exit(false);

        if AssemblyHeader."Quantity to Assemble" = 0 then
            exit(false);

        AssemblyLine.SetCurrentKey("Document Type", "Document No.", Type);
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");

        AssemblyLine.SetFilter(Type, '<>%1', AssemblyLine.Type::" ");
        if AssemblyLine.IsEmpty() then
            exit(false);

        AssemblyLine.SetFilter("Quantity to Consume", '<>0');
        exit(not AssemblyLine.IsEmpty);
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get();
        GLSetupRead := true;
    end;

    local procedure LockTables(var AssemblyLine: Record "Assembly Line"; var AssemblyHeader: Record "Assembly Header")
    var
        GLSetup: Record "General Ledger Setup";
    begin
        AssemblyLine.LockTable();
        AssemblyHeader.LockTable();
        GetGLSetup;
        if not GLSetup.OptimGLEntLockForMultiuserEnv then begin
            GLEntry.LockTable();
            if GLEntry.FindLast then;
        end;
    end;

    local procedure CopyCommentLines(FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    var
        AssemblyCommentLine: Record "Assembly Comment Line";
        AssemblyCommentLine2: Record "Assembly Comment Line";
    begin
        AssemblyCommentLine.SetRange("Document Type", FromDocumentType);
        AssemblyCommentLine.SetRange("Document No.", FromNumber);
        if AssemblyCommentLine.Find('-') then
            repeat
                AssemblyCommentLine2 := AssemblyCommentLine;
                AssemblyCommentLine2."Document Type" := ToDocumentType;
                AssemblyCommentLine2."Document No." := ToNumber;
                AssemblyCommentLine2.Insert();
            until AssemblyCommentLine.Next() = 0;
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    local procedure SortLines(var AssemblyLine: Record "Assembly Line")
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GetGLSetup();
        if GLSetup.OptimGLEntLockForMultiuserEnv then
            AssemblyLine.SetCurrentKey("Document Type", Type, "No.")
        else
            AssemblyLine.SetCurrentKey("Document Type", "Document No.", "Line No.");
    end;

    local procedure SortPostedLines(var PostedAsmLine: Record "Posted Assembly Line")
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GetGLSetup();
        if GLSetup.OptimGLEntLockForMultiuserEnv then
            PostedAsmLine.SetCurrentKey(Type, "No.")
        else
            PostedAsmLine.SetCurrentKey("Document No.", "Line No.");
    end;

    local procedure GetLineQtys(var LineQty: Decimal; var LineQtyBase: Decimal; AssemblyLine: Record "Assembly Line")
    begin
        with AssemblyLine do begin
            LineQty := Round("Quantity to Consume", UOMMgt.QtyRndPrecision);
            LineQtyBase := Round("Quantity to Consume (Base)", UOMMgt.QtyRndPrecision);
        end;
    end;

    local procedure GetHeaderQtys(var HeaderQty: Decimal; var HeaderQtyBase: Decimal; AssemblyHeader: Record "Assembly Header")
    begin
        with AssemblyHeader do begin
            HeaderQty := Round("Quantity to Assemble", UOMMgt.QtyRndPrecision);
            HeaderQtyBase := Round("Quantity to Assemble (Base)", UOMMgt.QtyRndPrecision);
        end;
    end;

    local procedure PostLines(AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; PostedAssemblyHeader: Record "Posted Assembly Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var ResJnlPostLine: Codeunit "Res. Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    var
        PostedAssemblyLine: Record "Posted Assembly Line";
        LineCounter: Integer;
        QtyToConsume: Decimal;
        QtyToConsumeBase: Decimal;
        ItemLedgEntryNo: Integer;
    begin
        with AssemblyLine do begin
            Reset();
            SetRange("Document Type", AssemblyHeader."Document Type");
            SetRange("Document No.", AssemblyHeader."No.");
            SortLines(AssemblyLine);

            LineCounter := 0;
            if FindSet() then
                repeat
                    if ("No." = '') and
                       (Description <> '') and
                       (Type <> Type::" ")
                    then
                        Error(Text009, FieldCaption(Type), Description);

                    LineCounter := LineCounter + 1;
                    if ShowProgress then
                        Window.Update(2, LineCounter);

                    GetLineQtys(QtyToConsume, QtyToConsumeBase, AssemblyLine);

                    ItemLedgEntryNo := 0;
                    if QtyToConsumeBase <> 0 then begin
                        case Type of
                            Type::Item:
                                ItemLedgEntryNo :=
                                  PostItemConsumption(
                                    AssemblyHeader,
                                    AssemblyLine,
                                    AssemblyHeader."Posting No. Series",
                                    QtyToConsume,
                                    QtyToConsumeBase, ItemJnlPostLine, WhseJnlRegisterLine, AssemblyHeader."Posting No.", false, 0);
                            Type::Resource:
                                PostResourceConsumption(
                                  AssemblyHeader,
                                  AssemblyLine,
                                  AssemblyHeader."Posting No. Series",
                                  QtyToConsume,
                                  QtyToConsumeBase, ResJnlPostLine, ItemJnlPostLine, AssemblyHeader."Posting No.", false);
                        end;

                        // modify the lines
                        "Consumed Quantity" := "Consumed Quantity" + QtyToConsume;
                        "Consumed Quantity (Base)" := "Consumed Quantity (Base)" + QtyToConsumeBase;
                        InitRemainingQty();
                        InitQtyToConsume();
                        OnBeforeAssemblyLineModify(AssemblyLine, QtyToConsumeBase);
                        Modify();
                    end;

                    // Insert posted assembly lines
                    PostedAssemblyLine.Init();
                    PostedAssemblyLine.TransferFields(AssemblyLine);
                    PostedAssemblyLine."Document No." := PostedAssemblyHeader."No.";
                    PostedAssemblyLine.Quantity := QtyToConsume;
                    PostedAssemblyLine."Quantity (Base)" := QtyToConsumeBase;
                    PostedAssemblyLine."Cost Amount" := Round(PostedAssemblyLine.Quantity * "Unit Cost");
                    PostedAssemblyLine."Order No." := "Document No.";
                    PostedAssemblyLine."Order Line No." := "Line No.";
                    InsertLineItemEntryRelation(PostedAssemblyLine, ItemJnlPostLine, ItemLedgEntryNo);
                    OnBeforePostedAssemblyLineInsert(PostedAssemblyLine, AssemblyLine);
                    PostedAssemblyLine.Insert();
                    OnAfterPostedAssemblyLineInsert(PostedAssemblyLine, AssemblyLine);
                until Next() = 0;
        end;
    end;

    local procedure PostHeader(var AssemblyHeader: Record "Assembly Header"; var PostedAssemblyHeader: Record "Posted Assembly Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line"; NeedUpdateUnitCost: Boolean)
    var
        WhseAssemblyRelease: Codeunit "Whse.-Assembly Release";
        ItemLedgEntryNo: Integer;
        QtyToOutput: Decimal;
        QtyToOutputBase: Decimal;
    begin
        with AssemblyHeader do begin
            GetHeaderQtys(QtyToOutput, QtyToOutputBase, AssemblyHeader);
            if NeedUpdateUnitCost then
                if not IsStandardCostItem then
                    UpdateUnitCost;

            ItemLedgEntryNo :=
              PostItemOutput(
                AssemblyHeader, "Posting No. Series",
                QtyToOutput, QtyToOutputBase,
                ItemJnlPostLine, WhseJnlRegisterLine, "Posting No.", false, 0);

            // modify the header
            "Assembled Quantity" := "Assembled Quantity" + QtyToOutput;
            "Assembled Quantity (Base)" := "Assembled Quantity (Base)" + QtyToOutputBase;
            InitRemainingQty();
            InitQtyToAssemble();
            Validate("Quantity to Assemble");
            "Posting No." := '';
            Modify();

            WhseAssemblyRelease.Release(AssemblyHeader);

            // modify the posted assembly header
            PostedAssemblyHeader.Quantity := QtyToOutput;
            PostedAssemblyHeader."Quantity (Base)" := QtyToOutputBase;
            PostedAssemblyHeader."Cost Amount" := Round(PostedAssemblyHeader.Quantity * "Unit Cost");

            InsertHeaderItemEntryRelation(PostedAssemblyHeader, ItemJnlPostLine, ItemLedgEntryNo);
            PostedAssemblyHeader.Modify();
            OnAfterPostedAssemblyHeaderModify(PostedAssemblyHeader, AssemblyHeader, ItemLedgEntryNo);
        end;
    end;

    local procedure PostItemConsumption(AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; PostingNoSeries: Code[20]; QtyToConsume: Decimal; QtyToConsumeBase: Decimal; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line"; DocumentNo: Code[20]; IsCorrection: Boolean; ApplyToEntryNo: Integer): Integer
    var
        ItemJnlLine: Record "Item Journal Line";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
    begin
        with AssemblyLine do begin
            TestField(Type, Type::Item);

            ItemJnlLine.Init();
            ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::"Assembly Consumption";
            ItemJnlLine."Source Code" := SourceCode;
            ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Posted Assembly";
            ItemJnlLine."Document No." := DocumentNo;
            ItemJnlLine."Document Date" := PostingDate;
            ItemJnlLine."Document Line No." := "Line No.";
            ItemJnlLine."Order Type" := ItemJnlLine."Order Type"::Assembly;
            ItemJnlLine."Order No." := "Document No.";
            ItemJnlLine."Order Line No." := "Line No.";
            ItemJnlLine."Dimension Set ID" := "Dimension Set ID";
            ItemJnlLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
            ItemJnlLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
            ItemJnlLine."Source Type" := ItemJnlLine."Source Type"::Item;
            ItemJnlLine."Source No." := AssembledItem."No.";

            ItemJnlLine."Posting Date" := PostingDate;
            ItemJnlLine."Posting No. Series" := PostingNoSeries;
            ItemJnlLine.Type := ItemJnlLine.Type::" ";
            ItemJnlLine."Item No." := "No.";
            ItemJnlLine."Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";
            ItemJnlLine."Inventory Posting Group" := "Inventory Posting Group";

            ItemJnlLine."Unit of Measure Code" := "Unit of Measure Code";
            ItemJnlLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
            ItemJnlLine.Quantity := QtyToConsume;
            ItemJnlLine."Quantity (Base)" := QtyToConsumeBase;
            ItemJnlLine."Variant Code" := "Variant Code";
            ItemJnlLine.Description := Description;
            ItemJnlLine.Validate("Location Code", "Location Code");
            ItemJnlLine."Bin Code" := "Bin Code";
            ItemJnlLine."Unit Cost" := "Unit Cost";
            ItemJnlLine.Correction := IsCorrection;
            ItemJnlLine."Applies-to Entry" := "Appl.-to Item Entry";
            UpdateItemCategoryAndGroupCode(ItemJnlLine);
        end;

        OnBeforePostItemConsumption(AssemblyHeader, AssemblyLine, ItemJnlLine);

        if IsCorrection then
            PostCorrectionItemJnLine(
              ItemJnlLine, AssemblyHeader, ItemJnlPostLine, WhseJnlRegisterLine, DATABASE::"Posted Assembly Line", ApplyToEntryNo)
        else begin
            AssemblyLineReserve.TransferAsmLineToItemJnlLine(AssemblyLine, ItemJnlLine, ItemJnlLine."Quantity (Base)", false);
            PostItemJnlLine(ItemJnlLine, ItemJnlPostLine);
            AssemblyLineReserve.UpdateItemTrackingAfterPosting(AssemblyLine);
            PostWhseJnlLine(AssemblyHeader, ItemJnlLine, ItemJnlPostLine, WhseJnlRegisterLine);
        end;
        exit(ItemJnlLine."Item Shpt. Entry No.");
    end;

    local procedure PostItemOutput(var AssemblyHeader: Record "Assembly Header"; PostingNoSeries: Code[20]; QtyToOutput: Decimal; QtyToOutputBase: Decimal; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line"; DocumentNo: Code[20]; IsCorrection: Boolean; ApplyToEntryNo: Integer): Integer
    var
        ItemJnlLine: Record "Item Journal Line";
        AssemblyHeaderReserve: Codeunit "Assembly Header-Reserve";
    begin
        with AssemblyHeader do begin
            ItemJnlLine.Init();
            ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::"Assembly Output";
            ItemJnlLine."Source Code" := SourceCode;
            ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Posted Assembly";
            ItemJnlLine."Document No." := DocumentNo;
            ItemJnlLine."Document Date" := PostingDate;
            ItemJnlLine."Document Line No." := 0;
            ItemJnlLine."Order No." := "No.";
            ItemJnlLine."Order Type" := ItemJnlLine."Order Type"::Assembly;
            ItemJnlLine."Dimension Set ID" := "Dimension Set ID";
            ItemJnlLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
            ItemJnlLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
            ItemJnlLine."Order Line No." := 0;
            ItemJnlLine."Source Type" := ItemJnlLine."Source Type"::Item;
            ItemJnlLine."Source No." := AssembledItem."No.";

            ItemJnlLine."Posting Date" := PostingDate;
            ItemJnlLine."Posting No. Series" := PostingNoSeries;
            ItemJnlLine.Type := ItemJnlLine.Type::" ";
            ItemJnlLine."Item No." := "Item No.";
            ItemJnlLine."Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";
            ItemJnlLine."Inventory Posting Group" := "Inventory Posting Group";

            ItemJnlLine."Unit of Measure Code" := "Unit of Measure Code";
            ItemJnlLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
            ItemJnlLine.Quantity := QtyToOutput;
            ItemJnlLine."Invoiced Quantity" := QtyToOutput;
            ItemJnlLine."Quantity (Base)" := QtyToOutputBase;
            ItemJnlLine."Invoiced Qty. (Base)" := QtyToOutputBase;
            ItemJnlLine."Variant Code" := "Variant Code";
            ItemJnlLine.Description := Description;
            ItemJnlLine.Validate("Location Code", "Location Code");
            ItemJnlLine."Bin Code" := "Bin Code";
            ItemJnlLine."Indirect Cost %" := "Indirect Cost %";
            ItemJnlLine."Overhead Rate" := "Overhead Rate";
            ItemJnlLine."Unit Cost" := "Unit Cost";
            ItemJnlLine.Validate("Unit Amount",
              Round(("Unit Cost" - "Overhead Rate") / (1 + "Indirect Cost %" / 100),
                GLSetup."Unit-Amount Rounding Precision"));
            ItemJnlLine.Correction := IsCorrection;
            UpdateItemCategoryAndGroupCode(ItemJnlLine);
        end;
        OnAfterCreateItemJnlLineFromAssemblyHeader(ItemJnlLine, AssemblyHeader);

        if IsCorrection then
            PostCorrectionItemJnLine(
              ItemJnlLine, AssemblyHeader, ItemJnlPostLine, WhseJnlRegisterLine, DATABASE::"Posted Assembly Header", ApplyToEntryNo)
        else begin
            AssemblyHeaderReserve.TransferAsmHeaderToItemJnlLine(AssemblyHeader, ItemJnlLine, ItemJnlLine."Quantity (Base)", false);
            PostItemJnlLine(ItemJnlLine, ItemJnlPostLine);
            AssemblyHeaderReserve.UpdateItemTrackingAfterPosting(AssemblyHeader);
            PostWhseJnlLine(AssemblyHeader, ItemJnlLine, ItemJnlPostLine, WhseJnlRegisterLine);
        end;
        exit(ItemJnlLine."Item Shpt. Entry No.");
    end;

    local procedure PostItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line")
    var
        OrigItemJnlLine: Record "Item Journal Line";
        ItemShptEntry: Integer;
    begin
        OrigItemJnlLine := ItemJnlLine;
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
        ItemShptEntry := ItemJnlLine."Item Shpt. Entry No.";
        ItemJnlLine := OrigItemJnlLine;
        ItemJnlLine."Item Shpt. Entry No." := ItemShptEntry;
    end;

    local procedure PostCorrectionItemJnLine(var ItemJnlLine: Record "Item Journal Line"; AssemblyHeader: Record "Assembly Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line"; SourceType: Integer; ApplyToEntry: Integer)
    var
        TempItemLedgEntry2: Record "Item Ledger Entry" temporary;
        ATOLink: Record "Assemble-to-Order Link";
        TempItemLedgEntryInChain: Record "Item Ledger Entry" temporary;
        ItemApplnEntry: Record "Item Application Entry";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        UndoPostingMgt.CollectItemLedgEntries(
          TempItemLedgEntry2, SourceType, ItemJnlLine."Document No.", ItemJnlLine."Document Line No.",
          Abs(ItemJnlLine."Quantity (Base)"), ApplyToEntry);

        if TempItemLedgEntry2.FindSet() then
            repeat
                ItemTrackingMgt.RetrieveAppliedExpirationDate(TempItemLedgEntry2);
                TempItemLedgEntry := TempItemLedgEntry2;
                TempItemLedgEntry.Insert();

                if ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::"Assembly Consumption" then begin
                    ItemJnlLine.Quantity :=
                      Round(TempItemLedgEntry.Quantity * TempItemLedgEntry."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
                    ItemJnlLine."Quantity (Base)" := TempItemLedgEntry.Quantity;

                    ItemJnlLine."Applies-from Entry" := TempItemLedgEntry."Entry No.";
                end else begin
                    ItemJnlLine.Quantity :=
                      -Round(TempItemLedgEntry.Quantity * TempItemLedgEntry."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
                    ItemJnlLine."Quantity (Base)" := -TempItemLedgEntry.Quantity;

                    if (ItemJnlLine."Order Type" = ItemJnlLine."Order Type"::Assembly) and
                       ATOLink.Get(ATOLink."Assembly Document Type"::Order, ItemJnlLine."Order No.")
                    then begin
                        TempItemLedgEntryInChain.Reset();
                        TempItemLedgEntryInChain.DeleteAll();
                        ItemApplnEntry.GetVisitedEntries(TempItemLedgEntry, TempItemLedgEntryInChain, true);

                        ItemJnlLine."Applies-to Entry" := FindAppliesToATOUndoEntry(TempItemLedgEntryInChain);
                    end else
                        ItemJnlLine."Applies-to Entry" := TempItemLedgEntry."Entry No.";
                end;
                ItemJnlLine."Invoiced Quantity" := ItemJnlLine.Quantity;
                ItemJnlLine."Invoiced Qty. (Base)" := ItemJnlLine."Quantity (Base)";

                ItemJnlLine.CopyTrackingFromItemLedgEntry(TempItemLedgEntry);
                ItemJnlLine."Warranty Date" := TempItemLedgEntry."Warranty Date";
                ItemJnlLine."Item Expiration Date" := TempItemLedgEntry."Expiration Date";
                ItemJnlLine."Item Shpt. Entry No." := 0;

                OnBeforePostCorrectionItemJnLine(ItemJnlLine, TempItemLedgEntry);

                ItemJnlPostLine.RunWithCheck(ItemJnlLine);
                PostWhseJnlLine(AssemblyHeader, ItemJnlLine, ItemJnlPostLine, WhseJnlRegisterLine);
            until TempItemLedgEntry2.Next() = 0;
    end;

    local procedure FindAppliesToATOUndoEntry(var ItemLedgEntryInChain: Record "Item Ledger Entry"): Integer
    begin
        with ItemLedgEntryInChain do begin
            Reset;
            SetCurrentKey("Item No.", Positive);
            SetRange(Positive, true);
            SetRange(Open, true);
            FindFirst;
            exit("Entry No.");
        end;
    end;

    local procedure GetLocation(LocationCode: Code[10]; var Location: Record Location)
    begin
        if LocationCode = '' then
            Location.GetLocationSetup(LocationCode, Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure PostWhseJnlLine(AssemblyHeader: Record "Assembly Header"; ItemJnlLine: Record "Item Journal Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    var
        Location: Record Location;
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        GetLocation(ItemJnlLine."Location Code", Location);
        if not Location."Bin Mandatory" then
            exit;

        if ItemTrackingMgt.GetWhseItemTrkgSetup(ItemJnlLine."Item No.") then
            if ItemJnlPostLine.CollectTrackingSpecification(TempTrackingSpecification) then
                if TempTrackingSpecification.FindSet() then
                    repeat
                        case ItemJnlLine."Entry Type" of
                            ItemJnlLine."Entry Type"::"Assembly Consumption":
                                TempTrackingSpecification."Source Type" := DATABASE::"Assembly Line";
                            ItemJnlLine."Entry Type"::"Assembly Output":
                                TempTrackingSpecification."Source Type" := DATABASE::"Assembly Header";
                        end;
                        TempTrackingSpecification."Source Subtype" := AssemblyHeader."Document Type";
                        TempTrackingSpecification."Source ID" := AssemblyHeader."No.";
                        TempTrackingSpecification."Source Batch Name" := '';
                        TempTrackingSpecification."Source Prod. Order Line" := 0;
                        TempTrackingSpecification."Source Ref. No." := ItemJnlLine."Order Line No.";
                        TempTrackingSpecification.Modify();
                    until TempTrackingSpecification.Next() = 0;

        CreateWhseJnlLine(Location, TempWhseJnlLine, AssemblyHeader, ItemJnlLine);
        ItemTrackingMgt.SplitWhseJnlLine(TempWhseJnlLine, TempWhseJnlLine2, TempTrackingSpecification, false);
        if TempWhseJnlLine2.FindSet() then
            repeat
                WhseJnlRegisterLine.Run(TempWhseJnlLine2);
            until TempWhseJnlLine2.Next() = 0;
    end;

    local procedure CreateWhseJnlLine(Location: Record Location; var WhseJnlLine: Record "Warehouse Journal Line"; AssemblyHeader: Record "Assembly Header"; ItemJnlLine: Record "Item Journal Line")
    var
        WMSManagement: Codeunit "WMS Management";
        WhseMgt: Codeunit "Whse. Management";
    begin
        with ItemJnlLine do begin
            case "Entry Type" of
                "Entry Type"::"Assembly Consumption":
                    WMSManagement.CheckAdjmtBin(Location, Quantity, true);
                "Entry Type"::"Assembly Output":
                    WMSManagement.CheckAdjmtBin(Location, Quantity, false);
            end;

            WMSManagement.CreateWhseJnlLine(ItemJnlLine, 0, WhseJnlLine, false);

            case "Entry Type" of
                "Entry Type"::"Assembly Consumption":
                    WhseJnlLine."Source Type" := DATABASE::"Assembly Line";
                "Entry Type"::"Assembly Output":
                    WhseJnlLine."Source Type" := DATABASE::"Assembly Header";
            end;
            WhseJnlLine."Source Subtype" := AssemblyHeader."Document Type";
            WhseJnlLine."Source Code" := SourceCode;
            WhseJnlLine."Source Document" := WhseMgt.GetSourceDocument(WhseJnlLine."Source Type", WhseJnlLine."Source Subtype");
            TestField("Order Type", "Order Type"::Assembly);
            WhseJnlLine."Source No." := "Order No.";
            WhseJnlLine."Source Line No." := "Order Line No.";
            WhseJnlLine."Reason Code" := "Reason Code";
            WhseJnlLine."Registering No. Series" := "Posting No. Series";
            WhseJnlLine."Whse. Document Type" := WhseJnlLine."Whse. Document Type"::Assembly;
            WhseJnlLine."Whse. Document No." := "Order No.";
            WhseJnlLine."Whse. Document Line No." := "Order Line No.";
            WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::Assembly;
            WhseJnlLine."Reference No." := "Document No.";
            if Location."Directed Put-away and Pick" then
                WMSManagement.CalcCubageAndWeight(
                  "Item No.", "Unit of Measure Code", WhseJnlLine."Qty. (Absolute)",
                  WhseJnlLine.Cubage, WhseJnlLine.Weight);
        end;
        OnAfterCreateWhseJnlLineFromItemJnlLine(WhseJnlLine, ItemJnlLine);
        WMSManagement.CheckWhseJnlLine(WhseJnlLine, 0, 0, false);
    end;

    local procedure PostResourceConsumption(AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; PostingNoSeries: Code[20]; QtyToConsume: Decimal; QtyToConsumeBase: Decimal; var ResJnlPostLine: Codeunit "Res. Jnl.-Post Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; DocumentNo: Code[20]; IsCorrection: Boolean)
    var
        ItemJnlLine: Record "Item Journal Line";
        ResJnlLine: Record "Res. Journal Line";
        TimeSheetMgt: Codeunit "Time Sheet Management";
    begin
        with AssemblyLine do begin
            TestField(Type, Type::Resource);
            ItemJnlLine.Init();
            ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::"Assembly Output";
            ItemJnlLine."Source Code" := SourceCode;
            ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Posted Assembly";
            ItemJnlLine."Document No." := DocumentNo;
            ItemJnlLine."Document Date" := PostingDate;
            ItemJnlLine."Document Line No." := "Line No.";
            ItemJnlLine."Order Type" := ItemJnlLine."Order Type"::Assembly;
            ItemJnlLine."Order No." := "Document No.";
            ItemJnlLine."Order Line No." := "Line No.";
            ItemJnlLine."Dimension Set ID" := "Dimension Set ID";
            ItemJnlLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
            ItemJnlLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
            ItemJnlLine."Source Type" := ItemJnlLine."Source Type"::Item;
            ItemJnlLine."Source No." := AssemblyHeader."Item No.";

            ItemJnlLine."Posting Date" := PostingDate;
            ItemJnlLine."Posting No. Series" := PostingNoSeries;
            ItemJnlLine.Type := ItemJnlLine.Type::Resource;
            ItemJnlLine."No." := "No.";
            ItemJnlLine."Item No." := AssemblyHeader."Item No.";
            ItemJnlLine."Unit of Measure Code" := AssemblyHeader."Unit of Measure Code";
            ItemJnlLine."Qty. per Unit of Measure" := AssemblyHeader."Qty. per Unit of Measure";

            ItemJnlLine.Validate("Location Code", "Location Code");
            ItemJnlLine."Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";
            ItemJnlLine."Inventory Posting Group" := "Inventory Posting Group";
            ItemJnlLine."Unit Cost" := "Unit Cost";
            ItemJnlLine."Qty. per Cap. Unit of Measure" := "Qty. per Unit of Measure";
            ItemJnlLine."Cap. Unit of Measure Code" := "Unit of Measure Code";
            ItemJnlLine.Description := Description;
            ItemJnlLine.Quantity := QtyToConsume;
            ItemJnlLine."Quantity (Base)" := QtyToConsumeBase;
            ItemJnlLine.Correction := IsCorrection;
        end;
        OnAfterCreateItemJnlLineFromAssemblyLine(ItemJnlLine, AssemblyLine);
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);

        with ItemJnlLine do begin
            ResJnlLine.Init();
            ResJnlLine."Posting Date" := "Posting Date";
            ResJnlLine."Document Date" := "Document Date";
            ResJnlLine."Reason Code" := "Reason Code";
            ResJnlLine."System-Created Entry" := true;
            ResJnlLine.Validate("Resource No.", "No.");
            ResJnlLine.Description := Description;
            ResJnlLine."Unit of Measure Code" := AssemblyLine."Unit of Measure Code";
            ResJnlLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
            ResJnlLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
            ResJnlLine."Dimension Set ID" := "Dimension Set ID";
            ResJnlLine."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
            ResJnlLine."Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";
            ResJnlLine."Entry Type" := ResJnlLine."Entry Type"::Usage;
            ResJnlLine."Document No." := "Document No.";
            ResJnlLine."Order Type" := ResJnlLine."Order Type"::Assembly;
            ResJnlLine."Order No." := "Order No.";
            ResJnlLine."Order Line No." := "Order Line No.";
            ResJnlLine."Line No." := "Document Line No.";
            ResJnlLine."External Document No." := "External Document No.";
            ResJnlLine.Quantity := QtyToConsume;
            ResJnlLine."Unit Cost" := AssemblyLine."Unit Cost";
            ResJnlLine."Total Cost" := AssemblyLine."Unit Cost" * ResJnlLine.Quantity;
            ResJnlLine."Source Code" := "Source Code";
            ResJnlLine."Posting No. Series" := "Posting No. Series";
            ResJnlLine."Qty. per Unit of Measure" := AssemblyLine."Qty. per Unit of Measure";
            OnAfterCreateResJnlLineFromItemJnlLine(ResJnlLine, ItemJnlLine, AssemblyLine);
            ResJnlPostLine.RunWithCheck(ResJnlLine);
        end;

        TimeSheetMgt.CreateTSLineFromAssemblyLine(AssemblyHeader, AssemblyLine, QtyToConsumeBase);
    end;

    local procedure InsertLineItemEntryRelation(var PostedAssemblyLine: Record "Posted Assembly Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; ItemLedgEntryNo: Integer)
    var
        ItemEntryRelation: Record "Item Entry Relation";
        TempItemEntryRelation: Record "Item Entry Relation" temporary;
    begin
        if ItemJnlPostLine.CollectItemEntryRelation(TempItemEntryRelation) then begin
            if TempItemEntryRelation.Find('-') then
                repeat
                    ItemEntryRelation := TempItemEntryRelation;
                    ItemEntryRelation.TransferFieldsPostedAsmLine(PostedAssemblyLine);
                    ItemEntryRelation.Insert();
                until TempItemEntryRelation.Next() = 0;
        end else
            PostedAssemblyLine."Item Shpt. Entry No." := ItemLedgEntryNo;
    end;

    local procedure InsertHeaderItemEntryRelation(var PostedAssemblyHeader: Record "Posted Assembly Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; ItemLedgEntryNo: Integer)
    var
        ItemEntryRelation: Record "Item Entry Relation";
        TempItemEntryRelation: Record "Item Entry Relation" temporary;
    begin
        if ItemJnlPostLine.CollectItemEntryRelation(TempItemEntryRelation) then begin
            if TempItemEntryRelation.Find('-') then
                repeat
                    ItemEntryRelation := TempItemEntryRelation;
                    ItemEntryRelation.TransferFieldsPostedAsmHeader(PostedAssemblyHeader);
                    ItemEntryRelation.Insert();
                until TempItemEntryRelation.Next() = 0;
        end else
            PostedAssemblyHeader."Item Rcpt. Entry No." := ItemLedgEntryNo;
    end;

    procedure Undo(var PostedAsmHeader: Record "Posted Assembly Header"; RecreateAsmOrder: Boolean)
    var
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
    begin
        ClearAll;

        Window.Open(
          '#1#################################\\' +
          Text007 + '\\' +
          StrSubstNo(Text010, PostedAsmHeader."No."));

        ShowProgress := true;
        Window.Update(1, StrSubstNo('%1 %2', PostedAsmHeader.TableCaption, PostedAsmHeader."No."));

        PostedAsmHeader.CheckIsNotAsmToOrder;

        UndoInitPost(PostedAsmHeader);
        UndoPost(PostedAsmHeader, ItemJnlPostLine, ResJnlPostLine, WhseJnlRegisterLine);
        UndoFinalizePost(PostedAsmHeader, RecreateAsmOrder);

        if not SuppressCommit then
            Commit();

        Window.Close;
    end;

    local procedure UndoInitPost(var PostedAsmHeader: Record "Posted Assembly Header")
    begin
        with PostedAsmHeader do begin
            PostingDate := "Posting Date";

            CheckPossibleToUndo(PostedAsmHeader);

            GetSourceCode(IsAsmToOrder);

            TempItemLedgEntry.Reset();
            TempItemLedgEntry.DeleteAll();
        end;

        OnAfterUndoInitPost(PostedAsmHeader);
    end;

    local procedure UndoFinalizePost(var PostedAsmHeader: Record "Posted Assembly Header"; RecreateAsmOrder: Boolean)
    var
        AsmHeader: Record "Assembly Header";
    begin
        MakeInvtAdjmt;

        if AsmHeader.Get(AsmHeader."Document Type"::Order, PostedAsmHeader."Order No.") then
            UpdateAsmOrderWithUndo(PostedAsmHeader)
        else
            if RecreateAsmOrder then
                RecreateAsmOrderWithUndo(PostedAsmHeader);
    end;

    local procedure UndoPost(var PostedAsmHeader: Record "Posted Assembly Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var ResJnlPostLine: Codeunit "Res. Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    begin
        AssembledItem.Get(PostedAsmHeader."Item No.");
        UndoPostHeader(PostedAsmHeader, ItemJnlPostLine, WhseJnlRegisterLine);
        UndoPostLines(PostedAsmHeader, ItemJnlPostLine, ResJnlPostLine, WhseJnlRegisterLine);

        OnAfterUndoPost(PostedAsmHeader, SuppressCommit);
    end;

    local procedure UndoPostLines(PostedAsmHeader: Record "Posted Assembly Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var ResJnlPostLine: Codeunit "Res. Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    var
        PostedAsmLine: Record "Posted Assembly Line";
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        LineCounter: Integer;
    begin
        AsmHeader.TransferFields(PostedAsmHeader);
        AsmHeader."Document Type" := AsmHeader."Document Type"::Order;
        AsmHeader."No." := PostedAsmHeader."Order No.";

        with PostedAsmLine do begin
            Reset;
            SetRange("Document No.", PostedAsmHeader."No.");
            SortPostedLines(PostedAsmLine);

            LineCounter := 0;
            if FindSet() then
                repeat
                    AsmLine.TransferFields(PostedAsmLine);
                    OnUndoPostLinesOnAfterTransferFields(AsmLine, AsmHeader, PostedAsmHeader);
                    AsmLine."Document Type" := AsmHeader."Document Type"::Order;
                    AsmLine."Document No." := PostedAsmHeader."Order No.";

                    LineCounter := LineCounter + 1;
                    if ShowProgress then
                        Window.Update(2, LineCounter);

                    if "Quantity (Base)" <> 0 then begin
                        case Type of
                            Type::Item:
                                PostItemConsumption(
                                  AsmHeader,
                                  AsmLine,
                                  PostedAsmHeader."No. Series",
                                  -Quantity,
                                  -"Quantity (Base)", ItemJnlPostLine, WhseJnlRegisterLine, "Document No.", true, "Item Shpt. Entry No.");
                            Type::Resource:
                                PostResourceConsumption(
                                  AsmHeader,
                                  AsmLine,
                                  PostedAsmHeader."No. Series",
                                  -Quantity,
                                  -"Quantity (Base)",
                                  ResJnlPostLine, ItemJnlPostLine, "Document No.", true);
                        end;
                        InsertLineItemEntryRelation(PostedAsmLine, ItemJnlPostLine, 0);

                        Modify();
                    end;
                until Next() = 0;
        end;
    end;

    local procedure UndoPostHeader(var PostedAsmHeader: Record "Posted Assembly Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    var
        AsmHeader: Record "Assembly Header";
    begin
        with PostedAsmHeader do begin
            AsmHeader.TransferFields(PostedAsmHeader);
            OnUndoPostHeaderOnAfterTransferFields(AsmHeader, PostedAsmHeader);
            AsmHeader."Document Type" := AsmHeader."Document Type"::Order;
            AsmHeader."No." := "Order No.";

            PostItemOutput(
              AsmHeader, "No. Series", -Quantity, -"Quantity (Base)", ItemJnlPostLine, WhseJnlRegisterLine, "No.", true, "Item Rcpt. Entry No.");
            InsertHeaderItemEntryRelation(PostedAsmHeader, ItemJnlPostLine, 0);

            Reversed := true;
            Modify();
        end;
    end;

    local procedure SumCapQtyPosted(OrderNo: Code[20]; OrderLineNo: Integer): Decimal
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
    begin
        with CapLedgEntry do begin
            SetCurrentKey("Order Type", "Order No.", "Order Line No.");
            SetRange("Order Type", "Order Type"::Assembly);
            SetRange("Order No.", OrderNo);
            SetRange("Order Line No.", OrderLineNo);
            CalcSums(Quantity);
            exit(Quantity);
        end;
    end;

    local procedure SumItemQtyPosted(OrderNo: Code[20]; OrderLineNo: Integer): Decimal
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        with ItemLedgEntry do begin
            SetCurrentKey("Order Type", "Order No.", "Order Line No.");
            SetRange("Order Type", "Order Type"::Assembly);
            SetRange("Order No.", OrderNo);
            SetRange("Order Line No.", OrderLineNo);
            CalcSums(Quantity);
            exit(Quantity);
        end;
    end;

    local procedure UpdateAsmOrderWithUndo(var PostedAsmHeader: Record "Posted Assembly Header")
    var
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        PostedAsmLine: Record "Posted Assembly Line";
    begin
        with AsmHeader do begin
            Get("Document Type"::Order, PostedAsmHeader."Order No.");
            "Assembled Quantity" -= PostedAsmHeader.Quantity;
            "Assembled Quantity (Base)" -= PostedAsmHeader."Quantity (Base)";
            InitRemainingQty();
            InitQtyToAssemble();
            Modify();

            RestoreItemTracking(TempItemLedgEntry, "No.", 0, DATABASE::"Assembly Header", "Document Type", "Due Date", 0D);
            VerifyAsmHeaderReservAfterUndo(AsmHeader);
        end;

        PostedAsmLine.SetRange("Document No.", PostedAsmHeader."No.");
        PostedAsmLine.SetFilter("Quantity (Base)", '<>0');
        if PostedAsmLine.FindSet() then
            repeat
                with AsmLine do begin
                    Get(AsmHeader."Document Type", AsmHeader."No.", PostedAsmLine."Line No.");
                    "Consumed Quantity" -= PostedAsmLine.Quantity;
                    "Consumed Quantity (Base)" -= PostedAsmLine."Quantity (Base)";
                    if "Qty. Picked (Base)" <> 0 then begin
                        "Qty. Picked" -= PostedAsmLine.Quantity;
                        "Qty. Picked (Base)" -= PostedAsmLine."Quantity (Base)";
                    end;

                    InitRemainingQty();
                    InitQtyToConsume();
                    Modify();

                    RestoreItemTracking(TempItemLedgEntry, "Document No.", "Line No.", DATABASE::"Assembly Line", "Document Type", 0D, "Due Date");
                    VerifyAsmLineReservAfterUndo(AsmLine);
                end;
            until PostedAsmLine.Next() = 0;

        OnAfterUpdateAsmOrderWithUndo(PostedAsmHeader, AsmHeader);
    end;

    local procedure RecreateAsmOrderWithUndo(var PostedAsmHeader: Record "Posted Assembly Header")
    var
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        PostedAsmLine: Record "Posted Assembly Line";
        AsmCommentLine: Record "Assembly Comment Line";
    begin
        with AsmHeader do begin
            Init();
            TransferFields(PostedAsmHeader);
            "Document Type" := "Document Type"::Order;
            "No." := PostedAsmHeader."Order No.";

            "Assembled Quantity (Base)" := SumItemQtyPosted("No.", 0);
            "Assembled Quantity" := Round("Assembled Quantity (Base)" / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
            Quantity := PostedAsmHeader.Quantity + "Assembled Quantity";
            "Quantity (Base)" := PostedAsmHeader."Quantity (Base)" + "Assembled Quantity (Base)";
            InitRemainingQty();
            InitQtyToAssemble();

            OnBeforeRecreatedAsmHeaderInsert(AsmHeader, PostedAsmHeader);
            Insert();

            CopyCommentLines(
              AsmCommentLine."Document Type"::"Posted Assembly", "Document Type",
              PostedAsmHeader."No.", "No.");

            RestoreItemTracking(TempItemLedgEntry, "No.", 0, DATABASE::"Assembly Header", "Document Type", "Due Date", 0D);
            VerifyAsmHeaderReservAfterUndo(AsmHeader);
        end;

        PostedAsmLine.SetRange("Document No.", PostedAsmHeader."No.");
        if PostedAsmLine.FindSet() then
            repeat
                with AsmLine do begin
                    Init();
                    TransferFields(PostedAsmLine);
                    "Document Type" := "Document Type"::Order;
                    "Document No." := PostedAsmLine."Order No.";
                    "Line No." := PostedAsmLine."Order Line No.";

                    if PostedAsmLine."Quantity (Base)" <> 0 then begin
                        if Type = Type::Item then
                            "Consumed Quantity (Base)" := -SumItemQtyPosted("Document No.", "Line No.")
                        else
                            "Consumed Quantity (Base)" := SumCapQtyPosted("Document No.", "Line No.");

                        "Consumed Quantity" := Round("Consumed Quantity (Base)" / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
                        Quantity := PostedAsmLine.Quantity + "Consumed Quantity";
                        "Quantity (Base)" := PostedAsmLine."Quantity (Base)" + "Consumed Quantity (Base)";
                        "Cost Amount" := CalcCostAmount(Quantity, "Unit Cost");
                        if Type = Type::Item then begin
                            "Qty. Picked" := "Consumed Quantity";
                            "Qty. Picked (Base)" := "Consumed Quantity (Base)";
                        end;
                        InitRemainingQty();
                        InitQtyToConsume();
                    end;
                    Insert();

                    RestoreItemTracking(TempItemLedgEntry, "Document No.", "Line No.", DATABASE::"Assembly Line", "Document Type", 0D, "Due Date");
                    VerifyAsmLineReservAfterUndo(AsmLine);
                end;
            until PostedAsmLine.Next() = 0;

        OnAfterRecreateAsmOrderWithUndo(PostedAsmHeader, AsmHeader);
    end;

    local procedure VerifyAsmHeaderReservAfterUndo(var AsmHeader: Record "Assembly Header")
    var
        xAsmHeader: Record "Assembly Header";
        AsmHeaderReserve: Codeunit "Assembly Header-Reserve";
    begin
        xAsmHeader := AsmHeader;
        xAsmHeader."Quantity (Base)" := 0;
        AsmHeaderReserve.VerifyQuantity(AsmHeader, xAsmHeader);
    end;

    local procedure VerifyAsmLineReservAfterUndo(var AsmLine: Record "Assembly Line")
    var
        xAsmLine: Record "Assembly Line";
        AsmLineReserve: Codeunit "Assembly Line-Reserve";
    begin
        xAsmLine := AsmLine;
        xAsmLine."Quantity (Base)" := 0;
        AsmLineReserve.VerifyQuantity(AsmLine, xAsmLine);
    end;

    local procedure GetSourceCode(IsATO: Boolean)
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        if IsATO then
            SourceCode := SourceCodeSetup.Sales
        else
            SourceCode := SourceCodeSetup.Assembly;
    end;

    local procedure CheckPossibleToUndo(PostedAsmHeader: Record "Posted Assembly Header"): Boolean
    var
        AsmHeader: Record "Assembly Header";
        PostedAsmLine: Record "Posted Assembly Line";
        AsmLine: Record "Assembly Line";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
    begin
        with PostedAsmHeader do begin
            TestField(Reversed, false);
            UndoPostingMgt.TestAsmHeader(PostedAsmHeader);
            UndoPostingMgt.CollectItemLedgEntries(
              TempItemLedgEntry, DATABASE::"Posted Assembly Header", "No.", 0, "Quantity (Base)", "Item Rcpt. Entry No.");
            UndoPostingMgt.CheckItemLedgEntries(TempItemLedgEntry, 0);
        end;

        with PostedAsmLine do begin
            SetRange("Document No.", PostedAsmHeader."No.");
            repeat
                if (Type = Type::Item) and ("Item Shpt. Entry No." <> 0) then begin
                    UndoPostingMgt.TestAsmLine(PostedAsmLine);
                    UndoPostingMgt.CollectItemLedgEntries(
                      TempItemLedgEntry, DATABASE::"Posted Assembly Line", "Document No.", "Line No.", "Quantity (Base)", "Item Shpt. Entry No.");
                    UndoPostingMgt.CheckItemLedgEntries(TempItemLedgEntry, "Line No.");
                end;
            until Next() = 0;
        end;

        if not AsmHeader.Get(AsmHeader."Document Type"::Order, PostedAsmHeader."Order No.") then
            exit(true);

        with AsmHeader do begin
            TestField("Variant Code", PostedAsmHeader."Variant Code");
            TestField("Location Code", PostedAsmHeader."Location Code");
            TestField("Bin Code", PostedAsmHeader."Bin Code");
        end;

        with AsmLine do begin
            SetRange("Document Type", AsmHeader."Document Type");
            SetRange("Document No.", AsmHeader."No.");

            if PostedAsmLine.Count <> Count then
                Error(Text011, PostedAsmHeader."No.", AsmHeader."No.");

            FindSet();
            PostedAsmLine.FindSet();
            repeat
                TestField(Type, PostedAsmLine.Type);
                TestField("No.", PostedAsmLine."No.");
                TestField("Variant Code", PostedAsmLine."Variant Code");
                TestField("Location Code", PostedAsmLine."Location Code");
                TestField("Bin Code", PostedAsmLine."Bin Code");
            until (PostedAsmLine.Next() = 0) and (Next() = 0);
        end;
    end;

    local procedure RestoreItemTracking(var ItemLedgEntry: Record "Item Ledger Entry"; OrderNo: Code[20]; OrderLineNo: Integer; SourceType: Integer; DocType: Option; RcptDate: Date; ShptDate: Date)
    var
        AsmHeader: Record "Assembly Header";
        ReservEntry: Record "Reservation Entry";
        ATOLink: Record "Assemble-to-Order Link";
        SalesLine: Record "Sales Line";
        FromTrackingSpecification: Record "Tracking Specification";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        IsATOHeader: Boolean;
        ReservStatus: Enum "Reservation Status";
    begin
        with ItemLedgEntry do begin
            AsmHeader.Get(AsmHeader."Document Type"::Order, OrderNo);
            IsATOHeader := (OrderLineNo = 0) and AsmHeader.IsAsmToOrder;

            Reset;
            SetRange("Order Type", "Order Type"::Assembly);
            SetRange("Order No.", OrderNo);
            SetRange("Order Line No.", OrderLineNo);
            if FindSet() then
                repeat
                    if TrackingExists then begin
                        CreateReservEntry.SetDates("Warranty Date", "Expiration Date");
                        CreateReservEntry.SetQtyToHandleAndInvoice(Quantity, Quantity);
                        CreateReservEntry.SetItemLedgEntryNo("Entry No.");
                        CreateReservEntry.CreateReservEntryFor(
                          SourceType, DocType, "Order No.", '', 0, "Order Line No.",
                          "Qty. per Unit of Measure", 0, Abs(Quantity),
                          "Serial No.", "Lot No.");

                        if IsATOHeader then begin
                            ATOLink.Get(AsmHeader."Document Type", AsmHeader."No.");
                            ATOLink.TestField(Type, ATOLink.Type::Sale);
                            SalesLine.Get(ATOLink."Document Type", ATOLink."Document No.", ATOLink."Document Line No.");

                            CreateReservEntry.SetDisallowCancellation(true);
                            CreateReservEntry.SetBinding(ReservEntry.Binding::"Order-to-Order");

                            FromTrackingSpecification.InitFromSalesLine(SalesLine);
                            FromTrackingSpecification."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
                            FromTrackingSpecification.CopyTrackingFromItemLedgEntry(ItemLedgEntry);
                            CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
                            ReservStatus := ReservStatus::Reservation;
                        end else
                            ReservStatus := ReservStatus::Surplus;
                        CreateReservEntry.CreateEntry(
                          "Item No.", "Variant Code", "Location Code", '', RcptDate, ShptDate, 0, ReservStatus);
                    end;
                until Next() = 0;
            DeleteAll();
        end;
    end;

    procedure InitPostATO(var AssemblyHeader: Record "Assembly Header")
    begin
        if AssemblyHeader.IsAsmToOrder then
            InitPost(AssemblyHeader);
    end;

    procedure PostATO(var AssemblyHeader: Record "Assembly Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var ResJnlPostLine: Codeunit "Res. Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    begin
        if AssemblyHeader.IsAsmToOrder then
            Post(AssemblyHeader, ItemJnlPostLine, ResJnlPostLine, WhseJnlRegisterLine, true);
    end;

    procedure FinalizePostATO(var AssemblyHeader: Record "Assembly Header")
    begin
        if AssemblyHeader.IsAsmToOrder then
            FinalizePost(AssemblyHeader);
    end;

    procedure UndoInitPostATO(var PostedAsmHeader: Record "Posted Assembly Header")
    begin
        if PostedAsmHeader.IsAsmToOrder then
            UndoInitPost(PostedAsmHeader);
    end;

    procedure UndoPostATO(var PostedAsmHeader: Record "Posted Assembly Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var ResJnlPostLine: Codeunit "Res. Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    begin
        if PostedAsmHeader.IsAsmToOrder then
            UndoPost(PostedAsmHeader, ItemJnlPostLine, ResJnlPostLine, WhseJnlRegisterLine);
    end;

    procedure UndoFinalizePostATO(var PostedAsmHeader: Record "Posted Assembly Header")
    begin
        if PostedAsmHeader.IsAsmToOrder then
            UndoFinalizePost(PostedAsmHeader, false);
    end;

    local procedure MakeInvtAdjmt()
    var
        InvtSetup: Record "Inventory Setup";
        InvtAdjmt: Codeunit "Inventory Adjustment";
    begin
        InvtSetup.Get();
        if InvtSetup."Automatic Cost Adjustment" <>
           InvtSetup."Automatic Cost Adjustment"::Never
        then begin
            InvtAdjmt.SetProperties(true, InvtSetup."Automatic Cost Posting");
            InvtAdjmt.MakeMultiLevelAdjmt();
        end;
    end;

    local procedure DeleteWhseRequest(AssemblyHeader: Record "Assembly Header")
    var
        WhseRqst: Record "Warehouse Request";
    begin
        with WhseRqst do begin
            SetCurrentKey("Source Type", "Source Subtype", "Source No.");
            SetRange("Source Type", DATABASE::"Assembly Line");
            SetRange("Source Subtype", AssemblyHeader."Document Type");
            SetRange("Source No.", AssemblyHeader."No.");
            if not IsEmpty() then
                DeleteAll(true);
        end;
    end;

    procedure UpdateBlanketATO(xBlanketOrderSalesLine: Record "Sales Line"; BlanketOrderSalesLine: Record "Sales Line")
    var
        AsmHeader: Record "Assembly Header";
        QuantityDiff: Decimal;
        QuantityDiffBase: Decimal;
    begin
        if BlanketOrderSalesLine.AsmToOrderExists(AsmHeader) then begin
            QuantityDiff := BlanketOrderSalesLine."Quantity Shipped" - xBlanketOrderSalesLine."Quantity Shipped";
            QuantityDiffBase := BlanketOrderSalesLine."Qty. Shipped (Base)" - xBlanketOrderSalesLine."Qty. Shipped (Base)";

            with AsmHeader do begin
                "Assembled Quantity" += QuantityDiff;
                "Assembled Quantity (Base)" += QuantityDiffBase;
                InitRemainingQty();
                InitQtyToAssemble();
                Modify(true);
            end;
            UpdateBlanketATOLines(AsmHeader, QuantityDiff);
        end;
    end;

    local procedure UpdateBlanketATOLines(AsmHeader: Record "Assembly Header"; QuantityDiff: Decimal)
    var
        AsmLine: Record "Assembly Line";
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        with AsmLine do begin
            SetRange("Document Type", AsmHeader."Document Type");
            SetRange("Document No.", AsmHeader."No.");
            if FindSet() then
                repeat
                    "Consumed Quantity" += UOMMgt.RoundQty(QuantityDiff * "Quantity per");
                    "Consumed Quantity (Base)" +=
                      UOMMgt.CalcBaseQty(
                        "No.", "Variant Code", "Unit of Measure Code",
                        QuantityDiff * "Quantity per", "Qty. per Unit of Measure");
                    InitRemainingQty();
                    InitQtyToConsume();
                    Modify(true);
                until Next() = 0;
        end;
    end;

    local procedure UpdateItemCategoryAndGroupCode(var ItemJnlLine: Record "Item Journal Line")
    var
        Item: Record Item;
    begin
        Item.Get(ItemJnlLine."Item No.");
        ItemJnlLine."Item Category Code" := Item."Item Category Code";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateItemJnlLineFromAssemblyHeader(var ItemJournalLine: Record "Item Journal Line"; AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateItemJnlLineFromAssemblyLine(var ItemJournalLine: Record "Item Journal Line"; AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateResJnlLineFromItemJnlLine(var ResJournalLine: Record "Res. Journal Line"; ItemJournalLine: Record "Item Journal Line"; AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseJnlLineFromItemJnlLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinalizePost(var AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitPost(var AssemblyHeader: Record "Assembly Header"; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var AssemblyHeader: Record "Assembly Header"; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPost(var AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostedAssemblyLineInsert(var PostedAssemblyLine: Record "Posted Assembly Line"; AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostedAssemblyHeaderModify(var PostedAssemblyHeader: Record "Posted Assembly Header"; AssemblyHeader: Record "Assembly Header"; ItemLedgEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecreateAsmOrderWithUndo(var PostedAssemblyHeader: Record "Posted Assembly Header"; var AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUndoInitPost(var PostedAssemblyHeader: Record "Posted Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUndoPost(var PostedAssemblyHeader: Record "Posted Assembly Header"; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAsmOrderWithUndo(var PostedAssemblyHeader: Record "Posted Assembly Header"; var AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssemblyLineModify(var AssemblyLine: Record "Assembly Line"; QtyToConsumeBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinalizePost(var AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitPost(var AssemblyHeader: Record "Assembly Header"; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var AssemblyHeader: Record "Assembly Header"; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePost(var AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCorrectionItemJnLine(var ItemJournalLine: Record "Item Journal Line"; var TempItemLedgEntry: Record "Item Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemConsumption(var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedAssemblyLineInsert(var PostedAssemblyLine: Record "Posted Assembly Line"; AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecreatedAsmHeaderInsert(var AssemblyHeader: Record "Assembly Header"; PostedAssemblyHeader: Record "Posted Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOnAfterCopyComments(AssemblyHeader: Record "Assembly Header"; PostedAssemblyHeader: Record "Posted Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoPostHeaderOnAfterTransferFields(var AssemblyHeader: Record "Assembly Header"; PostedAssemblyHeader: Record "Posted Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoPostLinesOnAfterTransferFields(var AssemblyLine: Record "Assembly Line"; AssemblyHeader: Record "Assembly Header"; PostedAssemblyHeader: Record "Posted Assembly Header")
    begin
    end;
}

