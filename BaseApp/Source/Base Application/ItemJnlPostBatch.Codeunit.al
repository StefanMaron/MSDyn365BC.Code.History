codeunit 23 "Item Jnl.-Post Batch"
{
    Permissions = TableData "Item Journal Batch" = imd,
                  TableData "Warehouse Register" = r;
    TableNo = "Item Journal Line";

    trigger OnRun()
    begin
        ItemJnlLine.Copy(Rec);
        ItemJnlLine.SetAutoCalcFields;
        Code;
        Rec := ItemJnlLine;
    end;

    var
        Text001: Label 'Journal Batch Name    #1##########\\';
        Text002: Label 'Checking lines        #2######\';
        Text003: Label 'Posting lines         #3###### @4@@@@@@@@@@@@@\';
        Text004: Label 'Updating lines        #5###### @6@@@@@@@@@@@@@';
        Text005: Label 'Posting lines         #3###### @4@@@@@@@@@@@@@';
        Text006: Label 'A maximum of %1 posting number series can be used in each journal.';
        Text007: Label '<Month Text>', Locked = true;
        Text008: Label 'There are new postings made in the period you want to revalue item no. %1.\';
        Text009: Label 'You must calculate the inventory value again.';
        Text010: Label 'One or more reservation entries exist for the item with %1 = %2, %3 = %4, %5 = %6 which may be disrupted if you post this negative adjustment. Do you want to continue?', Comment = 'One or more reservation entries exist for the item with Item No. = 1000, Location Code = BLUE, Variant Code = NEW which may be disrupted if you post this negative adjustment. Do you want to continue?';
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        WhseEntry: Record "Warehouse Entry";
        ItemReg: Record "Item Register";
        WhseReg: Record "Warehouse Register";
        GLSetup: Record "General Ledger Setup";
        InvtSetup: Record "Inventory Setup";
        AccountingPeriod: Record "Accounting Period";
        NoSeries: Record "No. Series" temporary;
        Location: Record Location;
        ItemJnlCheckLine: Codeunit "Item Jnl.-Check Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        NoSeriesMgt2: array[10] of Codeunit NoSeriesManagement;
        WMSMgmt: Codeunit "WMS Management";
        WhseJnlPostLine: Codeunit "Whse. Jnl.-Register Line";
        InvtAdjmt: Codeunit "Inventory Adjustment";
        Window: Dialog;
        ItemRegNo: Integer;
        WhseRegNo: Integer;
        StartLineNo: Integer;
        Day: Integer;
        Week: Integer;
        Month: Integer;
        MonthText: Text[30];
        NoOfRecords: Integer;
        LineCount: Integer;
        LastDocNo: Code[20];
        LastDocNo2: Code[20];
        LastPostedDocNo: Code[20];
        NoOfPostingNoSeries: Integer;
        PostingNoSeriesNo: Integer;
        WhseTransaction: Boolean;
        PhysInvtCount: Boolean;
        SuppressCommit: Boolean;

    local procedure "Code"()
    var
        UpdateAnalysisView: Codeunit "Update Analysis View";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        PhysInvtCountMgt: Codeunit "Phys. Invt. Count.-Management";
        OldEntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output," ","Assembly Consumption","Assembly Output";
        RaiseError: Boolean;
    begin
        OnBeforeCode(ItemJnlLine);

        with ItemJnlLine do begin
            LockTable();
            SetRange("Journal Template Name", "Journal Template Name");
            SetRange("Journal Batch Name", "Journal Batch Name");

            ItemJnlTemplate.Get("Journal Template Name");
            ItemJnlBatch.Get("Journal Template Name", "Journal Batch Name");

            OnBeforeRaiseExceedLengthError(ItemJnlBatch, RaiseError);

            if ItemJnlTemplate.Recurring then begin
                SetRange("Posting Date", 0D, WorkDate);
                SetFilter("Expiration Date", '%1 | %2..', 0D, WorkDate);
            end;

            if not Find('=><') then begin
                "Line No." := 0;
                if not SuppressCommit then
                    Commit();
                exit;
            end;

            CheckItemAvailability(ItemJnlLine);

            if ItemJnlTemplate.Recurring then
                Window.Open(
                  Text001 +
                  Text002 +
                  Text003 +
                  Text004)
            else
                Window.Open(
                  Text001 +
                  Text002 +
                  Text005);

            Window.Update(1, "Journal Batch Name");

            CheckLines(ItemJnlLine);

            // Find next register no.
            ItemLedgEntry.LockTable();
            if ItemLedgEntry.FindLast then;
            if WhseTransaction then begin
                WhseEntry.LockTable();
                if WhseEntry.FindLast then;
            end;

            ItemReg.LockTable();
            ItemRegNo := ItemReg.GetLastEntryNo() + 1;

            WhseReg.LockTable();
            WhseRegNo := WhseReg.GetLastEntryNo() + 1;

            GLSetup.Get();
            PhysInvtCount := false;

            // Post lines
            LineCount := 0;
            OldEntryType := "Entry Type";
            PostLines(ItemJnlLine, PhysInvtCountMgt);

            // Copy register no. and current journal batch name to item journal
            if not ItemReg.FindLast or (ItemReg."No." <> ItemRegNo) then
                ItemRegNo := 0;
            if not WhseReg.FindLast or (WhseReg."No." <> WhseRegNo) then
                WhseRegNo := 0;

            OnAfterCopyRegNos(ItemJnlLine, ItemRegNo, WhseRegNo);

            Init;

            "Line No." := ItemRegNo;
            if "Line No." = 0 then
                "Line No." := WhseRegNo;

            InvtSetup.Get();
            if InvtSetup."Automatic Cost Adjustment" <>
               InvtSetup."Automatic Cost Adjustment"::Never
            then begin
                InvtAdjmt.SetProperties(true, InvtSetup."Automatic Cost Posting");
                InvtAdjmt.MakeMultiLevelAdjmt;
            end;

            // Update/delete lines
            OnBeforeUpdateDeleteLines(ItemJnlLine, ItemRegNo);
            if "Line No." <> 0 then begin
                if ItemJnlTemplate.Recurring then begin
                    HandleRecurringLine(ItemJnlLine);
                end else
                    HandleNonRecurringLine(ItemJnlLine, OldEntryType);
                if ItemJnlBatch."No. Series" <> '' then
                    NoSeriesMgt.SaveNoSeries;
                if NoSeries.FindSet then
                    repeat
                        Evaluate(PostingNoSeriesNo, NoSeries.Description);
                        NoSeriesMgt2[PostingNoSeriesNo].SaveNoSeries;
                    until NoSeries.Next = 0;
            end;

            if PhysInvtCount then
                PhysInvtCountMgt.UpdateItemSKUListPhysInvtCount;

            OnAfterPostJnlLines(ItemJnlBatch, ItemJnlLine, ItemRegNo, WhseRegNo);

            Window.Close;
            if not SuppressCommit then
                Commit();
            Clear(ItemJnlCheckLine);
            Clear(ItemJnlPostLine);
            Clear(WhseJnlPostLine);
            Clear(InvtAdjmt)
        end;
        UpdateAnalysisView.UpdateAll(0, true);
        UpdateItemAnalysisView.UpdateAll(0, true);

        OnAfterUpdateAnalysisViews(ItemReg);

        if not SuppressCommit then
            Commit();
    end;

    local procedure CheckLines(var ItemJnlLine: Record "Item Journal Line")
    begin
        OnBeforeCheckLines(ItemJnlLine);

        with ItemJnlLine do begin
            LineCount := 0;
            StartLineNo := "Line No.";
            repeat
                LineCount := LineCount + 1;
                Window.Update(2, LineCount);
                CheckRecurringLine(ItemJnlLine);

                if (("Value Entry Type" = "Value Entry Type"::"Direct Cost") and ("Item Charge No." = '')) or
                   (("Invoiced Quantity" <> 0) and (Amount <> 0))
                then begin
                    ItemJnlCheckLine.RunCheck(ItemJnlLine);

                    if (Quantity <> 0) and
                       ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
                       ("Item Charge No." = '')
                    then
                        CheckWMSBin(ItemJnlLine);

                    if ("Value Entry Type" = "Value Entry Type"::Revaluation) and
                       ("Inventory Value Per" = "Inventory Value Per"::" ") and
                       "Partial Revaluation"
                    then
                        CheckRemainingQty;

                    OnAfterCheckJnlLine(ItemJnlLine, SuppressCommit);
                end;

                if Next = 0 then
                    FindFirst;
            until "Line No." = StartLineNo;
            NoOfRecords := LineCount;
        end;

        OnAfterCheckLines(ItemJnlLine);
    end;

    local procedure PostLines(var ItemJnlLine: Record "Item Journal Line"; var PhysInvtCountMgt: Codeunit "Phys. Invt. Count.-Management")
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        OriginalQuantity: Decimal;
        OriginalQuantityBase: Decimal;
    begin
        LastDocNo := '';
        LastDocNo2 := '';
        LastPostedDocNo := '';
        with ItemJnlLine do begin
            SetCurrentKey("Journal Template Name", "Journal Batch Name", "Line No.");
            FindSet;
            repeat
                if not EmptyLine and
                   (ItemJnlBatch."No. Series" <> '') and
                   ("Document No." <> LastDocNo2)
                then
                    TestField("Document No.", NoSeriesMgt.GetNextNo(ItemJnlBatch."No. Series", "Posting Date", false));
                if not EmptyLine then
                    LastDocNo2 := "Document No.";
                MakeRecurringTexts(ItemJnlLine);
                ConstructPostingNumber(ItemJnlLine);

                OnPostLinesOnBeforePostLine(ItemJnlLine, SuppressCommit);

                if "Inventory Value Per" <> "Inventory Value Per"::" " then
                    ItemJnlPostSumLine(ItemJnlLine)
                else
                    if (("Value Entry Type" = "Value Entry Type"::"Direct Cost") and ("Item Charge No." = '')) or
                       (("Invoiced Quantity" <> 0) and (Amount <> 0))
                    then begin
                        LineCount := LineCount + 1;
                        Window.Update(3, LineCount);
                        Window.Update(4, Round(LineCount / NoOfRecords * 10000, 1));
                        OriginalQuantity := Quantity;
                        OriginalQuantityBase := "Quantity (Base)";
                        if not ItemJnlPostLine.RunWithCheck(ItemJnlLine) then
                            ItemJnlPostLine.CheckItemTracking;
                        if "Value Entry Type" <> "Value Entry Type"::Revaluation then begin
                            ItemJnlPostLine.CollectTrackingSpecification(TempTrackingSpecification);
                            OnPostLinesBeforePostWhseJnlLine(ItemJnlLine, SuppressCommit);
                            PostWhseJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase, TempTrackingSpecification);
                            OnPostLinesOnAfterPostWhseJnlLine(ItemJnlLine, SuppressCommit);
                        end;
                    end;

                if IsPhysInvtCount(ItemJnlTemplate, "Phys Invt Counting Period Code", "Phys Invt Counting Period Type") then begin
                    if not PhysInvtCount then begin
                        PhysInvtCountMgt.InitTempItemSKUList;
                        PhysInvtCount := true;
                    end;
                    PhysInvtCountMgt.AddToTempItemSKUList("Item No.", "Location Code", "Variant Code", "Phys Invt Counting Period Type");
                end;
            until Next = 0;
        end;

        OnAfterPostLines(ItemJnlLine, ItemRegNo);
    end;

    local procedure HandleRecurringLine(var ItemJnlLine: Record "Item Journal Line")
    var
        ItemJnlLine2: Record "Item Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHandleRecurringLine(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        LineCount := 0;
        ItemJnlLine2.CopyFilters(ItemJnlLine);
        ItemJnlLine2.FindSet;
        repeat
            LineCount := LineCount + 1;
            Window.Update(5, LineCount);
            Window.Update(6, Round(LineCount / NoOfRecords * 10000, 1));
            if ItemJnlLine2."Posting Date" <> 0D then
                ItemJnlLine2.Validate("Posting Date", CalcDate(ItemJnlLine2."Recurring Frequency", ItemJnlLine2."Posting Date"));
            if (ItemJnlLine2."Recurring Method" = ItemJnlLine2."Recurring Method"::Variable) and
               (ItemJnlLine2."Item No." <> '')
            then begin
                ItemJnlLine2.Quantity := 0;
                ItemJnlLine2."Invoiced Quantity" := 0;
                ItemJnlLine2.Amount := 0;
                OnHandleRecurringLineOnBeforeModify(ItemJnlLine2);
            end;
            ItemJnlLine2.Modify();
        until ItemJnlLine2.Next = 0;
    end;

    local procedure HandleNonRecurringLine(var ItemJnlLine: Record "Item Journal Line"; OldEntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output," ","Assembly Consumption","Assembly Output")
    var
        ItemJnlLine2: Record "Item Journal Line";
        ItemJnlLine3: Record "Item Journal Line";
        IncrBatchName: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHandleNonRecurringLine(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        with ItemJnlLine do begin
            ItemJnlLine2.CopyFilters(ItemJnlLine);
            ItemJnlLine2.SetFilter("Item No.", '<>%1', '');
            if ItemJnlLine2.FindLast then; // Remember the last line
            ItemJnlLine2."Entry Type" := OldEntryType;

            ItemJnlLine3.Copy(ItemJnlLine);
            ItemJnlLine3.DeleteAll();
            ItemJnlLine3.Reset();
            ItemJnlLine3.SetRange("Journal Template Name", "Journal Template Name");
            ItemJnlLine3.SetRange("Journal Batch Name", "Journal Batch Name");
            if ItemJnlTemplate."Increment Batch Name" then
                if not ItemJnlLine3.FindLast then begin
                    IncrBatchName := IncStr("Journal Batch Name") <> '';
                    OnBeforeIncrBatchName(ItemJnlLine, IncrBatchName);
                    if IncrBatchName then begin
                        ItemJnlBatch.Delete();
                        ItemJnlBatch.Name := IncStr("Journal Batch Name");
                        if ItemJnlBatch.Insert() then;
                        "Journal Batch Name" := ItemJnlBatch.Name;
                    end;
                end;

            OnHandleNonRecurringLineOnInsertNewLine(ItemJnlLine3);

            ItemJnlLine3.SetRange("Journal Batch Name", "Journal Batch Name");
            if (ItemJnlBatch."No. Series" = '') and not ItemJnlLine3.FindLast and
               not (ItemJnlLine2."Entry Type" in [ItemJnlLine2."Entry Type"::Consumption, ItemJnlLine2."Entry Type"::Output])
            then begin
                ItemJnlLine3.Init();
                ItemJnlLine3."Journal Template Name" := "Journal Template Name";
                ItemJnlLine3."Journal Batch Name" := "Journal Batch Name";
                ItemJnlLine3."Line No." := 10000;
                ItemJnlLine3.Insert();
                ItemJnlLine3.SetUpNewLine(ItemJnlLine2);
                ItemJnlLine3.Modify();
            end;
        end;
    end;

    local procedure ConstructPostingNumber(var ItemJnlLine: Record "Item Journal Line")
    begin
        with ItemJnlLine do
            if "Posting No. Series" = '' then
                "Posting No. Series" := ItemJnlBatch."No. Series"
            else
                if not EmptyLine then
                    if "Document No." = LastDocNo then
                        "Document No." := LastPostedDocNo
                    else begin
                        if not NoSeries.Get("Posting No. Series") then begin
                            NoOfPostingNoSeries := NoOfPostingNoSeries + 1;
                            if NoOfPostingNoSeries > ArrayLen(NoSeriesMgt2) then
                                Error(
                                  Text006,
                                  ArrayLen(NoSeriesMgt2));
                            NoSeries.Code := "Posting No. Series";
                            NoSeries.Description := Format(NoOfPostingNoSeries);
                            NoSeries.Insert();
                        end;
                        LastDocNo := "Document No.";
                        Evaluate(PostingNoSeriesNo, NoSeries.Description);
                        "Document No." := NoSeriesMgt2[PostingNoSeriesNo].GetNextNo("Posting No. Series", "Posting Date", false);
                        LastPostedDocNo := "Document No.";
                    end;

        OnAfterConstructPostingNumber(ItemJnlLine);
    end;

    local procedure CheckRecurringLine(var ItemJnlLine2: Record "Item Journal Line")
    var
        NULDF: DateFormula;
    begin
        with ItemJnlLine2 do
            if "Item No." <> '' then
                if ItemJnlTemplate.Recurring then begin
                    TestField("Recurring Method");
                    TestField("Recurring Frequency");
                    if "Recurring Method" = "Recurring Method"::Variable then
                        TestField(Quantity);
                end else begin
                    Clear(NULDF);
                    TestField("Recurring Method", 0);
                    TestField("Recurring Frequency", NULDF);
                end;
    end;

    local procedure MakeRecurringTexts(var ItemJnlLine2: Record "Item Journal Line")
    begin
        with ItemJnlLine2 do
            if ("Item No." <> '') and ("Recurring Method" <> 0) then begin // Not recurring
                Day := Date2DMY("Posting Date", 1);
                Week := Date2DWY("Posting Date", 2);
                Month := Date2DMY("Posting Date", 2);
                MonthText := Format("Posting Date", 0, Text007);
                AccountingPeriod.SetRange("Starting Date", 0D, "Posting Date");
                if not AccountingPeriod.FindLast then
                    AccountingPeriod.Name := '';
                "Document No." :=
                  DelChr(
                    PadStr(
                      StrSubstNo("Document No.", Day, Week, Month, MonthText, AccountingPeriod.Name),
                      MaxStrLen("Document No.")),
                    '>');
                Description :=
                  DelChr(
                    PadStr(
                      StrSubstNo(Description, Day, Week, Month, MonthText, AccountingPeriod.Name),
                      MaxStrLen(Description)),
                    '>');
            end;
    end;

    local procedure ItemJnlPostSumLine(ItemJnlLine4: Record "Item Journal Line")
    var
        Item: Record Item;
        ItemLedgEntry4: Record "Item Ledger Entry";
        ItemLedgEntry5: Record "Item Ledger Entry";
        Remainder: Decimal;
        RemAmountToDistribute: Decimal;
        RemQuantity: Decimal;
        DistributeCosts: Boolean;
        IncludeExpectedCost: Boolean;
        PostingDate: Date;
        IsLastEntry: Boolean;
    begin
        DistributeCosts := true;
        RemAmountToDistribute := ItemJnlLine.Amount;
        RemQuantity := ItemJnlLine.Quantity;
        if ItemJnlLine.Amount <> 0 then begin
            LineCount := LineCount + 1;
            Window.Update(3, LineCount);
            Window.Update(4, Round(LineCount / NoOfRecords * 10000, 1));
            with ItemLedgEntry4 do begin
                Item.Get(ItemJnlLine4."Item No.");
                OnItemJnlPostSumLineOnAfterGetItem(Item, ItemJnlLine4);
                IncludeExpectedCost :=
                    (Item."Costing Method" = Item."Costing Method"::Standard) and
                    (ItemJnlLine4."Inventory Value Per" <> ItemJnlLine4."Inventory Value Per"::" ");
                Reset;
                SetCurrentKey("Item No.", Positive, "Location Code", "Variant Code");
                SetRange("Item No.", ItemJnlLine."Item No.");
                SetRange(Positive, true);
                PostingDate := ItemJnlLine."Posting Date";

                if (ItemJnlLine4."Location Code" <> '') or
                   (ItemJnlLine4."Inventory Value Per" in
                    [ItemJnlLine."Inventory Value Per"::Location,
                     ItemJnlLine4."Inventory Value Per"::"Location and Variant"])
                then
                    SetRange("Location Code", ItemJnlLine."Location Code");
                if (ItemJnlLine."Variant Code" <> '') or
                   (ItemJnlLine4."Inventory Value Per" in
                    [ItemJnlLine."Inventory Value Per"::Variant,
                     ItemJnlLine4."Inventory Value Per"::"Location and Variant"])
                then
                    SetRange("Variant Code", ItemJnlLine."Variant Code");
                if FindSet then
                    repeat
                        OnItemJnlPostSumLineOnBeforeIncludeEntry(ItemJnlLine4, ItemLedgEntry4, IncludeExpectedCost);
                        if IncludeEntryInCalc(ItemLedgEntry4, PostingDate, IncludeExpectedCost) then begin
                            ItemLedgEntry5 := ItemLedgEntry4;

                            ItemJnlLine4."Entry Type" := "Entry Type";
                            ItemJnlLine4.Quantity := CalculateRemQuantity("Entry No.", ItemJnlLine."Posting Date");

                            ItemJnlLine4."Quantity (Base)" := ItemJnlLine4.Quantity;
                            ItemJnlLine4."Invoiced Quantity" := ItemJnlLine4.Quantity;
                            ItemJnlLine4."Invoiced Qty. (Base)" := ItemJnlLine4.Quantity;
                            ItemJnlLine4."Location Code" := "Location Code";
                            ItemJnlLine4."Variant Code" := "Variant Code";
                            ItemJnlLine4."Applies-to Entry" := "Entry No.";
                            ItemJnlLine4."Source No." := "Source No.";
                            ItemJnlLine4."Order Type" := "Order Type";
                            ItemJnlLine4."Order No." := "Order No.";
                            ItemJnlLine4."Order Line No." := "Order Line No.";

                            if ItemJnlLine4.Quantity <> 0 then begin
                                ItemJnlLine4.Amount :=
                                  ItemJnlLine."Inventory Value (Revalued)" * ItemJnlLine4.Quantity /
                                  ItemJnlLine.Quantity -
                                  Round(
                                    CalculateRemInventoryValue(
                                      "Entry No.", Quantity, ItemJnlLine4.Quantity,
                                      IncludeExpectedCost and not "Completely Invoiced", PostingDate),
                                    GLSetup."Amount Rounding Precision") + Remainder;

                                RemQuantity := RemQuantity - ItemJnlLine4.Quantity;

                                if RemQuantity = 0 then begin
                                    if Next > 0 then
                                        repeat
                                            if IncludeEntryInCalc(ItemLedgEntry4, PostingDate, IncludeExpectedCost) then begin
                                                RemQuantity := CalculateRemQuantity("Entry No.", ItemJnlLine."Posting Date");
                                                if RemQuantity > 0 then
                                                    Error(Text008 + Text009, ItemJnlLine4."Item No.");
                                            end;
                                        until Next = 0;

                                    ItemJnlLine4.Amount := RemAmountToDistribute;
                                    DistributeCosts := false;
                                end else begin
                                    repeat
                                        IsLastEntry := Next = 0;
                                    until IncludeEntryInCalc(ItemLedgEntry4, PostingDate, IncludeExpectedCost) or IsLastEntry;
                                    if IsLastEntry or (RemQuantity < 0) then
                                        Error(Text008 + Text009, ItemJnlLine4."Item No.");
                                    Remainder := ItemJnlLine4.Amount - Round(ItemJnlLine4.Amount, GLSetup."Amount Rounding Precision");
                                    ItemJnlLine4.Amount := Round(ItemJnlLine4.Amount, GLSetup."Amount Rounding Precision");
                                    RemAmountToDistribute := RemAmountToDistribute - ItemJnlLine4.Amount;
                                end;
                                ItemJnlLine4."Unit Cost" := ItemJnlLine4.Amount / ItemJnlLine4.Quantity;

                                OnItemJnlPostSumLineOnBeforeCalcAppliedAmount(ItemJnlLine4, ItemLedgEntry4);
                                if ItemJnlLine4.Amount <> 0 then begin
                                    if IncludeExpectedCost and not ItemLedgEntry5."Completely Invoiced" then begin
                                        ItemJnlLine4."Applied Amount" := Round(
                                            ItemJnlLine4.Amount * (ItemLedgEntry5.Quantity - ItemLedgEntry5."Invoiced Quantity") /
                                            ItemLedgEntry5.Quantity,
                                            GLSetup."Amount Rounding Precision");
                                    end else
                                        ItemJnlLine4."Applied Amount" := 0;
                                    OnBeforeItemJnlPostSumLine(ItemJnlLine4, ItemLedgEntry4);
                                    ItemJnlPostLine.RunWithCheck(ItemJnlLine4);
                                end;
                            end else begin
                                repeat
                                    IsLastEntry := Next = 0;
                                until IncludeEntryInCalc(ItemLedgEntry4, PostingDate, IncludeExpectedCost) or IsLastEntry;
                                if IsLastEntry then
                                    Error(Text008 + Text009, ItemJnlLine4."Item No.");
                            end;
                        end else
                            DistributeCosts := Next <> 0;
                    until not DistributeCosts;
            end;

            if ItemJnlLine."Update Standard Cost" then
                UpdateStdCost;
        end;

        OnAfterItemJnlPostSumLine(ItemJnlLine);
    end;

    local procedure IncludeEntryInCalc(ItemLedgEntry: Record "Item Ledger Entry"; PostingDate: Date; IncludeExpectedCost: Boolean): Boolean
    begin
        with ItemLedgEntry do begin
            if IncludeExpectedCost then
                exit("Posting Date" in [0D .. PostingDate]);
            exit("Completely Invoiced" and ("Last Invoice Date" in [0D .. PostingDate]));
        end;
    end;

    local procedure UpdateStdCost()
    var
        SKU: Record "Stockkeeping Unit";
        InventorySetup: Record "Inventory Setup";
    begin
        with ItemJnlLine do begin
            InventorySetup.Get();
            if InventorySetup."Average Cost Calc. Type" = InventorySetup."Average Cost Calc. Type"::Item then
                UpdateItemStdCost
            else
                if SKU.Get("Location Code", "Item No.", "Variant Code") then begin
                    SKU.Validate("Standard Cost", "Unit Cost (Revalued)");
                    SKU.Modify();
                end else
                    UpdateItemStdCost;
        end;
    end;

    local procedure UpdateItemStdCost()
    var
        Item: Record Item;
    begin
        with ItemJnlLine do begin
            Item.Get("Item No.");
            Item.Validate("Standard Cost", "Unit Cost (Revalued)");
            SetItemSingleLevelCosts(Item, ItemJnlLine);
            SetItemRolledUpCosts(Item, ItemJnlLine);
            Item."Last Unit Cost Calc. Date" := "Posting Date";
            Item.Modify();
        end;
    end;

    local procedure CheckRemainingQty()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        RemainingQty: Decimal;
    begin
        RemainingQty := ItemLedgerEntry.CalculateRemQuantity(
            ItemJnlLine."Applies-to Entry", ItemJnlLine."Posting Date");

        if RemainingQty <> ItemJnlLine.Quantity then
            Error(Text008 + Text009, ItemJnlLine."Item No.");
    end;

    procedure PostWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; OriginalQuantity: Decimal; OriginalQuantityBase: Decimal; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        ItemJnlTemplateType: Option;
    begin
        with ItemJnlLine do begin
            Quantity := OriginalQuantity;
            "Quantity (Base)" := OriginalQuantityBase;
            GetLocation("Location Code");
            ItemJnlTemplateType := ItemJnlTemplate.Type;
            OnPostWhseJnlLineOnBeforeCreateWhseJnlLines(ItemJnlLine, ItemJnlTemplateType);
            if not ("Entry Type" in ["Entry Type"::Consumption, "Entry Type"::Output]) then
                PostWhseJnlLines(ItemJnlLine, TempTrackingSpecification, ItemJnlTemplateType, false);

            if "Entry Type" = "Entry Type"::Transfer then begin
                GetLocation("New Location Code");
                PostWhseJnlLines(ItemJnlLine, TempTrackingSpecification, ItemJnlTemplateType, true);
            end;
        end;
    end;

    local procedure PostWhseJnlLines(ItemJnlLine: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; ItemJnlTemplateType: Option; ToTransfer: Boolean)
    var
        WhseJnlLine: Record "Warehouse Journal Line";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        IsHandled: Boolean;
    begin
        with ItemJnlLine do
            if Location."Bin Mandatory" then
                if WMSMgmt.CreateWhseJnlLine(ItemJnlLine, ItemJnlTemplateType, WhseJnlLine, ToTransfer) then begin
                    ItemTrackingMgt.SplitWhseJnlLine(WhseJnlLine, TempWhseJnlLine, TempTrackingSpecification, ToTransfer);
                    if TempWhseJnlLine.FindSet then
                        repeat
                            WMSMgmt.CheckWhseJnlLine(TempWhseJnlLine, 1, 0, ToTransfer);
                            IsHandled := false;
                            OnBeforeWhseJnlPostLineRun(ItemJnlLine, TempWhseJnlLine, IsHandled);
                            if not IsHandled then
                                WhseJnlPostLine.Run(TempWhseJnlLine);
                        until TempWhseJnlLine.Next = 0;
                    OnAfterPostWhseJnlLine(ItemJnlLine, SuppressCommit);
                end;
    end;

    local procedure CheckWMSBin(ItemJnlLine: Record "Item Journal Line")
    begin
        with ItemJnlLine do begin
            GetLocation("Location Code");
            if Location."Bin Mandatory" then
                WhseTransaction := true;
            case "Entry Type" of
                "Entry Type"::Purchase, "Entry Type"::Sale,
                "Entry Type"::"Positive Adjmt.", "Entry Type"::"Negative Adjmt.":
                    begin
                        if Location."Directed Put-away and Pick" then
                            WMSMgmt.CheckAdjmtBin(
                              Location, Quantity,
                              ("Entry Type" in
                               ["Entry Type"::Purchase,
                                "Entry Type"::"Positive Adjmt."]));
                    end;
                "Entry Type"::Transfer:
                    begin
                        if Location."Directed Put-away and Pick" then
                            WMSMgmt.CheckAdjmtBin(Location, -Quantity, false);
                        GetLocation("New Location Code");
                        if Location."Directed Put-away and Pick" then
                            WMSMgmt.CheckAdjmtBin(Location, Quantity, true);
                        if Location."Bin Mandatory" then
                            WhseTransaction := true;
                    end;
            end;
        end;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    procedure GetWhseRegNo(): Integer
    begin
        exit(WhseRegNo);
    end;

    procedure GetItemRegNo(): Integer
    begin
        exit(ItemRegNo);
    end;

    local procedure IsPhysInvtCount(ItemJnlTemplate2: Record "Item Journal Template"; PhysInvtCountingPeriodCode: Code[10]; PhysInvtCountingPeriodType: Option " ",Item,SKU): Boolean
    begin
        exit(
          (ItemJnlTemplate2.Type = ItemJnlTemplate2.Type::"Phys. Inventory") and
          (PhysInvtCountingPeriodType <> PhysInvtCountingPeriodType::" ") and
          (PhysInvtCountingPeriodCode <> ''));
    end;

    local procedure CheckItemAvailability(var ItemJnlLine: Record "Item Journal Line")
    var
        Item: Record Item;
        TempSKU: Record "Stockkeeping Unit" temporary;
        ItemJnlLine2: Record "Item Journal Line";
        ConfirmManagement: Codeunit "Confirm Management";
        QtyinItemJnlLine: Decimal;
        AvailableQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemAvailabilityHandled(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        ItemJnlLine2.CopyFilters(ItemJnlLine);
        if ItemJnlLine2.FindSet then
            repeat
                if not TempSKU.Get(ItemJnlLine2."Location Code", ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code") then
                    InsertTempSKU(TempSKU, ItemJnlLine2);
                OnBeforeCheckItemAvailability(ItemJnlLine2, TempSKU);
            until ItemJnlLine2.Next = 0;

        if TempSKU.FindSet then
            repeat
                QtyinItemJnlLine := CalcRequiredQty(TempSKU, ItemJnlLine2);
                if QtyinItemJnlLine < 0 then begin
                    Item.Get(TempSKU."Item No.");
                    Item.SetFilter("Location Filter", TempSKU."Location Code");
                    Item.SetFilter("Variant Filter", TempSKU."Variant Code");
                    Item.CalcFields("Reserved Qty. on Inventory", "Net Change");
                    AvailableQty := Item."Net Change" - Item."Reserved Qty. on Inventory" + SelfReservedQty(TempSKU, ItemJnlLine2);

                    if (Item."Reserved Qty. on Inventory" > 0) and (AvailableQty < Abs(QtyinItemJnlLine)) then
                        if not ConfirmManagement.GetResponseOrDefault(
                            StrSubstNo(
                                Text010, TempSKU.FieldCaption("Item No."), TempSKU."Item No.", TempSKU.FieldCaption("Location Code"),
                                TempSKU."Location Code", TempSKU.FieldCaption("Variant Code"), TempSKU."Variant Code"), true)
                        then
                            Error('');
                end;
            until TempSKU.Next = 0;
    end;

    local procedure InsertTempSKU(var TempSKU: Record "Stockkeeping Unit" temporary; ItemJnlLine: Record "Item Journal Line")
    begin
        with TempSKU do begin
            Init;
            "Location Code" := ItemJnlLine."Location Code";
            "Item No." := ItemJnlLine."Item No.";
            "Variant Code" := ItemJnlLine."Variant Code";
            Insert;
        end;
    end;

    local procedure CalcRequiredQty(TempSKU: Record "Stockkeeping Unit" temporary; var ItemJnlLine: Record "Item Journal Line"): Decimal
    var
        SignFactor: Integer;
        QtyinItemJnlLine: Decimal;
    begin
        QtyinItemJnlLine := 0;
        ItemJnlLine.SetRange("Item No.", TempSKU."Item No.");
        ItemJnlLine.SetRange("Location Code", TempSKU."Location Code");
        ItemJnlLine.SetRange("Variant Code", TempSKU."Variant Code");
        ItemJnlLine.FindSet;
        repeat
            if (ItemJnlLine."Entry Type" in
                [ItemJnlLine."Entry Type"::Sale,
                 ItemJnlLine."Entry Type"::"Negative Adjmt.",
                 ItemJnlLine."Entry Type"::Consumption]) or
               (ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Transfer)
            then
                SignFactor := -1
            else
                SignFactor := 1;
            QtyinItemJnlLine += ItemJnlLine."Quantity (Base)" * SignFactor;
        until ItemJnlLine.Next = 0;
        exit(QtyinItemJnlLine);
    end;

    local procedure SelfReservedQty(SKU: Record "Stockkeeping Unit"; ItemJnlLine: Record "Item Journal Line"): Decimal
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        if ItemJnlLine."Order Type" <> ItemJnlLine."Order Type"::Production then
            exit;

        with ReservationEntry do begin
            SetRange("Item No.", SKU."Item No.");
            SetRange("Location Code", SKU."Location Code");
            SetRange("Variant Code", SKU."Variant Code");
            SetRange("Source Type", DATABASE::"Prod. Order Component");
            SetRange("Source ID", ItemJnlLine."Order No.");
            if IsEmpty then
                exit;
            CalcSums("Quantity (Base)");
            exit(-"Quantity (Base)");
        end;
    end;

    local procedure SetItemSingleLevelCosts(var Item: Record Item; ItemJournalLine: Record "Item Journal Line")
    begin
        with ItemJournalLine do begin
            Item."Single-Level Material Cost" := "Single-Level Material Cost";
            Item."Single-Level Capacity Cost" := "Single-Level Capacity Cost";
            Item."Single-Level Subcontrd. Cost" := "Single-Level Subcontrd. Cost";
            Item."Single-Level Cap. Ovhd Cost" := "Single-Level Cap. Ovhd Cost";
            Item."Single-Level Mfg. Ovhd Cost" := "Single-Level Mfg. Ovhd Cost";
        end;
    end;

    local procedure SetItemRolledUpCosts(var Item: Record Item; ItemJournalLine: Record "Item Journal Line")
    begin
        with ItemJournalLine do begin
            Item."Rolled-up Material Cost" := "Rolled-up Material Cost";
            Item."Rolled-up Capacity Cost" := "Rolled-up Capacity Cost";
            Item."Rolled-up Subcontracted Cost" := "Rolled-up Subcontracted Cost";
            Item."Rolled-up Mfg. Ovhd Cost" := "Rolled-up Mfg. Ovhd Cost";
            Item."Rolled-up Cap. Overhead Cost" := "Rolled-up Cap. Overhead Cost";
        end;
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckLines(var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckJnlLine(var ItemJournalLine: Record "Item Journal Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConstructPostingNumber(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyRegNos(var ItemJournalLine: Record "Item Journal Line"; var ItemRegNo: Integer; var WhseRegNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemJnlPostSumLine(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostLines(var ItemJournalLine: Record "Item Journal Line"; var ItemRegNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostJnlLines(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; ItemRegNo: Integer; WhseRegNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostWhseJnlLine(ItemJournalLine: Record "Item Journal Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAnalysisViews(var ItemRegister: Record "Item Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemAvailability(var ItemJournalLine: Record "Item Journal Line"; var StockkeepingUnit: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemAvailabilityHandled(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLines(var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRaiseExceedLengthError(var ItemJournalBatch: Record "Item Journal Batch"; var RaiseError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseJnlPostLineRun(ItemJournalLine: Record "Item Journal Line"; var TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnAfterPostWhseJnlLine(var ItemJournalLine: Record "Item Journal Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLinesBeforePostWhseJnlLine(var ItemJournalLine: Record "Item Journal Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleNonRecurringLine(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleRecurringLine(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIncrBatchName(var ItemJournalLine: Record "Item Journal Line"; var IncrBatchName: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemJnlPostSumLine(var ItemJournalLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDeleteLines(var ItemJournalLine: Record "Item Journal Line"; ItemRegNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleRecurringLineOnBeforeModify(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleNonRecurringLineOnInsertNewLine(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemJnlPostSumLineOnAfterGetItem(var Item: Record Item; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemJnlPostSumLineOnBeforeIncludeEntry(var ItemJournalLine: Record "Item Journal Line"; ItemLedgEntry: Record "Item Ledger Entry"; var IncludeExpectedCost: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemJnlPostSumLineOnBeforeCalcAppliedAmount(var ItemJournalLine: Record "Item Journal Line"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnBeforePostLine(var ItemJournalLine: Record "Item Journal Line"; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostWhseJnlLineOnBeforeCreateWhseJnlLines(ItemJournalLine: Record "Item Journal Line"; var ItemJnlTemplateType: Option)
    begin
    end;
}

