codeunit 7304 "Whse. Jnl.-Register Batch"
{
    Permissions = TableData "Warehouse Journal Batch" = imd,
                  TableData "Warehouse Entry" = imd,
                  TableData "Warehouse Register" = imd;
    TableNo = "Warehouse Journal Line";

    trigger OnRun()
    begin
        WhseJnlLine.Copy(Rec);
        Code;
        Rec := WhseJnlLine;
    end;

    var
        Text001: Label 'Journal Batch Name    #1##########\\';
        Text002: Label 'Checking lines        #2######\';
        Text003: Label 'Registering lines     #3###### @4@@@@@@@@@@@@@';
        Text004: Label 'A maximum of %1 registering number series can be used in each journal.';
        Text007: Label 'One or more reservation entries exist for the item with %1 = %2, %3 = %4, %5 = %6 which may be disrupted if you post this negative adjustment. Do you want to continue?', Comment = 'One or more reservation entries exist for the item with Item No. = 1000, Location Code = BLUE, Variant Code = NEW which may be disrupted if you post this negative adjustment. Do you want to continue?';
        WhseJnlTemplate: Record "Warehouse Journal Template";
        WhseJnlBatch: Record "Warehouse Journal Batch";
        WhseJnlLine: Record "Warehouse Journal Line";
        WhseJnlLine2: Record "Warehouse Journal Line";
        WhseJnlLine3: Record "Warehouse Journal Line";
        WhseReg: Record "Warehouse Register";
        TempBinContentBuffer: Record "Bin Content Buffer" temporary;
        NoSeries: Record "No. Series" temporary;
        NoSeriesMgt: Codeunit NoSeriesManagement;
        NoSeriesMgt2: array[10] of Codeunit NoSeriesManagement;
        WMSMgt: Codeunit "WMS Management";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        Window: Dialog;
        WhseRegNo: Integer;
        StartLineNo: Integer;
        NoOfRecords: Integer;
        LineCount: Integer;
        LastDocNo: Code[20];
        LastDocNo2: Code[20];
        LastRegisteredDocNo: Code[20];
        NoOfRegisteringNoSeries: Integer;
        RegisteringNoSeriesNo: Integer;
        Text005: Label 'Item tracking lines defined for the source line must account for the same quantity as you have entered.';
        Text006: Label 'Item tracking lines do not match the bin content.';
        PhysInvtCount: Boolean;

    local procedure "Code"()
    var
        TempHandlingSpecification: Record "Tracking Specification" temporary;
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
        ItemJnlLine: Record "Item Journal Line";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        PhysInvtCountMgt: Codeunit "Phys. Invt. Count.-Management";
        HideDialog: Boolean;
        SuppressCommit: Boolean;
        IsHandled: Boolean;
    begin
        HideDialog := false;
        SuppressCommit := false;
        IsHandled := false;
        OnBeforeCode(WhseJnlLine, HideDialog, SuppressCommit, IsHandled);
        if IsHandled then
            exit;

        with WhseJnlLine do begin
            LockTable();
            SetRange("Journal Template Name", "Journal Template Name");
            SetRange("Journal Batch Name", "Journal Batch Name");
            SetRange("Location Code", "Location Code");
            WhseJnlTemplate.Get("Journal Template Name");
            WhseJnlBatch.Get("Journal Template Name", "Journal Batch Name", "Location Code");

            if not Find('=><') then begin
                "Line No." := 0;
                if not SuppressCommit then
                    Commit();
                exit;
            end;

            if not HideDialog then begin
                Window.Open(
                  Text001 +
                  Text002 +
                  Text003);
                Window.Update(1, "Journal Batch Name");
            end;
            CheckItemAvailability(WhseJnlLine);

            CheckLines(TempHandlingSpecification, HideDialog);

            // Find next register no.
            WhseRegNo := FindWhseRegNo;

            PhysInvtCount := false;

            // Register lines
            LineCount := 0;
            LastDocNo := '';
            LastDocNo2 := '';
            LastRegisteredDocNo := '';
            Find('-');
            OnBeforeRegisterLines(WhseJnlLine, TempHandlingSpecification);

            repeat
                if not EmptyLine and
                   (WhseJnlBatch."No. Series" <> '') and
                   ("Whse. Document No." <> LastDocNo2)
                then
                    TestField("Whse. Document No.",
                      NoSeriesMgt.GetNextNo(WhseJnlBatch."No. Series", "Registering Date", false));
                if not EmptyLine then
                    LastDocNo2 := "Whse. Document No.";
                if "Registering No. Series" = '' then
                    "Registering No. Series" := WhseJnlBatch."No. Series"
                else
                    if not EmptyLine then
                        if "Whse. Document No." = LastDocNo then
                            "Whse. Document No." := LastRegisteredDocNo
                        else begin
                            if not NoSeries.Get("Registering No. Series") then begin
                                NoOfRegisteringNoSeries := NoOfRegisteringNoSeries + 1;
                                if NoOfRegisteringNoSeries > ArrayLen(NoSeriesMgt2) then
                                    Error(
                                      Text004,
                                      ArrayLen(NoSeriesMgt2));
                                NoSeries.Code := "Registering No. Series";
                                NoSeries.Description := Format(NoOfRegisteringNoSeries);
                                NoSeries.Insert();
                            end;
                            LastDocNo := "Whse. Document No.";
                            Evaluate(RegisteringNoSeriesNo, NoSeries.Description);
                            "Whse. Document No." :=
                              NoSeriesMgt2[RegisteringNoSeriesNo].GetNextNo(
                                "Registering No. Series", "Registering Date", false);
                            LastRegisteredDocNo := "Whse. Document No.";
                        end;

                LineCount := LineCount + 1;
                if not HideDialog then begin
                    Window.Update(3, LineCount);
                    Window.Update(4, Round(LineCount / NoOfRecords * 10000, 1));
                end;

                if Quantity < 0 then
                    WMSMgt.CalcCubageAndWeight(
                      "Item No.", "Unit of Measure Code", "Qty. (Absolute)", Cubage, Weight);

                ItemTrackingMgt.SplitWhseJnlLine(WhseJnlLine, TempWhseJnlLine2, TempHandlingSpecification, false);
                if TempWhseJnlLine2.Find('-') then
                    repeat
                        OnBeforeWhseJnlRegisterLineRun(TempWhseJnlLine2);
                        WhseJnlRegisterLine.Run(TempWhseJnlLine2);
                    until TempWhseJnlLine2.Next = 0;

                if IsReclass("Journal Template Name") then
                    if CreateItemJnlLine(WhseJnlLine, ItemJnlLine) then
                        ItemJnlPostLine.RunWithCheck(ItemJnlLine);

                OnAfterItemJnlPostLine(WhseJnlLine);

                if IsPhysInvtCount(WhseJnlTemplate, "Phys Invt Counting Period Code", "Phys Invt Counting Period Type") then begin
                    if not PhysInvtCount then begin
                        PhysInvtCountMgt.InitTempItemSKUList;
                        PhysInvtCount := true;
                    end;
                    PhysInvtCountMgt.AddToTempItemSKUList("Item No.", "Location Code", "Variant Code", "Phys Invt Counting Period Type");
                end;
            until Next = 0;

            // Copy register no. and current journal batch name to Whse journal
            if not WhseReg.FindLast or (WhseReg."No." <> WhseRegNo) then
                WhseRegNo := 0;

            Init;
            "Line No." := WhseRegNo;

            // Update/delete lines
            UpdateDeleteLines();

            if WhseJnlBatch."No. Series" <> '' then
                NoSeriesMgt.SaveNoSeries;
            if NoSeries.Find('-') then
                repeat
                    Evaluate(RegisteringNoSeriesNo, NoSeries.Description);
                    NoSeriesMgt2[RegisteringNoSeriesNo].SaveNoSeries;
                until NoSeries.Next = 0;

            if PhysInvtCount then
                PhysInvtCountMgt.UpdateItemSKUListPhysInvtCount;

            OnAfterPostJnlLines(WhseJnlBatch, WhseJnlLine, WhseRegNo);

            if not HideDialog then
                Window.Close;
            if not SuppressCommit then
                Commit();
            Clear(WhseJnlRegisterLine);
        end;

        OnAfterCode(WhseJnlLine, WhseJnlBatch, WhseRegNo);
    end;

    local procedure CheckLines(var TempTrackingSpecification: Record "Tracking Specification" temporary; HideDialog: Boolean)
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        IsHandled: Boolean;
    begin
        with WhseJnlLine do begin
            LineCount := 0;
            StartLineNo := "Line No.";
            ItemTrackingMgt.InitCollectItemTrkgInformation;
            repeat
                LineCount := LineCount + 1;
                if not HideDialog then
                    Window.Update(2, LineCount);
                IsHandled := false;
                OnCheckLinesOnBeforeCheckWhseJnlLine(WhseJnlLine, IsHandled);
                if not IsHandled then
                    WMSMgt.CheckWhseJnlLine(WhseJnlLine, 4, "Qty. (Absolute, Base)", false);
                if "Entry Type" in ["Entry Type"::"Positive Adjmt.", "Entry Type"::Movement] then
                    UpdateTempBinContentBuffer(WhseJnlLine, "To Bin Code", true);
                if "Entry Type" in ["Entry Type"::"Negative Adjmt.", "Entry Type"::Movement] then
                    UpdateTempBinContentBuffer(WhseJnlLine, "From Bin Code", false);

                ItemTrackingMgt.GetWhseItemTrkgSetup("Item No.", WhseItemTrackingSetup);
                if WhseItemTrackingSetup.TrackingRequired() then begin
                    if WhseItemTrackingSetup."Serial No. Required" then
                        TestField("Qty. per Unit of Measure", 1);
                    if WhseJnlTemplate.Type <> WhseJnlTemplate.Type::"Physical Inventory" then
                        CreateTrackingSpecification(WhseJnlLine, TempTrackingSpecification)
                    else begin
                        OnCheckWhseJnlLine(WhseJnlLine);
                        CheckTrackingIfRequired(WhseItemTrackingSetup);
                    end;
                end;
                ItemTrackingMgt.CollectItemTrkgInfWhseJnlLine(WhseJnlLine);
                OnAfterCollectTrackingInformation(WhseJnlLine);
                if Next = 0 then
                    Find('-');
            until "Line No." = StartLineNo;
            ItemTrackingMgt.CheckItemTrkgInfBeforePost;
            CheckBin;
            NoOfRecords := LineCount;
        end;
    end;

    local procedure UpdateDeleteLines()
    var
        IncrBatchName: Boolean;
        SkipUpdate: Boolean;
    begin
        SkipUpdate := WhseRegNo = 0;
        OnBeforeUpdateDeleteLines(WhseJnlLine, WhseRegNo, SkipUpdate);
        if SkipUpdate then
            exit;

        with WhseJnlLine do begin
            // Not a recurring journal
            WhseJnlLine2.CopyFilters(WhseJnlLine);
            WhseJnlLine2.SetFilter("Item No.", '<>%1', '');
            if WhseJnlLine2.FindLast then; // Remember the last line

            if Find('-') then begin
                repeat
                    ItemTrackingMgt.DeleteWhseItemTrkgLines(
                        DATABASE::"Warehouse Journal Line", 0, "Journal Batch Name",
                        "Journal Template Name", 0, "Line No.", "Location Code", true);
                until Next = 0;
                DeleteAll();
            end;

            WhseJnlLine3.SetRange("Journal Template Name", "Journal Template Name");
            WhseJnlLine3.SetRange("Journal Batch Name", "Journal Batch Name");
            WhseJnlLine3.SetRange("Location Code", "Location Code");
            if not WhseJnlLine3.FindLast then
                IncrBatchName := IncStr("Journal Batch Name") <> '';
            OnBeforeIncrBatchName(WhseJnlLine3, IncrBatchName);
            if IncrBatchName then begin
                WhseJnlBatch.Delete();
                WhseJnlBatch.Name := IncStr("Journal Batch Name");
                if WhseJnlBatch.Insert() then;
                "Journal Batch Name" := WhseJnlBatch.Name;
            end;

            WhseJnlLine3.SetRange("Journal Batch Name", "Journal Batch Name");
            if (WhseJnlBatch."No. Series" = '') and not WhseJnlLine3.FindLast then begin
                WhseJnlLine3.Init();
                WhseJnlLine3."Journal Template Name" := "Journal Template Name";
                WhseJnlLine3."Journal Batch Name" := "Journal Batch Name";
                WhseJnlLine3."Location Code" := "Location Code";
                WhseJnlLine3."Line No." := 10000;
                WhseJnlLine3.Insert();
                WhseJnlLine3.SetUpNewLine(WhseJnlLine2);
                WhseJnlLine3.Modify();
            end;
        end;
    end;

    local procedure CreateTrackingSpecification(WhseJnlLine: Record "Warehouse Journal Line"; var TempHandlingSpecification: Record "Tracking Specification" temporary)
    var
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        BinContent: Record "Bin Content";
        Location: Record Location;
    begin
        if (WhseJnlLine."Entry Type" = WhseJnlLine."Entry Type"::Movement) or
           (WhseJnlLine.Quantity < 0)
        then
            BinContent.Get(WhseJnlLine."Location Code", WhseJnlLine."From Bin Code", WhseJnlLine."Item No.",
              WhseJnlLine."Variant Code", WhseJnlLine."Unit of Measure Code");

        WhseItemTrkgLine.SetCurrentKey(
          "Source ID", "Source Type", "Source Subtype", "Source Batch Name",
          "Source Prod. Order Line", "Source Ref. No.", "Location Code");
        WhseItemTrkgLine.SetRange("Source Type", DATABASE::"Warehouse Journal Line");
        WhseItemTrkgLine.SetRange("Source ID", WhseJnlLine."Journal Batch Name");
        WhseItemTrkgLine.SetRange("Source Batch Name", WhseJnlLine."Journal Template Name");
        WhseItemTrkgLine.SetRange("Source Ref. No.", WhseJnlLine."Line No.");
        WhseItemTrkgLine.SetRange("Location Code", WhseJnlLine."Location Code");
        WhseItemTrkgLine.CalcSums("Qty. to Handle (Base)");

        if WhseItemTrkgLine."Qty. to Handle (Base)" <> Abs(WhseJnlLine."Qty. (Absolute, Base)") then
            Error(Text005);

        if WhseItemTrkgLine.Find('-') then
            repeat
                ItemTrackingMgt.GetWhseItemTrkgSetup(WhseJnlLine."Item No.", WhseItemTrackingSetup);
                WhseItemTrkgLine.CheckTrackingIfRequired(WhseItemTrackingSetup);
            until WhseItemTrkgLine.Next = 0;

        if (WhseJnlLine."Entry Type" = WhseJnlLine."Entry Type"::Movement) or
           (WhseJnlLine.Quantity < 0)
        then
            if WhseItemTrkgLine.Find('-') then
                repeat
                    BinContent.SetTrackingFilterFromWhseItemTrackingLine(WhseItemTrkgLine);
                    BinContent.CalcFields("Quantity (Base)");
                    if WhseItemTrkgLine."Quantity (Base)" > BinContent."Quantity (Base)" then
                        Error(Text006);
                until WhseItemTrkgLine.Next = 0;

        if WhseItemTrkgLine.Find('-') then
            repeat
                OnBeforeInsertTempHandlingSpecs(WhseJnlLine, WhseItemTrkgLine);

                TempHandlingSpecification.Init();
                TempHandlingSpecification.TransferFields(WhseItemTrkgLine);
                TempHandlingSpecification."Quantity actual Handled (Base)" := WhseItemTrkgLine."Qty. to Handle (Base)";
                OnBeforeTempHandlingSpecificationInsert(TempHandlingSpecification, WhseItemTrkgLine);
                TempHandlingSpecification.Insert();

                with WhseJnlLine do begin
                    Location.Get("Location Code");
                    if ("From Bin Code" <> '') and
                       ("From Bin Code" <> Location."Adjustment Bin Code") and
                       Location."Directed Put-away and Pick"
                    then begin
                        BinContent.Get("Location Code", "From Bin Code", "Item No.", "Variant Code", "Unit of Measure Code");
                        BinContent.SetTrackingFilterFromTrackingSpecification(TempHandlingSpecification);
                        BinContent.CheckDecreaseBinContent("Qty. (Absolute)", "Qty. (Absolute, Base)", "Qty. (Absolute, Base)");
                    end;
                end;
            until WhseItemTrkgLine.Next() = 0;
    end;

    local procedure UpdateTempBinContentBuffer(WhseJnlLine: Record "Warehouse Journal Line"; BinCode: Code[20]; Increase: Boolean)
    begin
        // Calculate cubage and weight per bin
        with WhseJnlLine do begin
            if not TempBinContentBuffer.Get(
                 "Location Code", BinCode, '', '', '', '', '')
            then begin
                TempBinContentBuffer.Init();
                TempBinContentBuffer."Location Code" := "Location Code";
                TempBinContentBuffer."Bin Code" := BinCode;
                TempBinContentBuffer.Insert();
            end;
            if Increase then begin
                TempBinContentBuffer."Qty. to Handle (Base)" := TempBinContentBuffer."Qty. to Handle (Base)" + "Qty. (Absolute, Base)";
                TempBinContentBuffer.Cubage := TempBinContentBuffer.Cubage + Cubage;
                TempBinContentBuffer.Weight := TempBinContentBuffer.Weight + Weight;
            end else begin
                WMSMgt.CalcCubageAndWeight(
                  "Item No.", "Unit of Measure Code", "Qty. (Absolute)", Cubage, Weight);
                TempBinContentBuffer."Qty. to Handle (Base)" := TempBinContentBuffer."Qty. to Handle (Base)" - "Qty. (Absolute, Base)";
                TempBinContentBuffer.Cubage := TempBinContentBuffer.Cubage - Cubage;
                TempBinContentBuffer.Weight := TempBinContentBuffer.Weight - Weight;
            end;
            TempBinContentBuffer.Modify();
        end;
    end;

    local procedure CheckBin()
    var
        Bin: Record Bin;
    begin
        with TempBinContentBuffer do begin
            SetFilter("Qty. to Handle (Base)", '>0');
            if Find('-') then
                repeat
                    Bin.Get("Location Code", "Bin Code");
                    Bin.CheckIncreaseBin(
                      "Bin Code", '', "Qty. to Handle (Base)", Cubage, Weight, Cubage, Weight, true, false);
                until Next = 0;
        end;
    end;

    local procedure FindWhseRegNo(): Integer
    var
        WhseEntry: Record "Warehouse Entry";
    begin
        WhseEntry.LockTable();
        if WhseEntry.FindLast then;
        WhseReg.LockTable();
        exit(WhseReg.GetLastEntryNo() + 1);
    end;

    procedure GetWhseRegNo(): Integer
    begin
        exit(WhseRegNo);
    end;

    local procedure CreateItemJnlLine(WhseJnlLine2: Record "Warehouse Journal Line"; var ItemJnlLine: Record "Item Journal Line"): Boolean
    var
        ReservEntry: Record "Reservation Entry";
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        QtyToHandleBase: Decimal;
    begin
        WhseItemTrkgLine.SetCurrentKey(
          "Source ID", "Source Type", "Source Subtype", "Source Batch Name",
          "Source Prod. Order Line", "Source Ref. No.", "Location Code");
        WhseItemTrkgLine.SetRange("Source Type", DATABASE::"Warehouse Journal Line");
        WhseItemTrkgLine.SetRange("Source ID", WhseJnlLine2."Journal Batch Name");
        WhseItemTrkgLine.SetRange("Source Batch Name", WhseJnlLine2."Journal Template Name");
        WhseItemTrkgLine.SetRange("Source Ref. No.", WhseJnlLine2."Line No.");
        WhseItemTrkgLine.SetRange("Location Code", WhseJnlLine2."Location Code");

        if WhseItemTrkgLine.FindSet then begin
            ItemJnlLine.Init();
            ItemJnlLine."Line No." := 0;
            ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Transfer);
            with WhseJnlLine2 do begin
                repeat
                    if not WhseItemTrkgLine.HasSameNewTracking() or
                        (WhseItemTrkgLine."New Expiration Date" <> WhseItemTrkgLine."Expiration Date")
                    then begin
                        ReservEntry.CopyTrackingFromWhseItemTrackingLine(WhseItemTrkgLine);
                        CreateReservEntry.CreateReservEntryFor(
                          DATABASE::"Item Journal Line", ItemJnlLine."Entry Type", '', '', 0, "Line No.", WhseItemTrkgLine."Qty. per Unit of Measure",
                          Abs(WhseItemTrkgLine."Qty. to Handle"), Abs(WhseItemTrkgLine."Qty. to Handle (Base)"), ReservEntry);
                        CreateReservEntry.SetNewTrackingFromNewWhseItemTrackingLine(WhseItemTrkgLine);
                        CreateReservEntry.SetDates(WhseItemTrkgLine."Warranty Date", WhseItemTrkgLine."Expiration Date");
                        CreateReservEntry.SetNewExpirationDate(WhseItemTrkgLine."New Expiration Date");
                        OnBeforeCreateReservEntry(WhseJnlLine2, WhseItemTrkgLine);
                        CreateReservEntry.CreateEntry(
                          "Item No.", "Variant Code", "Location Code", Description, 0D, 0D, 0, ReservEntry."Reservation Status"::Prospect);
                        QtyToHandleBase += Abs(WhseItemTrkgLine."Qty. to Handle (Base)");
                    end;
                until WhseItemTrkgLine.Next = 0;

                if QtyToHandleBase <> 0 then begin
                    ItemJnlLine."Document No." := "Whse. Document No.";
                    ItemJnlLine.Validate("Posting Date", "Registering Date");
                    ItemJnlLine.Validate("Item No.", "Item No.");
                    ItemJnlLine.Validate("Variant Code", "Variant Code");
                    ItemJnlLine.Validate("Location Code", "Location Code");
                    ItemJnlLine.Validate("Unit of Measure Code", "Unit of Measure Code");
                    ItemJnlLine.Validate(Quantity, Round(QtyToHandleBase / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision));
                    ItemJnlLine.Description := Description;
                    ItemJnlLine."Source Type" := ItemJnlLine."Source Type"::Item;
                    ItemJnlLine."Source No." := "Item No.";
                    ItemJnlLine."Source Code" := "Source Code";
                    ItemJnlLine."Reason Code" := "Reason Code";
                    ItemJnlLine."Warehouse Adjustment" := true;
                    ItemJnlLine."Line No." := "Line No.";
                    OnAfterCreateItemJnlLine(ItemJnlLine, WhseItemTrkgLine, WhseJnlLine2);
                end;
            end;
        end;

        exit(QtyToHandleBase <> 0);
    end;

    local procedure IsPhysInvtCount(WhseJnlTemplate2: Record "Warehouse Journal Template"; PhysInvtCountingPeriodCode: Code[10]; PhysInvtCountingPeriodType: Option " ",Item,SKU): Boolean
    begin
        exit(
          (WhseJnlTemplate2.Type = WhseJnlTemplate2.Type::"Physical Inventory") and
          (PhysInvtCountingPeriodType <> PhysInvtCountingPeriodType::" ") and
          (PhysInvtCountingPeriodCode <> ''));
    end;

    local procedure CheckItemAvailability(var WhseJnlLine: Record "Warehouse Journal Line")
    var
        TempSKU: Record "Stockkeeping Unit" temporary;
        WhseJnlLineToPost: Record "Warehouse Journal Line";
        ConfirmManagement: Codeunit "Confirm Management";
        WhseJnlLineQty: Decimal;
        ReservedQtyOnInventory: Decimal;
        QtyOnWarehouseEntries: Decimal;
    begin
        WhseJnlLineToPost.CopyFilters(WhseJnlLine);
        if WhseJnlLineToPost.FindSet then
            repeat
                if not TempSKU.Get(WhseJnlLineToPost."Location Code", WhseJnlLineToPost."Item No.", WhseJnlLineToPost."Variant Code") then begin
                    InsertTempSKU(TempSKU, WhseJnlLineToPost);

                    WhseJnlLineQty := CalcRequiredQty(TempSKU, WhseJnlLine);
                    if WhseJnlLineQty < 0 then begin
                        ReservedQtyOnInventory := CalcReservedQtyOnInventory(TempSKU."Item No.", TempSKU."Location Code", TempSKU."Variant Code");
                        QtyOnWarehouseEntries := CalcQtyOnWarehouseEntry(TempSKU."Item No.", TempSKU."Location Code", TempSKU."Variant Code");
                        if (ReservedQtyOnInventory > 0) and ((QtyOnWarehouseEntries - ReservedQtyOnInventory) < Abs(WhseJnlLineQty)) then
                            if not ConfirmManagement.GetResponseOrDefault(
                                StrSubstNo(
                                     Text007, TempSKU.FieldCaption("Item No."), TempSKU."Item No.", TempSKU.FieldCaption("Location Code"),
                                     TempSKU."Location Code", TempSKU.FieldCaption("Variant Code"), TempSKU."Variant Code"), true)
                            then
                                Error('');
                    end;
                end;
            until WhseJnlLineToPost.Next = 0;

        OnAfterCheckItemAvailability(WhseJnlLine);
    end;

    local procedure CalcReservedQtyOnInventory(ItemNo: Code[20]; LocationCode: Code[20]; VariantCode: Code[20]): Decimal
    var
        Item: Record Item;
    begin
        with Item do begin
            Get(ItemNo);
            SetFilter("Location Filter", LocationCode);
            SetFilter("Variant Filter", VariantCode);
            CalcFields("Reserved Qty. on Inventory");
            exit("Reserved Qty. on Inventory")
        end;
    end;

    local procedure CalcQtyOnWarehouseEntry(ItemNo: Code[20]; LocationCode: Code[20]; VariantCode: Code[20]): Decimal
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        with WarehouseEntry do begin
            Reset;
            SetCurrentKey("Item No.", "Location Code", "Variant Code", "Bin Type Code", "Unit of Measure Code", "Lot No.", "Serial No.");
            SetRange("Item No.", ItemNo);
            SetRange("Location Code", LocationCode);
            SetRange("Variant Code", VariantCode);
            CalcSums("Qty. (Base)");
            exit("Qty. (Base)");
        end;
    end;

    local procedure InsertTempSKU(var TempSKU: Record "Stockkeeping Unit" temporary; WhseJnlLine: Record "Warehouse Journal Line")
    begin
        with TempSKU do begin
            Init;
            "Location Code" := WhseJnlLine."Location Code";
            "Item No." := WhseJnlLine."Item No.";
            "Variant Code" := WhseJnlLine."Variant Code";
            Insert;
        end;
    end;

    local procedure CalcRequiredQty(TempSKU: Record "Stockkeeping Unit" temporary; var WhseJnlLineFiltered: Record "Warehouse Journal Line"): Decimal
    var
        WhseJnlLine: Record "Warehouse Journal Line";
    begin
        WhseJnlLine.CopyFilters(WhseJnlLineFiltered);
        WhseJnlLine.SetRange("Item No.", TempSKU."Item No.");
        WhseJnlLine.SetRange("Location Code", TempSKU."Location Code");
        WhseJnlLine.SetRange("Variant Code", TempSKU."Variant Code");
        WhseJnlLine.CalcSums("Qty. (Base)");
        exit(WhseJnlLine."Qty. (Base)");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckWhseJnlLine(var WhseJnlLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTempHandlingSpecs(var WhseJnlLine: Record "Warehouse Journal Line"; var WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckItemAvailability(var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCollectTrackingInformation(var WhseJnlLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseJournalBatch: Record "Warehouse Journal Batch"; WhseRegNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemJnlPostLine(var WhseJnlLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostJnlLines(var WhseJnlBatch: Record "Warehouse Journal Batch"; var WhseJnlLine: Record "Warehouse Journal Line"; WhseRegNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var WarehouseJournalLine: Record "Warehouse Journal Line"; var HideDialog: Boolean; var SuppressCommit: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateReservEntry(WarehouseJournalLine: Record "Warehouse Journal Line"; var WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIncrBatchName(var WarehouseJournalLine: Record "Warehouse Journal Line"; var IncrBatchName: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRegisterLines(var WarehouseJournalLine: Record "Warehouse Journal Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempHandlingSpecificationInsert(var TempHandlingTrackingSpecification: Record "Tracking Specification" temporary; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDeleteLines(var WarehouseJournalLine: Record "Warehouse Journal Line"; WhseRegNo: Integer; var SkipUpdate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseJnlRegisterLineRun(var TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckLinesOnBeforeCheckWhseJnlLine(WarehouseJournalLine: Record "Warehouse Journal Line"; var IsHandled: Boolean)
    begin
    end;
}

