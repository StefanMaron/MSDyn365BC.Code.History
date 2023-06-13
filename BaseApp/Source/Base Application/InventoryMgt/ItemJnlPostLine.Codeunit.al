codeunit 22 "Item Jnl.-Post Line"
{
    Permissions = TableData Item = rimd,
                  TableData "Item Ledger Entry" = rimd,
                  TableData "Item Register" = rimd,
                  TableData "Phys. Inventory Ledger Entry" = rimd,
                  TableData "Item Application Entry" = rimd,
                  TableData "Prod. Order Capacity Need" = rimd,
                  TableData "Stockkeeping Unit" = rimd,
                  TableData "Value Entry" = rimd,
                  TableData "Avg. Cost Adjmt. Entry Point" = rim,
                  TableData "Post Value Entry to G/L" = ri,
                  TableData "Capacity Ledger Entry" = rimd,
                  TableData "Inventory Adjmt. Entry (Order)" = rim;
    TableNo = "Item Journal Line";

    trigger OnRun()
    begin
        GetGLSetup();
        RunWithCheck(Rec);
    end;

    var
        Text000: Label 'cannot be less than zero';
        Text001: Label 'Item Tracking is signed wrongly.';
        Text003: Label 'Reserved item %1 is not on inventory.';
        Text004: Label 'is too low';
        TrackingSpecificationMissingErr: Label 'Tracking Specification is missing.';
        Text012: Label 'Item %1 must be reserved.';
        Text014: Label 'Serial No. %1 is already on inventory.';
        SerialNoRequiredErr: Label 'You must assign a serial number for item %1.', Comment = '%1 - Item No.';
        LotNoRequiredErr: Label 'You must assign a lot number for item %1.', Comment = '%1 - Item No.';
        LineNoTxt: Label ' Line No. = ''%1''.', Comment = '%1 - Line No.';
        Text017: Label ' is before the posting date.';
        Text018: Label 'Item Tracking Serial No. %1 Lot No. %2 for Item No. %3 Variant %4 cannot be fully applied.';
        Text021: Label 'You must not define item tracking on %1 %2.';
        Text022: Label 'You cannot apply %1 to %2 on the same item %3 on Production Order %4.';
        Text100: Label 'Fatal error when retrieving Tracking Specification.';
        Text99000000: Label 'must not be filled out when reservations exist';
        CannotUnapplyItemLedgEntryErr: Label 'You cannot proceed with the posting as it will result in negative inventory for item %1. \Item ledger entry %2 cannot be left unapplied.', Comment = '%1 - Item no., %2 - Item ledger entry no.';
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        InvtSetup: Record "Inventory Setup";
        MfgSetup: Record "Manufacturing Setup";
        Location: Record Location;
        NewLocation: Record Location;
        Item: Record Item;
        GlobalItemLedgEntry: Record "Item Ledger Entry";
        OldItemLedgEntry: Record "Item Ledger Entry";
        ItemReg: Record "Item Register";
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlLineOrigin: Record "Item Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
        GenPostingSetup: Record "General Posting Setup";
        ItemApplnEntry: Record "Item Application Entry";
        GlobalValueEntry: Record "Value Entry";
        DirCostValueEntry: Record "Value Entry";
        SKU: Record "Stockkeeping Unit";
        CurrExchRate: Record "Currency Exchange Rate";
        GlobalItemTrackingCode: Record "Item Tracking Code";
        GlobalItemTrackingSetup: Record "Item Tracking Setup";
        TempSplitItemJnlLine: Record "Item Journal Line" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempValueEntryRelation: Record "Value Entry Relation" temporary;
        TempItemEntryRelation: Record "Item Entry Relation" temporary;
        TempJobPlanningLine: Record "Job Planning Line" temporary;
        WhseJnlLine: Record "Warehouse Journal Line";
        TempTouchedItemLedgerEntries: Record "Item Ledger Entry" temporary;
        TempItemApplnEntryHistory: Record "Item Application Entry History" temporary;
        PrevAppliedItemLedgEntry: Record "Item Ledger Entry";
        WMSMgmt: Codeunit "WMS Management";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        ItemJnlCheckLine: Codeunit "Item Jnl.-Check Line";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        ItemJnlLineReserve: Codeunit "Item Jnl. Line-Reserve";
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
        ProdOrderLineReserve: Codeunit "Prod. Order Line-Reserve";
        JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        InventoryPostingToGL: Codeunit "Inventory Posting To G/L";
        CostCalcMgt: Codeunit "Cost Calculation Management";
        AvgCostEntryPointHandler: Codeunit "Avg. Cost Entry Point Handler";
        ACYMgt: Codeunit "Additional-Currency Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        ItemLedgEntryNo: Integer;
        PhysInvtEntryNo: Integer;
        CapLedgEntryNo: Integer;
        ValueEntryNo: Integer;
        ItemApplnEntryNo: Integer;
        TotalAppliedQty: Decimal;
        OverheadAmount: Decimal;
        VarianceAmount: Decimal;
        OverheadAmountACY: Decimal;
        VarianceAmountACY: Decimal;
        QtyPerUnitOfMeasure: Decimal;
        RoundingResidualAmount: Decimal;
        RoundingResidualAmountACY: Decimal;
        InvtSetupRead: Boolean;
        GLSetupRead: Boolean;
        MfgSetupRead: Boolean;
        SKUExists: Boolean;
        AverageTransfer: Boolean;
        PostponeReservationHandling: Boolean;
        VarianceRequired: Boolean;
        LastOperation: Boolean;
        DisableItemTracking: Boolean;
        CalledFromInvtPutawayPick: Boolean;
        CalledFromAdjustment: Boolean;
        PostToGL: Boolean;
        ProdOrderCompModified: Boolean;
        Text023: Label 'Entries applied to an Outbound Transfer cannot be unapplied.';
        Text024: Label 'Entries applied to a Drop Shipment Order cannot be unapplied.';
        CannotUnapplyCorrEntryErr: Label 'Entries applied to a Correction entry cannot be unapplied.';
        IsServUndoConsumption: Boolean;
        Text027: Label 'A fixed application was not unapplied and this prevented the reapplication. Use the Application Worksheet to remove the applications.';
        Text01: Label 'Checking for open entries.';
        BlockRetrieveIT: Boolean;
        Text029: Label '%1 %2 for %3 %4 is reserved for %5.';
        Text030: Label 'The quantity that you are trying to invoice is larger than the quantity in the item ledger with the entry number %1.';
        Text031: Label 'You cannot invoice the item %1 with item tracking number %2 %3 in this purchase order before the associated sales order %4 has been invoiced.', Comment = '%2 = Lot No. %3 = Serial No. Both are tracking numbers.';
        Text032: Label 'You cannot invoice item %1 in this purchase order before the associated sales order %2 has been invoiced.';
        Text033: Label 'Quantity must be -1, 0 or 1 when Serial No. is stated.';
        SkipApplicationCheck: Boolean;
        CalledFromApplicationWorksheet: Boolean;
        SkipSerialNoQtyValidation: Boolean;

    procedure RunWithCheck(var ItemJnlLine2: Record "Item Journal Line"): Boolean
    var
        TrackingSpecExists: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunWithCheck(
          ItemJnlLine2, CalledFromAdjustment, CalledFromInvtPutawayPick, CalledFromApplicationWorksheet,
          PostponeReservationHandling, IsHandled);
        if IsHandled then
            exit;

        PrepareItem(ItemJnlLine2);
        TrackingSpecExists := ItemTrackingMgt.RetrieveItemTracking(ItemJnlLine2, TempTrackingSpecification);
        OnRunWithCheckOnAfterRetrieveItemTracking(
            ItemJnlLine2, TempTrackingSpecification, TrackingSpecExists, PostponeReservationHandling);
        exit(PostSplitJnlLine(ItemJnlLine2, TrackingSpecExists));
    end;

    procedure RunPostWithReservation(var ItemJnlLine2: Record "Item Journal Line"; var ReservationEntry: Record "Reservation Entry"): Boolean
    var
        TrackingSpecExists: Boolean;
    begin
        PrepareItem(ItemJnlLine2);

        ReservationEntry.Reset();
        TrackingSpecExists :=
          ItemTrackingMgt.RetrieveItemTrackingFromReservEntry(ItemJnlLine2, ReservationEntry, TempTrackingSpecification);

        exit(PostSplitJnlLine(ItemJnlLine2, TrackingSpecExists));
    end;

    local procedure "Code"()
    var
        IsHandled: Boolean;
    begin
        OnBeforePostItemJnlLine(ItemJnlLine, CalledFromAdjustment, CalledFromInvtPutawayPick, ItemReg, ItemLedgEntryNo, ValueEntryNo, ItemApplnEntryNo);

        with ItemJnlLine do begin
            if EmptyLine() and not Correction and not Adjustment then
                if not IsValueEntryForDeletedItem() then
                    exit;

            ItemJnlCheckLine.SetCalledFromInvtPutawayPick(CalledFromInvtPutawayPick);
            ItemJnlCheckLine.SetCalledFromAdjustment(CalledFromAdjustment);

            OnCodeOnBeforeRunCheck(ItemJnlCheckLine, ItemJnlLine);
            ItemJnlCheckLine.RunCheck(ItemJnlLine);

            if "Document Date" = 0D then
                "Document Date" := "Posting Date";

            if "VAT Reporting Date" = 0D then
                "VAT Reporting Date" := GLSetup.GetVATDate("Posting Date", "Document Date");

            if ItemLedgEntryNo = 0 then begin
                GlobalItemLedgEntry.LockTable();
                ItemLedgEntryNo := GlobalItemLedgEntry.GetLastEntryNo();
                GlobalItemLedgEntry."Entry No." := ItemLedgEntryNo;
            end;
            InitValueEntryNo();

            GetInvtSetup();
            if not CalledFromAdjustment then
                PostToGL := InvtSetup."Automatic Cost Posting";
            OnCheckPostingCostToGL(PostToGL);

            IsHandled := false;
            OnCodeOnBeforeCheckItemTracking(ItemJnlLine, DisableItemTracking, IsHandled, TempTrackingSpecification, GlobalItemTrackingSetup);
            if not IsHandled then
                if GlobalItemTrackingSetup.TrackingRequired() and ("Quantity (Base)" <> 0) and
                   ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
                   not DisableItemTracking and not Adjustment and
                   not Subcontracting and not IsAssemblyResourceConsumpLine()
                then
                    CheckItemTracking();

            if Correction then
                UndoQuantityPosting();

            if ("Entry Type" in
                ["Entry Type"::Consumption, "Entry Type"::Output, "Entry Type"::"Assembly Consumption", "Entry Type"::"Assembly Output"]) and
               not ("Value Entry Type" = "Value Entry Type"::Revaluation) and
               not OnlyStopTime()
            then begin
                case "Entry Type" of
                    "Entry Type"::"Assembly Consumption", "Entry Type"::"Assembly Output":
                        TestField("Order Type", "Order Type"::Assembly);
                    "Entry Type"::Consumption, "Entry Type"::Output:
                        TestField("Order Type", "Order Type"::Production);
                end;

                IsHandled := false;
                OnCodeOnBeforeTestOrder(ItemJnlLine, IsHandled);
                if not IsHandled then begin
                    TestField("Order No.");
                    if IsAssemblyOutputLine() then
                        TestField("Order Line No.", 0)
                    else
                        TestField("Order Line No.");
                end;
            end;

            GetGeneralPostingSetup(ItemJnlLine);

            if "Qty. per Unit of Measure" = 0 then
                "Qty. per Unit of Measure" := 1;
            if "Qty. per Cap. Unit of Measure" = 0 then
                "Qty. per Cap. Unit of Measure" := 1;

            OnCodeOnBeforeSetQuantity(ItemJnlLine);

            Quantity := "Quantity (Base)";
            "Invoiced Quantity" := "Invoiced Qty. (Base)";
            "Setup Time" := "Setup Time (Base)";
            "Run Time" := "Run Time (Base)";
            "Stop Time" := "Stop Time (Base)";
            "Output Quantity" := "Output Quantity (Base)";
            "Scrap Quantity" := "Scrap Quantity (Base)";

            if not Subcontracting and
               (("Entry Type" = "Entry Type"::Output) or
                IsAssemblyResourceConsumpLine())
            then
                QtyPerUnitOfMeasure := "Qty. per Cap. Unit of Measure"
            else
                QtyPerUnitOfMeasure := "Qty. per Unit of Measure";

            OnCodeOnAfterCalcQtyPerUnitOfMeasure(ItemJnlLine, Subcontracting, QtyPerUnitOfMeasure);

            RoundingResidualAmount := 0;
            RoundingResidualAmountACY := 0;
            RoundingResidualAmount := Quantity *
              ("Unit Cost" / QtyPerUnitOfMeasure - Round("Unit Cost" / QtyPerUnitOfMeasure, GLSetup."Unit-Amount Rounding Precision"));
            RoundingResidualAmountACY := Quantity *
              ("Unit Cost (ACY)" / QtyPerUnitOfMeasure - Round("Unit Cost (ACY)" / QtyPerUnitOfMeasure, Currency."Unit-Amount Rounding Precision"));

            "Unit Amount" := Round(
                "Unit Amount" / QtyPerUnitOfMeasure, GLSetup."Unit-Amount Rounding Precision");
            "Unit Cost" := Round(
                "Unit Cost" / QtyPerUnitOfMeasure, GLSetup."Unit-Amount Rounding Precision");
            "Unit Cost (ACY)" := Round(
                "Unit Cost (ACY)" / QtyPerUnitOfMeasure, Currency."Unit-Amount Rounding Precision");

            OverheadAmount := 0;
            VarianceAmount := 0;
            OverheadAmountACY := 0;
            VarianceAmountACY := 0;
            VarianceRequired := false;
            LastOperation := false;

            OnBeforePostLineByEntryType(ItemJnlLine, CalledFromAdjustment, CalledFromInvtPutawayPick);

            case true of
                IsAssemblyResourceConsumpLine():
                    PostAssemblyResourceConsump();
                Adjustment,
                "Value Entry Type" in ["Value Entry Type"::Rounding, "Value Entry Type"::Revaluation],
                "Entry Type" = "Entry Type"::"Assembly Consumption",
                "Entry Type" = "Entry Type"::"Assembly Output":
                    PostItem();
                "Entry Type" = "Entry Type"::Consumption:
                    PostConsumption();
                "Entry Type" = "Entry Type"::Output:
                    PostOutput();
                not Correction:
                    PostItem();
            end;

            // Entry no. is returned to shipment/receipt
            if Subcontracting then
                "Item Shpt. Entry No." := CapLedgEntryNo
            else
                "Item Shpt. Entry No." := GlobalItemLedgEntry."Entry No.";
        end;

        OnAfterPostItemJnlLine(ItemJnlLine, GlobalItemLedgEntry, ValueEntryNo, InventoryPostingToGL, CalledFromAdjustment, CalledFromInvtPutawayPick, ItemReg, ItemLedgEntryNo, ItemApplnEntryNo);
    end;

    procedure PostSplitJnlLine(var ItemJnlLineToPost: Record "Item Journal Line"; TrackingSpecExists: Boolean): Boolean
    var
        PostItemJnlLine: Boolean;
    begin
        PostItemJnlLine := SetupSplitJnlLine(ItemJnlLineToPost, TrackingSpecExists);
        if not PostItemJnlLine then
            PostItemJnlLine := IsNotInternalWhseMovement(ItemJnlLineToPost);

        OnPostSplitJnlLineOnBeforeSplitJnlLine(ItemJnlLine, ItemJnlLineToPost, PostItemJnlLine, DisableItemTracking);

        while SplitItemJnlLine(ItemJnlLine, PostItemJnlLine) do
            if PostItemJnlLine then
                Code();

        OnPostSplitJnlLineOnAfterCode(ItemJnlLine, ItemJnlLineToPost, PostItemJnlLine, TempTrackingSpecification, DisableItemTracking);
        Clear(PrevAppliedItemLedgEntry);
        ItemJnlLineToPost := ItemJnlLine;
        CorrectOutputValuationDate(GlobalItemLedgEntry);
        RedoApplications();

        OnAfterPostSplitJnlLine(ItemJnlLineToPost, TempTrackingSpecification);

        exit(PostItemJnlLine);
    end;

    local procedure PostConsumption()
    var
        ProdOrderComp: Record "Prod. Order Component";
        TempHandlingSpecification: Record "Tracking Specification" temporary;
        RemQtyToPost: Decimal;
        RemQtyToPostThisLine: Decimal;
        QtyToPost: Decimal;
        UseItemTrackingApplication: Boolean;
        LastLoop: Boolean;
        EndLoop: Boolean;
        NewRemainingQty: Decimal;
        IsHandled: Boolean;
    begin
        with ProdOrderComp do begin
            IsHandled := false;
            OnPostConsumptionOnBeforeCheckOrderType(ProdOrderComp, ItemJnlLine, IsHandled);
            if not IsHandled then
                ItemJnlLine.TestField("Order Type", ItemJnlLine."Order Type"::Production);
            SetCurrentKey(Status, "Prod. Order No.", "Prod. Order Line No.", "Item No.", "Line No.");
            SetRange(Status, Status::Released);
            SetRange("Prod. Order No.", ItemJnlLine."Order No.");
            SetRange("Prod. Order Line No.", ItemJnlLine."Order Line No.");
            SetRange("Item No.", ItemJnlLine."Item No.");
            if ItemJnlLine."Prod. Order Comp. Line No." <> 0 then
                SetRange("Line No.", ItemJnlLine."Prod. Order Comp. Line No.");
            LockTable();

            RemQtyToPost := ItemJnlLine.Quantity;

            OnPostConsumptionOnBeforeFindSetProdOrderComp(ProdOrderComp, ItemJnlLine);

            if FindSet() then begin
                OnPostConsumptionOnAfterFindProdOrderComp(ProdOrderComp);
                if ItemJnlLine.TrackingExists() and not BlockRetrieveIT then
                    UseItemTrackingApplication :=
                      ItemTrackingMgt.RetrieveConsumpItemTracking(ItemJnlLine, TempHandlingSpecification);

                if UseItemTrackingApplication then begin
                    TempHandlingSpecification.SetTrackingFilterFromItemJnlLine(ItemJnlLine);
                    LastLoop := false;
                end else
                    if ReservationExists(ItemJnlLine) then
                        ItemJnlLine.CheckTrackingIfRequiredNotBlank(GlobalItemTrackingSetup);

                repeat
                    IsHandled := false;
                    OnPostConsumptionOnBeforeCalcRemQtyToPostThisLine(ProdOrderComp, ItemJnlLine, TempHandlingSpecification, RemQtyToPost, UseItemTrackingApplication, LastLoop, IsHandled);
                    if not IsHandled then
                        if UseItemTrackingApplication then begin
                            TempHandlingSpecification.SetRange("Source Ref. No.", "Line No.");
                            if LastLoop then begin
                                RemQtyToPostThisLine := "Remaining Qty. (Base)";
                                if TempHandlingSpecification.FindSet() then
                                    repeat
                                        CheckItemTrackingOfComp(TempHandlingSpecification, ItemJnlLine);
                                        RemQtyToPostThisLine += TempHandlingSpecification."Qty. to Handle (Base)";
                                    until TempHandlingSpecification.Next() = 0;
                                if RemQtyToPostThisLine * RemQtyToPost < 0 then
                                    Error(Text001); // Assertion: Test signing
                            end else
                                if TempHandlingSpecification.FindFirst() then begin
                                    RemQtyToPostThisLine := -TempHandlingSpecification."Qty. to Handle (Base)";
                                    TempHandlingSpecification.Delete();
                                end else begin
                                    TempHandlingSpecification.ClearTrackingFilter();
                                    TempHandlingSpecification.FindFirst();
                                    CheckItemTrackingOfComp(TempHandlingSpecification, ItemJnlLine);
                                    RemQtyToPostThisLine := 0;
                                end;
                            if RemQtyToPostThisLine > RemQtyToPost then
                                RemQtyToPostThisLine := RemQtyToPost;
                        end else begin
                            RemQtyToPostThisLine := RemQtyToPost;
                            LastLoop := true;
                        end;

                    QtyToPost := RemQtyToPostThisLine;
                    CalcFields("Act. Consumption (Qty)");
                    NewRemainingQty := "Expected Qty. (Base)" - "Act. Consumption (Qty)" - QtyToPost;
                    OnPostConsumptionOnAfterCalcNewRemainingQty(ProdOrderComp, NewRemainingQty, QtyToPost);
                    NewRemainingQty := Round(NewRemainingQty, UOMMgt.QtyRndPrecision());
                    if (NewRemainingQty * "Expected Qty. (Base)") <= 0 then begin
                        QtyToPost := "Remaining Qty. (Base)";
                        "Remaining Qty. (Base)" := 0;
                    end else begin
                        if ("Remaining Qty. (Base)" * "Expected Qty. (Base)") >= 0 then
                            QtyToPost := "Remaining Qty. (Base)" - NewRemainingQty
                        else
                            QtyToPost := NewRemainingQty;
                        "Remaining Qty. (Base)" := NewRemainingQty;
                    end;

                    IsHandled := false;
                    OnPostConsumptionOnBeforeCalcRemainingQuantity(ProdOrderComp, ItemJnlLine, NewRemainingQty, QtyToPost, IsHandled, RemQtyToPost);
                    if not IsHandled then
                        "Remaining Quantity" := Round("Remaining Qty. (Base)" / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());

                    // Update Qty. Pick for location with optional warehouse pick.
                    UpdateQtyPickedForOptionalWhsePick(ProdOrderComp, QtyToPost + "Act. Consumption (Qty)");

                    if QtyToPost <> 0 then begin
                        RemQtyToPost := RemQtyToPost - QtyToPost;
                        Modify();
                        if ProdOrderCompModified then
                            InsertConsumpEntry(ProdOrderComp, "Line No.", QtyToPost, false)
                        else
                            InsertConsumpEntry(ProdOrderComp, "Line No.", QtyToPost, true);
                        OnPostConsumptionOnAfterInsertEntry(ProdOrderComp);
                    end;

                    if UseItemTrackingApplication then begin
                        if Next() = 0 then begin
                            EndLoop := LastLoop;
                            LastLoop := true;
                            Find('-');
                            TempHandlingSpecification.Reset();
                        end;
                    end else
                        EndLoop := Next() = 0;

                until EndLoop or (RemQtyToPost = 0);
            end;

            OnPostConsumptionOnRemQtyToPostOnBeforeInsertConsumpEntry(ItemJnlLine, ProdOrderComp);
            if RemQtyToPost <> 0 then
                InsertConsumpEntry(ProdOrderComp, ItemJnlLine."Prod. Order Comp. Line No.", RemQtyToPost, false);
        end;
        ProdOrderCompModified := false;

        OnAfterPostConsumption(ProdOrderComp, ItemJnlLine);
    end;

    local procedure PostOutput()
    var
        MfgItem: Record Item;
        MfgSKU: Record "Stockkeeping Unit";
        CapLedgEntry: Record "Capacity Ledger Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        DirCostAmt: Decimal;
        IndirCostAmt: Decimal;
        ValuedQty: Decimal;
        MfgUnitCost: Decimal;
        ReTrack: Boolean;
        PostWhseJnlLine: Boolean;
        SkipPost: Boolean;
        GetItemResult: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforePostOutput(ItemJnlLine);

        with ItemJnlLine do begin
            if "Stop Time" <> 0 then begin
                InsertCapLedgEntry(CapLedgEntry, "Stop Time", "Stop Time");
                SkipPost := OnlyStopTime();
                OnPostOutputOnAfterInsertCapLedgEntry(ItemJnlLine, SkipPost);
                if SkipPost then
                    exit;
            end;

            if OutputValuePosting() then begin
                PostItem();
                exit;
            end;

            if Subcontracting then
                ValuedQty := "Invoiced Quantity"
            else
                ValuedQty := CalcCapQty();

            if GetItem("Item No.", false) then
                if not CalledFromAdjustment then
                    Item.TestField("Inventory Value Zero", false);

            if "Item Shpt. Entry No." <> 0 then
                CapLedgEntry.Get("Item Shpt. Entry No.")
            else
                PostOutputForProdOrder(ProdOrder, ProdOrderLine, CapLedgEntry, ValuedQty, LastOperation);

            CalcDirAndIndirCostAmts(DirCostAmt, IndirCostAmt, ValuedQty, ItemJnlLine);

            InsertCapValueEntry(CapLedgEntry, "Value Entry Type"::"Direct Cost", ValuedQty, ValuedQty, DirCostAmt);
            InsertCapValueEntry(CapLedgEntry, "Value Entry Type"::"Indirect Cost", ValuedQty, 0, IndirCostAmt);

            OnPostOutputOnAfterInsertCostValueEntries(ItemJnlLine, CapLedgEntry, CalledFromAdjustment, PostToGL);

            if LastOperation and ("Output Quantity" <> 0) then begin
                CheckItemTracking();
                if ("Output Quantity" < 0) and not Adjustment then begin
                    if "Applies-to Entry" = 0 then
                        "Applies-to Entry" := FindOpenOutputEntryNoToApply(ItemJnlLine);
                    TestField("Applies-to Entry");
                    ItemLedgerEntry.Get("Applies-to Entry");
                    CheckTrackingEqualItemLedgEntry(ItemLedgerEntry);
                end;

                IsHandled := false;
                OnPostOutputOnBeforeGetMfgAmounts(ItemJnlLine, ProdOrder, IsHandled);
                If not IsHandled THEN BEGIN
                    MfgItem.Get(ProdOrderLine."Item No.");
                    MfgItem.TestField("Gen. Prod. Posting Group");
                    if Subcontracting then
                        MfgUnitCost := ProdOrderLine."Unit Cost" / ProdOrderLine."Qty. per Unit of Measure"
                    else
                        if MfgSKU.Get(ProdOrderLine."Location Code", ProdOrderLine."Item No.", ProdOrderLine."Variant Code") then
                            MfgUnitCost := MfgSKU."Unit Cost"
                        else
                            MfgUnitCost := MfgItem."Unit Cost";
                    OnPostOutputOnAfterSetMfgUnitCost(ItemJnlLine, MfgUnitCost, ProdOrderLine);

                    Amount := "Output Quantity" * MfgUnitCost;
                    "Amount (ACY)" := ACYMgt.CalcACYAmt(Amount, "Posting Date", false);
                    OnPostOutputOnAfterUpdateAmounts(ItemJnlLine);

                    "Gen. Bus. Posting Group" := ProdOrder."Gen. Bus. Posting Group";
                    "Gen. Prod. Posting Group" := MfgItem."Gen. Prod. Posting Group";
                    if "Output Quantity (Base)" * ProdOrderLine."Remaining Qty. (Base)" <= 0 then
                        ReTrack := true
                    else
                        if not CalledFromInvtPutawayPick then
                            ProdOrderLineReserve.TransferPOLineToItemJnlLine(
                            ProdOrderLine, ItemJnlLine, "Output Quantity (Base)");
                end;

                PostWhseJnlLine := true;
                OnPostOutputOnBeforeCreateWhseJnlLine(ItemJnlLine, PostWhseJnlLine);
                if PostWhseJnlLine then begin
                    GetLocation("Location Code");
                    if Location."Bin Mandatory" and (not CalledFromInvtPutawayPick) then begin
                        GetItemResult := GetItem("Item No.", false);
                        if not GetItemResult or Item.IsInventoriableType() then begin
                            WMSMgmt.CreateWhseJnlLineFromOutputJnl(ItemJnlLine, WhseJnlLine);
                            WMSMgmt.CheckWhseJnlLine(WhseJnlLine, 2, 0, false);
                        end;
                    end;
                end;
                OnPostOutputOnAfterCreateWhseJnlLine(ItemJnlLine);

                Description := ProdOrderLine.Description;
                if Subcontracting then begin
                    "Document Type" := "Document Type"::" ";
                    "Document No." := "Order No.";
                    "Document Line No." := 0;
                    "Invoiced Quantity" := 0;
                end;

                IsHandled := false;
                OnPostOutputOnBeforePostItem(ItemJnlLine, ProdOrderLine, IsHandled);
                if not IsHandled then
                    PostItem();

                IsHandled := false;
                OnPostOutputOnBeforeUpdateProdOrderLine(ItemJnlLine, IsHandled);
                if not IsHandled then begin
                    UpdateProdOrderLine(ProdOrderLine, ReTrack);
                    OnPostOutputOnAfterUpdateProdOrderLine(ItemJnlLine, WhseJnlLine, GlobalItemLedgEntry);
                end;

                if PostWhseJnlLine then
                    if Location."Bin Mandatory" and (not CalledFromInvtPutawayPick) then
                        WhseJnlRegisterLine.RegisterWhseJnlLine(WhseJnlLine);
            end;
        end;

        OnAfterPostOutput(GlobalItemLedgEntry, ProdOrderLine, ItemJnlLine);
    end;

    local procedure PostOutputForProdOrder(var ProdOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; var CapLedgEntry: Record "Capacity Ledger Entry"; ValuedQty: Decimal; var LastOperation: Boolean)
    var
        MachCenter: Record "Machine Center";
        WorkCenter: Record "Work Center";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ShouldFlushOperation: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostOutputForProdOrder(ItemJnlLine, LastOperation, IsHandled);
        if IsHandled then
            exit;

        ItemJnlLine.TestField("Order Type", "Inventory Order Type"::Production);
        GetOutputProdOrder(ProdOrder);
        ProdOrder.TestField(Blocked, false);
        ProdOrderLine.LockTable();
        GetOutputProdOrderLine(ProdOrderLine);

        ItemJnlLine."Inventory Posting Group" := ProdOrderLine."Inventory Posting Group";

        ProdOrderRtngLine.SetRange(Status, ProdOrderRtngLine.Status::Released);
        ProdOrderRtngLine.SetRange("Prod. Order No.", ItemJnlLine."Order No.");
        ProdOrderRtngLine.SetRange("Routing Reference No.", ItemJnlLine."Routing Reference No.");
        ProdOrderRtngLine.SetRange("Routing No.", ItemJnlLine."Routing No.");
        OnPostOutputOnAfterProdOrderRtngLineSetFilters(ProdOrderRtngLine);
        if not ProdOrderRtngLine.IsEmpty() then begin
            ItemJnlLine.TestField("Operation No.");
            ItemJnlLine.TestField("No.");

            if ItemJnlLine.Type = "Capacity Type Journal"::"Machine Center" then begin
                MachCenter.Get(ItemJnlLine."No.");
                MachCenter.TestField(Blocked, false);
            end;
            WorkCenter.Get(ItemJnlLine."Work Center No.");
            WorkCenter.TestField(Blocked, false);

            ApplyCapNeed(ItemJnlLine."Setup Time (Base)", ItemJnlLine."Run Time (Base)");
        end;

        if ItemJnlLine."Operation No." <> '' then
            PostOutputUpdateProdOrderRtngLine(ProdOrderLine)
        else
            LastOperation := true;

        if ItemJnlLine.Subcontracting then
            InsertCapLedgEntry(CapLedgEntry, ItemJnlLine.Quantity, ItemJnlLine."Invoiced Quantity")
        else
            InsertCapLedgEntry(CapLedgEntry, ValuedQty, ValuedQty);

        ShouldFlushOperation := ItemJnlLine."Output Quantity" >= 0;
        OnBeforeCallFlushOperation(ItemJnlLine, ShouldFlushOperation);
        if ShouldFlushOperation then
            FlushOperation(ProdOrder, ProdOrderLine);
    end;

    local procedure UpdateQtyPickedForOptionalWhsePick(var ProdOrderComp: Record "Prod. Order Component"; QtyPosted: Decimal)
    begin
        GetLocation(ProdOrderComp."Location Code");
        if not (Location."Require Pick" and Location."Require Shipment") then
            if ProdOrderComp."Qty. Picked (Base)" < QtyPosted then
                ProdOrderComp.Validate("Qty. Picked (Base)", QtyPosted);
    end;

    local procedure GetOutputProdOrder(var ProdOrder: Record "Production Order")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetOutputProdOrder(ProdOrder, ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        ProdOrder.Get(ProdOrder.Status::Released, ItemJnlLine."Order No.");
    end;

    local procedure GetOutputProdOrderLine(var ProdOrderLine: Record "Prod. Order Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetOutputProdOrderLine(ProdOrderLine, ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        ProdOrderLine.Get(ProdOrderLine.Status::Released, ItemJnlLine."Order No.", ItemJnlLine."Order Line No.");
    end;

    local procedure PostOutputUpdateProdOrderRtngLine(ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostOutputUpdateProdOrderRtngLine(ProdOrderRtngLine, ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        with ItemJnlLine do begin
            GetProdOrderRoutingLine(ProdOrderRtngLine, ItemJnlLine);
            if Finished then
                ProdOrderRtngLine."Routing Status" := ProdOrderRtngLine."Routing Status"::Finished
            else
                ProdOrderRtngLine."Routing Status" := ProdOrderRtngLine."Routing Status"::"In Progress";
            LastOperation := (not NextOperationExist(ProdOrderRtngLine));
            OnPostOutputOnBeforeProdOrderRtngLineModify(ProdOrderRtngLine, ProdOrderLine, ItemJnlLine, LastOperation);
            ProdOrderRtngLine.Modify();
        end;
    end;

    procedure PostItem()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItem(ItemJnlLine, IsHandled, CalledFromAdjustment);
        if IsHandled then
            exit;

        with ItemJnlLine do begin
            SKUExists := SKU.Get("Location Code", "Item No.", "Variant Code");
            IsHandled := false;
            OnPostItemOnAfterGetSKU(ItemJnlLine, SKUExists, IsHandled);
            if not IsHandled then
                if "Item Shpt. Entry No." <> 0 then begin
                    "Location Code" := '';
                    "Variant Code" := '';
                end;

            if GetItem("Item No.", false) then
                CheckIfItemIsBlocked();

            OnPostItemOnBeforeCheckInventoryPostingGroup(ItemJnlLine, CalledFromAdjustment, Item, GlobalItemTrackingCode);
            if ("Inventory Posting Group" = '') and (Item.Type = Item.Type::Inventory) then begin
                Item.TestField("Inventory Posting Group");
                "Inventory Posting Group" := Item."Inventory Posting Group";
            end;

            OnPostItemOnBeforeSetAverageTransfer(ItemJnlLine, CalledFromAdjustment);
            if ("Entry Type" = "Entry Type"::Transfer) and
               (Item."Costing Method" = Item."Costing Method"::Average) and
               ("Applies-to Entry" = 0)
            then begin
                AverageTransfer := true;
                TotalAppliedQty := 0;
            end else
                AverageTransfer := false;

            IsHandled := false;
            OnPostItemOnBeforeTransferReservFromJobPlanningLine(ItemJnlLine, IsHandled, AverageTransfer);
            if not IsHandled then
                if "Job Contract Entry No." <> 0 then
                    TransReserveFromJobPlanningLine("Job Contract Entry No.", ItemJnlLine);

            if Item."Costing Method" = Item."Costing Method"::Standard then begin
                OnPostItemOnAfterCheckCostingMethodStandard(Item, ItemJnlLine);
                "Overhead Rate" := Item."Overhead Rate";
                "Indirect Cost %" := Item."Indirect Cost %";
            end;

            if ("Value Entry Type" <> "Value Entry Type"::"Direct Cost") or
               ("Item Charge No." <> '')
            then begin
                "Overhead Rate" := 0;
                "Indirect Cost %" := 0;
            end;

            if (Quantity <> 0) and
               ("Item Charge No." = '') and
               not ("Value Entry Type" in ["Value Entry Type"::Revaluation, "Value Entry Type"::Rounding]) and
               not Adjustment
            then
                ItemQtyPosting()
            else
                if ("Invoiced Quantity" <> 0) or Adjustment or
                   IsInterimRevaluation()
                then begin
                    if "Value Entry Type" = "Value Entry Type"::"Direct Cost" then begin
                        if Item.Type <> Item.Type::"Non-Inventory" then begin
                            IsHandled := false;
                            OnPostItemOnBeforeGetGlobalLedgerEntry(ItemJnlLine, IsHandled);
                            if not IsHandled then
                                GlobalItemLedgEntry.Get("Item Shpt. Entry No.")
                        end else
                            if not GlobalItemLedgEntry.Get("Item Shpt. Entry No.") then
                                exit;
                    end else
                        GlobalItemLedgEntry.Get("Applies-to Entry");
                    CorrectOutputValuationDate(GlobalItemLedgEntry);
                    InitValueEntry(GlobalValueEntry, GlobalItemLedgEntry);
                end;
            CheckRunItemValuePosting();

            OnPostItemOnBeforeUpdateUnitCost(ItemJnlLine, GlobalItemLedgEntry);

            UpdateUnitCost(GlobalValueEntry);
        end;

        OnAfterPostItem(ItemJnlLine, CalledFromAdjustment);
    end;

    local procedure InsertConsumpEntry(var ProdOrderComp: Record "Prod. Order Component"; ProdOrderCompLineNo: Integer; QtyBase: Decimal; ModifyProdOrderComp: Boolean)
    var
        PostWhseJnlLine: Boolean;
        GetItemResult: Boolean;
    begin
        OnBeforeInsertConsumpEntry(ProdOrderComp, QtyBase, ModifyProdOrderComp, ItemJnlLine, TempSplitItemJnlLine);

        with ItemJnlLine do begin
            Quantity := QtyBase;
            "Quantity (Base)" := QtyBase;
            "Invoiced Quantity" := QtyBase;
            "Invoiced Qty. (Base)" := QtyBase;
            "Prod. Order Comp. Line No." := ProdOrderCompLineNo;
            if ModifyProdOrderComp then begin
                if not CalledFromInvtPutawayPick then
                    ProdOrderCompReserve.TransferPOCompToItemJnlLine(ProdOrderComp, ItemJnlLine, QtyBase);
                OnBeforeProdOrderCompModify(ProdOrderComp, ItemJnlLine);
                ProdOrderComp.Modify();
            end;

            if "Value Entry Type" <> "Value Entry Type"::Revaluation then begin
                GetLocation("Location Code");
                if Location."Bin Mandatory" and (not CalledFromInvtPutawayPick) then begin
                    GetItemResult := GetItem("Item No.", false);
                    if GetItemResult and Item.IsInventoriableType() then begin
                        WMSMgmt.CreateWhseJnlLineFromConsumJnl(ItemJnlLine, WhseJnlLine);
                        WMSMgmt.CheckWhseJnlLine(WhseJnlLine, 3, 0, false);
                        PostWhseJnlLine := true;
                    end;
                end;
            end;
        end;

        OnInsertConsumpEntryOnBeforePostItem(ItemJnlLine, ProdOrderComp);

        PostItem();
        if PostWhseJnlLine then
            WhseJnlRegisterLine.RegisterWhseJnlLine(WhseJnlLine);

        OnAfterInsertConsumpEntry(WhseJnlLine, ProdOrderComp, QtyBase, PostWhseJnlLine, ItemJnlLine, ItemLedgEntryNo);
    end;

    local procedure CalcCapQty() CapQty: Decimal
    begin
        GetMfgSetup();

        with ItemJnlLine do begin
            if "Unit Cost Calculation" = "Unit Cost Calculation"::Time then begin
                if MfgSetup."Cost Incl. Setup" then
                    CapQty := "Setup Time" + "Run Time"
                else
                    CapQty := "Run Time";
            end else
                CapQty := Quantity + "Scrap Quantity";
        end;

        OnAfterCalcCapQty(ItemJnlLine, CapQty);
    end;

    local procedure CalcDirAndIndirCostAmts(var DirCostAmt: Decimal; var IndirCostAmt: Decimal; CapQty: Decimal; var ItemJournalLine: Record "Item Journal Line")
    var
        CostAmt: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcDirAndIndirCostAmts(ItemJournalLine, DirCostAmt, IndirCostAmt, CapQty, IsHandled);
        if IsHandled then
            exit;

        with ItemJournalLine do begin
            CostAmt := CapQty * "Unit Cost";
            if Subcontracting then
                CostAmt += RoundingResidualAmount;
            CostAmt := Round(CostAmt);
            DirCostAmt := Round((CostAmt - CapQty * "Overhead Rate") / (1 + "Indirect Cost %" / 100));
            IndirCostAmt := CostAmt - DirCostAmt;
        end;
    end;

    local procedure ApplyCapNeed(PostedSetupTime: Decimal; PostedRunTime: Decimal)
    var
        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
        TypeHelper: Codeunit "Type Helper";
        TimeToAllocate: Decimal;
        PrevSetupTime: Decimal;
        PrevRunTime: Decimal;
    begin
        with ItemJnlLine do begin
            ProdOrderCapNeed.LockTable();
            ProdOrderCapNeed.Reset();
            ProdOrderCapNeed.SetCurrentKey(
              Status, "Prod. Order No.", "Routing Reference No.", "Operation No.", Date, "Starting Time");
            ProdOrderCapNeed.SetRange(Status, ProdOrderCapNeed.Status::Released);
            ProdOrderCapNeed.SetRange("Prod. Order No.", "Order No.");
            ProdOrderCapNeed.SetRange("Requested Only", false);
            ProdOrderCapNeed.SetRange("Routing No.", "Routing No.");
            ProdOrderCapNeed.SetRange("Routing Reference No.", "Routing Reference No.");
            ProdOrderCapNeed.SetRange("Operation No.", "Operation No.");

            if Finished then
                ProdOrderCapNeed.ModifyAll("Allocated Time", 0)
            else begin
                OnApplyCapNeedOnAfterSetFilters(ProdOrderCapNeed, ItemJnlLine);
                CalcCapLedgerEntriesSetupRunTime(ItemJnlLine, PrevSetupTime, PrevRunTime);

                if PostedSetupTime <> 0 then begin
                    ProdOrderCapNeed.SetRange("Time Type", ProdOrderCapNeed."Time Type"::"Setup Time");
                    PostedSetupTime += PrevSetupTime;
                    if ProdOrderCapNeed.FindSet() then
                        repeat
                            TimeToAllocate := TypeHelper.Minimum(ProdOrderCapNeed."Needed Time", PostedSetupTime);
                            ProdOrderCapNeed."Allocated Time" := ProdOrderCapNeed."Needed Time" - TimeToAllocate;
                            ProdOrderCapNeed.Modify();
                            PostedSetupTime -= TimeToAllocate;
                        until ProdOrderCapNeed.Next() = 0;
                end;

                if PostedRunTime <> 0 then begin
                    ProdOrderCapNeed.SetRange("Time Type", ProdOrderCapNeed."Time Type"::"Run Time");
                    PostedRunTime += PrevRunTime;
                    if ProdOrderCapNeed.FindSet() then
                        repeat
                            TimeToAllocate := TypeHelper.Minimum(ProdOrderCapNeed."Needed Time", PostedRunTime);
                            ProdOrderCapNeed."Allocated Time" := ProdOrderCapNeed."Needed Time" - TimeToAllocate;
                            ProdOrderCapNeed.Modify();
                            PostedRunTime -= TimeToAllocate;
                        until ProdOrderCapNeed.Next() = 0;
                end;
            end;
        end;
    end;

    local procedure CalcCapLedgerEntriesSetupRunTime(ItemJnlLine: Record "Item Journal Line"; var TotalSetupTime: Decimal; var TotalRunTime: Decimal)
    var
        CapLedgerEntry: Record "Capacity Ledger Entry";
    begin
        CapLedgerEntry.SetCurrentKey(
          "Order Type", "Order No.", "Order Line No.", "Routing No.", "Routing Reference No.", "Operation No.", "Last Output Line");
        CapLedgerEntry.SetRange("Order Type", CapLedgerEntry."Order Type"::Production);
        CapLedgerEntry.SetRange("Order No.", ItemJnlLine."Order No.");
        CapLedgerEntry.SetRange("Order Line No.", ItemJnlLine."Order Line No.");
        CapLedgerEntry.SetRange("Routing No.", ItemJnlLine."Routing No.");
        CapLedgerEntry.SetRange("Routing Reference No.", ItemJnlLine."Routing Reference No.");
        CapLedgerEntry.SetRange("Operation No.", ItemJnlLine."Operation No.");
        OnCalcCapLedgerEntriesSetupRunTimeOnAfterCapLedgerEntrySetFilters(CapLedgerEntry, ItemJnlLine);

        CapLedgerEntry.CalcSums("Setup Time", "Run Time");
        TotalSetupTime := CapLedgerEntry."Setup Time";
        TotalRunTime := CapLedgerEntry."Run Time";
    end;

    local procedure UpdateProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ReTrack: Boolean)
    var
        ReservMgt: Codeunit "Reservation Management";
    begin
        OnBeforeUpdateProdOrderLine(ProdOrderLine, ItemJnlLine, ReTrack);

        with ProdOrderLine do begin
            if ItemJnlLine."Output Quantity (Base)" > "Remaining Qty. (Base)" then
                ProdOrderLineReserve.AssignForPlanning(ProdOrderLine);
            "Finished Qty. (Base)" := "Finished Qty. (Base)" + ItemJnlLine."Output Quantity (Base)";
            "Finished Quantity" := "Finished Qty. (Base)" / "Qty. per Unit of Measure";
            if "Finished Qty. (Base)" < 0 then
                FieldError("Finished Quantity", Text000);
            "Remaining Qty. (Base)" := "Quantity (Base)" - "Finished Qty. (Base)";
            if "Remaining Qty. (Base)" < 0 then
                "Remaining Qty. (Base)" := 0;
            "Remaining Quantity" := "Remaining Qty. (Base)" / "Qty. per Unit of Measure";
            OnBeforeProdOrderLineModify(ProdOrderLine, ItemJnlLine, ItemLedgEntryNo);
            Modify();

            if ReTrack then begin
                ReservMgt.SetReservSource(ProdOrderLine);
                ReservMgt.ClearSurplus();
                ReservMgt.AutoTrack("Remaining Qty. (Base)");
            end;
        end;

        OnAfterUpdateProdOrderLine(ProdOrderLine, ReTrack, ItemJnlLine);
    end;

    local procedure InsertCapLedgEntry(var CapLedgEntry: Record "Capacity Ledger Entry"; Qty: Decimal; InvdQty: Decimal)
    begin
        with ItemJnlLine do begin
            if CapLedgEntryNo = 0 then begin
                CapLedgEntry.LockTable();
                CapLedgEntryNo := CapLedgEntry.GetLastEntryNo();
            end;

            CapLedgEntryNo := CapLedgEntryNo + 1;

            CapLedgEntry.Init();
            CapLedgEntry."Entry No." := CapLedgEntryNo;

            CapLedgEntry."Operation No." := "Operation No.";
            CapLedgEntry.Type := Type;
            CapLedgEntry."No." := "No.";
            CapLedgEntry.Description := Description;
            CapLedgEntry."Work Center No." := "Work Center No.";
            CapLedgEntry."Work Center Group Code" := "Work Center Group Code";
            CapLedgEntry.Subcontracting := Subcontracting;

            CapLedgEntry.Quantity := Qty;
            CapLedgEntry."Invoiced Quantity" := InvdQty;
            CapLedgEntry."Completely Invoiced" := CapLedgEntry."Invoiced Quantity" = CapLedgEntry.Quantity;

            CapLedgEntry."Setup Time" := "Setup Time";
            CapLedgEntry."Run Time" := "Run Time";
            CapLedgEntry."Stop Time" := "Stop Time";

            if "Unit Cost Calculation" = "Unit Cost Calculation"::Time then begin
                CapLedgEntry."Cap. Unit of Measure Code" := "Cap. Unit of Measure Code";
                CapLedgEntry."Qty. per Cap. Unit of Measure" := "Qty. per Cap. Unit of Measure";
            end;

            CapLedgEntry."Item No." := "Item No.";
            CapLedgEntry."Variant Code" := "Variant Code";
            CapLedgEntry."Output Quantity" := "Output Quantity";
            CapLedgEntry."Scrap Quantity" := "Scrap Quantity";
            CapLedgEntry."Unit of Measure Code" := "Unit of Measure Code";
            CapLedgEntry."Qty. per Unit of Measure" := "Qty. per Unit of Measure";

            CapLedgEntry."Order Type" := "Order Type";
            CapLedgEntry."Order No." := "Order No.";
            CapLedgEntry."Order Line No." := "Order Line No.";
            CapLedgEntry."Routing No." := "Routing No.";
            CapLedgEntry."Routing Reference No." := "Routing Reference No.";
            CapLedgEntry."Operation No." := "Operation No.";

            CapLedgEntry."Posting Date" := "Posting Date";
            CapLedgEntry."Document Date" := "Document Date";
            CapLedgEntry."Document No." := "Document No.";
            CapLedgEntry."External Document No." := "External Document No.";

            CapLedgEntry."Starting Time" := "Starting Time";
            CapLedgEntry."Ending Time" := "Ending Time";
            CapLedgEntry."Concurrent Capacity" := "Concurrent Capacity";
            CapLedgEntry."Work Shift Code" := "Work Shift Code";

            CapLedgEntry."Stop Code" := "Stop Code";
            CapLedgEntry."Scrap Code" := "Scrap Code";
            CapLedgEntry."Last Output Line" := LastOperation;

            CapLedgEntry."Global Dimension 1 Code" := "Shortcut Dimension 1 Code";
            CapLedgEntry."Global Dimension 2 Code" := "Shortcut Dimension 2 Code";
            CapLedgEntry."Dimension Set ID" := "Dimension Set ID";

            OnBeforeInsertCapLedgEntry(CapLedgEntry, ItemJnlLine);

            CapLedgEntry.Insert();

            OnAfterInsertCapLedgEntry(CapLedgEntry, ItemJnlLine);

            InsertItemReg(0, 0, 0, CapLedgEntry."Entry No.");
        end;
    end;

    local procedure InsertCapValueEntry(var CapLedgEntry: Record "Capacity Ledger Entry"; ValueEntryType: Enum "Cost Entry Type"; ValuedQty: Decimal; InvdQty: Decimal; AdjdCost: Decimal)
    var
        ValueEntry: Record "Value Entry";
        IsHandled: Boolean;
    begin
        OnBeforeInsertCapValueEntryProcedure(ItemJnlLine, ValueEntryType, ValuedQty, InvdQty, AdjdCost);

        with ItemJnlLine do begin
            if (InvdQty = 0) and (AdjdCost = 0) then
                exit;

            ValueEntryNo := ValueEntryNo + 1;

            ValueEntry.Init();
            ValueEntry."Entry No." := ValueEntryNo;
            ValueEntry."Capacity Ledger Entry No." := CapLedgEntry."Entry No.";
            ValueEntry."Entry Type" := ValueEntryType;
            ValueEntry."Item Ledger Entry Type" := ValueEntry."Item Ledger Entry Type"::" ";

            ValueEntry.Type := Type;
            ValueEntry."No." := "No.";
            ValueEntry.Description := Description;
            ValueEntry."Order Type" := "Order Type";
            ValueEntry."Order No." := "Order No.";
            ValueEntry."Order Line No." := "Order Line No.";
            ValueEntry."Source Type" := "Source Type";
            ValueEntry."Source No." := GetSourceNo(ItemJnlLine);
            ValueEntry."Invoiced Quantity" := InvdQty;
            ValueEntry."Valued Quantity" := ValuedQty;

            ValueEntry."Cost Amount (Actual)" := AdjdCost;
            ValueEntry."Cost Amount (Actual) (ACY)" := ACYMgt.CalcACYAmt(AdjdCost, "Posting Date", false);
            OnInsertCapValueEntryOnAfterUpdateCostAmounts(ValueEntry, ItemJnlLine);

            ValueEntry."Cost per Unit" :=
              CalcCostPerUnit(ValueEntry."Cost Amount (Actual)", ValueEntry."Valued Quantity", false);
            ValueEntry."Cost per Unit (ACY)" :=
              CalcCostPerUnit(ValueEntry."Cost Amount (Actual) (ACY)", ValueEntry."Valued Quantity", true);
            ValueEntry.Inventoriable := true;

            if Type = Type::Resource then
                TestField("Inventory Posting Group", '')
            else
                TestField("Inventory Posting Group");
            ValueEntry."Inventory Posting Group" := "Inventory Posting Group";
            ValueEntry."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
            ValueEntry."Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";

            ValueEntry."Posting Date" := "Posting Date";
            ValueEntry."Valuation Date" := "Posting Date";
            ValueEntry."Source No." := GetSourceNo(ItemJnlLine);
            ValueEntry."Document Type" := "Document Type";
            if ValueEntry."Expected Cost" or ("Invoice No." = '') then
                ValueEntry."Document No." := "Document No."
            else begin
                ValueEntry."Document No." := "Invoice No.";
                if "Document Type" in
                   ["Document Type"::"Purchase Receipt", "Document Type"::"Purchase Return Shipment",
                    "Document Type"::"Sales Shipment", "Document Type"::"Sales Return Receipt",
                    "Document Type"::"Service Shipment"]
                then
                    ValueEntry."Document Type" := "Item Ledger Document Type".FromInteger("Document Type".AsInteger() + 1);
            end;
            ValueEntry."Document Line No." := "Document Line No.";
            ValueEntry."Document Date" := "Document Date";
            ValueEntry."External Document No." := "External Document No.";
            ValueEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(ValueEntry."User ID"));
            ValueEntry."Source Code" := "Source Code";
            ValueEntry."Reason Code" := "Reason Code";
            ValueEntry."Journal Batch Name" := "Journal Batch Name";

            ValueEntry."Global Dimension 1 Code" := "Shortcut Dimension 1 Code";
            ValueEntry."Global Dimension 2 Code" := "Shortcut Dimension 2 Code";
            ValueEntry."Dimension Set ID" := "Dimension Set ID";

            OnBeforeInsertCapValueEntry(ValueEntry, ItemJnlLine);

            IsHandled := false;
            OnInsertCapValueEntryOnBeforeInventoryPostingToGL(ValueEntry, IsHandled, PostToGL);
            if not IsHandled then begin
                InventoryPostingToGL.SetRunOnlyCheck(true, not InvtSetup."Automatic Cost Posting", false);
                PostInvtBuffer(ValueEntry);
            end;

            ValueEntry.Insert(true);
            OnAfterInsertCapValueEntry(ValueEntry, ItemJnlLine);

            UpdateAdjmtProperties(ValueEntry, CapLedgEntry."Posting Date");

            InsertItemReg(0, 0, ValueEntry."Entry No.", 0);
            InsertPostValueEntryToGL(ValueEntry);
            if Item."Item Tracking Code" <> '' then begin
                TempValueEntryRelation.Init();
                TempValueEntryRelation."Value Entry No." := ValueEntry."Entry No.";
                TempValueEntryRelation.Insert();
            end;
            OnInsertCapValueEntryOnAfterInsertValueEntryRelation(ValueEntry, ItemJnlLine, TempValueEntryRelation);

            if ("Item Shpt. Entry No." <> 0) and
               (ValueEntryType = "Value Entry Type"::"Direct Cost")
            then begin
                CapLedgEntry."Invoiced Quantity" := CapLedgEntry."Invoiced Quantity" + "Invoiced Quantity";
                if Subcontracting then
                    CapLedgEntry."Completely Invoiced" := CapLedgEntry."Invoiced Quantity" = CapLedgEntry."Output Quantity"
                else
                    CapLedgEntry."Completely Invoiced" := CapLedgEntry."Invoiced Quantity" = CapLedgEntry.Quantity;
                CapLedgEntry.Modify();
            end;
        end;

        OnInsertCapValueEntryOnAfterUpdateCapLedgEntry(ValueEntry, ItemJnlLine);
    end;

    procedure ItemQtyPosting()
    var
        IsReserved: Boolean;
        InsertItemLedgEntryNeeded: Boolean;
    begin
        with ItemJnlLine do begin
            if Quantity <> "Invoiced Quantity" then
                TestField("Invoiced Quantity", 0);
            TestField("Item Shpt. Entry No.", 0);

            InitItemLedgEntry(GlobalItemLedgEntry);
            InitValueEntry(GlobalValueEntry, GlobalItemLedgEntry);

            if Item.Type = Item.Type::Inventory then begin
                GlobalItemLedgEntry."Remaining Quantity" := GlobalItemLedgEntry.Quantity;
                GlobalItemLedgEntry.Open := GlobalItemLedgEntry."Remaining Quantity" <> 0;
            end else begin
                GlobalItemLedgEntry."Remaining Quantity" := 0;
                GlobalItemLedgEntry.Open := false;
            end;
            GlobalItemLedgEntry.Positive := GlobalItemLedgEntry.Quantity > 0;
            if GlobalItemLedgEntry."Entry Type" = GlobalItemLedgEntry."Entry Type"::Transfer then
                GlobalItemLedgEntry."Completely Invoiced" := true;

            if GlobalItemLedgEntry.Quantity > 0 then
                if GlobalItemLedgEntry."Entry Type" <> GlobalItemLedgEntry."Entry Type"::Transfer then
                    IsReserved :=
                      ItemJnlLineReserve.TransferItemJnlToItemLedgEntry(
                        ItemJnlLine, GlobalItemLedgEntry, "Quantity (Base)", true);

            OnItemQtyPostingOnBeforeApplyItemLedgEntry(ItemJnlLine, GlobalItemLedgEntry);
            ApplyItemLedgEntry(GlobalItemLedgEntry, OldItemLedgEntry, GlobalValueEntry, false);
            CheckApplFromInProduction(GlobalItemLedgEntry, "Applies-from Entry");
            AutoTrack(GlobalItemLedgEntry, IsReserved);

            if ("Entry Type" = "Entry Type"::Transfer) and AverageTransfer then
                InsertTransferEntry(GlobalItemLedgEntry, OldItemLedgEntry, TotalAppliedQty);

            OnItemQtyPostingOnAfterInsertTransferEntry(
                ItemJnlLine, AverageTransfer, GlobalItemLedgEntry, OldItemLedgEntry, TotalAppliedQty, TempItemEntryRelation, GlobalValueEntry); // <-- NEW EVENT

            if "Entry Type" in ["Entry Type"::"Assembly Output", "Entry Type"::"Assembly Consumption"] then
                InsertAsmItemEntryRelation(GlobalItemLedgEntry);

            InsertItemLedgEntryNeeded := (not "Phys. Inventory") or (Quantity <> 0);
            OnItemQtyPostingOnAfterCalcInsertItemLedgEntryNeeded(ItemJnlLine, InsertItemLedgEntryNeeded);
            if InsertItemLedgEntryNeeded then begin
                InsertItemLedgEntry(GlobalItemLedgEntry, false);
                OnItemQtyPostingOnBeforeInsertApplEntry(GlobalItemLedgEntry, ItemJnlLine);
                if GlobalItemLedgEntry.Positive then
                    InsertApplEntry(
                      GlobalItemLedgEntry."Entry No.", GlobalItemLedgEntry."Entry No.",
                      "Applies-from Entry", 0, GlobalItemLedgEntry."Posting Date",
                      GlobalItemLedgEntry.Quantity, true);
                OnItemQtyPostingOnAfterInsertApplEntry(ItemJnlLine, TempSplitItemJnlLine, GlobalItemLedgEntry);
            end;
        end;
        OnAfterItemQtyPosting(ItemJnlLine);
    end;

    local procedure CheckRunItemValuePosting()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckRunItemValuePosting(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        with ItemJnlLine do
            if ((Quantity <> 0) or ("Invoiced Quantity" <> 0)) and
                not (Adjustment and (Amount = 0) and ("Amount (ACY)" = 0))
            then
                ItemValuePosting();
    end;

    local procedure CheckIfItemIsBlocked()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIfItemIsBlocked(ItemJnlLine, CalledFromAdjustment, IsHandled);
        if IsHandled then
            exit;

        if not CalledFromAdjustment then
            ItemJnlLine.DisplayErrorIfItemIsBlocked(Item);
        Item.CheckBlockedByApplWorksheet();
    end;

    procedure ItemValuePosting()
    var
        IsCostNotTracedDirectly: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeItemValuePosting(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        with ItemJnlLine do begin
            if ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
               ("Item Charge No." = '') and
               not Adjustment
            then
                if (Quantity = 0) and ("Invoiced Quantity" <> 0) then begin
                    if (GlobalValueEntry."Invoiced Quantity" < 0) and
                       (Item."Costing Method" = Item."Costing Method"::Average)
                    then
                        ValuateAppliedAvgEntry(GlobalValueEntry, Item);
                end else begin
                    if (GlobalValueEntry."Valued Quantity" < 0) and ("Entry Type" <> "Entry Type"::Transfer) then
                        if Item."Costing Method" = Item."Costing Method"::Average then
                            ValuateAppliedAvgEntry(GlobalValueEntry, Item);
                end;

            InsertValueEntry(GlobalValueEntry, GlobalItemLedgEntry, false);

            OnItemValuePostingOnAfterInsertValueEntry(GlobalValueEntry, GlobalItemLedgEntry, ValueEntryNo);

            IsCostNotTracedDirectly := ("Value Entry Type" <> "Value Entry Type"::"Direct Cost") or ("Item Charge No." <> '');
            OnItemValuePostingOnAfterCalcIsCostNotTracedDirectly(ItemJnlLine, IsCostNotTracedDirectly);
            if IsCostNotTracedDirectly then begin
                if ("Value Entry Type" <> "Value Entry Type"::Rounding) and (not Adjustment) then begin
                    if GlobalItemLedgEntry.Positive then
                        GlobalItemLedgEntry.Modify();
                    IsHandled := false;
                    OnItemValuePostingOnBeforeInsertOHValueEntry(ItemJnlLine, GlobalValueEntry, GlobalItemLedgEntry, ValueEntryNo, IsHandled, VarianceAmount, VarianceAmountACY);
                    if not IsHandled then
                        if ((GlobalValueEntry."Valued Quantity" > 0) or
                            (("Applies-to Entry" <> 0) and ("Entry Type" in ["Entry Type"::Purchase, "Entry Type"::"Assembly Output"]))) and
                           (OverheadAmount <> 0)
                        then
                            InsertOHValueEntry(GlobalValueEntry, OverheadAmount, OverheadAmountACY);
                    if (Item."Costing Method" = Item."Costing Method"::Standard) and
                       ("Entry Type" = "Entry Type"::Purchase) and
                       (GlobalValueEntry."Entry Type" <> GlobalValueEntry."Entry Type"::Revaluation)
                    then
                        InsertVarValueEntry(
                          GlobalValueEntry,
                          -GlobalValueEntry."Cost Amount (Actual)" + OverheadAmount,
                          -(GlobalValueEntry."Cost Amount (Actual) (ACY)" + OverheadAmountACY));
                end;
            end else begin
                if IsBalanceExpectedCostFromRev(ItemJnlLine) then
                    InsertBalanceExpCostRevEntry(GlobalValueEntry);

                IsHandled := false;
                OnItemValuePostingOnBeforeInsertOHValueEntry(ItemJnlLine, GlobalValueEntry, GlobalItemLedgEntry, ValueEntryNo, IsHandled, VarianceAmount, VarianceAmountACY);
                if not IsHandled then
                    if ((GlobalValueEntry."Valued Quantity" > 0) or
                        (("Applies-to Entry" <> 0) and ("Entry Type" in ["Entry Type"::Purchase, "Entry Type"::"Assembly Output"]))) and
                       (OverheadAmount <> 0)
                    then
                        InsertOHValueEntry(GlobalValueEntry, OverheadAmount, OverheadAmountACY);

                if ((GlobalValueEntry."Valued Quantity" > 0) or ("Applies-to Entry" <> 0)) and
                   ("Entry Type" = "Entry Type"::Purchase) and
                   (Item."Costing Method" = Item."Costing Method"::Standard) and
                   (Round(VarianceAmount, GLSetup."Amount Rounding Precision") <> 0) or
                   VarianceRequired
                then
                    InsertVarValueEntry(GlobalValueEntry, VarianceAmount, VarianceAmountACY);
            end;
            if (GlobalValueEntry."Valued Quantity" < 0) and
               (GlobalItemLedgEntry.Quantity = GlobalItemLedgEntry."Invoiced Quantity")
            then
                UpdateItemApplnEntry(GlobalValueEntry."Item Ledger Entry No.", "Posting Date");
        end;

        OnAfterItemValuePosting(GlobalValueEntry, ItemJnlLine, Item);
    end;

    local procedure FlushOperation(ProdOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderComp: Record "Prod. Order Component";
        OldItemJnlLine: Record "Item Journal Line";
        OldTempSplitItemJnlLine: Record "Item Journal Line" temporary;
        OldItemTrackingCode: Record "Item Tracking Code";
        OldItemTrackingSetup: Record "Item Tracking Setup";
        xCalledFromInvtPutawayPick: Boolean;
    begin
        OnBeforeFlushOperation(ProdOrder, ProdOrderLine, ItemJnlLine, LastOperation);

        if ItemJnlLine."Operation No." = '' then
            exit;

        OldItemJnlLine := ItemJnlLine;
        OldTempSplitItemJnlLine.Reset();
        OldTempSplitItemJnlLine.DeleteAll();
        TempSplitItemJnlLine.Reset();
        if TempSplitItemJnlLine.FindSet() then
            repeat
                OldTempSplitItemJnlLine := TempSplitItemJnlLine;
                OldTempSplitItemJnlLine.Insert();
            until TempSplitItemJnlLine.Next() = 0;

        OldItemTrackingSetup := GlobalItemTrackingSetup;
        OldItemTrackingCode := GlobalItemTrackingCode;
        xCalledFromInvtPutawayPick := CalledFromInvtPutawayPick;
        CalledFromInvtPutawayPick := false;

        GetProdOrderRoutingLine(ProdOrderRoutingLine, OldItemJnlLine);
        OnFlushOperationOnBeforeCheckRoutingLinkCode(ProdOrder, ProdOrderLine, ProdOrderRoutingLine, ItemJnlLine, LastOperation);
        if ProdOrderRoutingLine."Routing Link Code" <> '' then
            with ProdOrderComp do begin
                SetCurrentKey(Status, "Prod. Order No.", "Routing Link Code", "Flushing Method");
                SetRange("Flushing Method", "Flushing Method"::Forward, "Flushing Method"::"Pick + Backward");
                SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
                SetRange(Status, Status::Released);
                SetRange("Prod. Order No.", OldItemJnlLine."Order No.");
                SetRange("Prod. Order Line No.", OldItemJnlLine."Order Line No.");
                OnFlushOperationOnAfterProdOrderCompSetFilters(ProdOrderComp, OldItemJnlLine, ProdOrderRoutingLine);
                if FindSet() then begin
                    BlockRetrieveIT := true;
                    repeat
                        PostFlushedConsumption(ProdOrder, ProdOrderLine, ProdOrderComp, ProdOrderRoutingLine, OldItemJnlLine);
                    until Next() = 0;
                    BlockRetrieveIT := false;
                end;
            end;

        ItemJnlLine := OldItemJnlLine;
        TempSplitItemJnlLine.Reset();
        TempSplitItemJnlLine.DeleteAll();
        if OldTempSplitItemJnlLine.FindSet() then
            repeat
                TempSplitItemJnlLine := OldTempSplitItemJnlLine;
                TempSplitItemJnlLine.Insert();
            until OldTempSplitItemJnlLine.Next() = 0;

        GlobalItemTrackingSetup := OldItemTrackingSetup;
        GlobalItemTrackingCode := OldItemTrackingCode;
        CalledFromInvtPutawayPick := xCalledFromInvtPutawayPick;

        OnAfterFlushOperation(ProdOrder, ProdOrderLine, ItemJnlLine);
    end;

    local procedure GetProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; OrderNo: Code[20]; OrderLineNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetProdOrderLine(ProdOrderLine, OrderNo, OrderLineNo, IsHandled);
        if IsHandled then
            exit;

        ProdOrderLine.Get(ProdOrderLine.Status::Released, OrderNo, OrderLineNo);
    end;

    local procedure GetProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; OldItemJnlLine: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetProdOrderRoutingLine(ProdOrderRoutingLine, OldItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        ProdOrderRoutingLine.Get(
          ProdOrderRoutingLine.Status::Released, OldItemJnlLine."Order No.",
          OldItemJnlLine."Routing Reference No.", OldItemJnlLine."Routing No.", OldItemJnlLine."Operation No.");
    end;

    procedure PostFlushedConsumption(ProdOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderComp: Record "Prod. Order Component"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; OldItemJnlLine: Record "Item Journal Line")
    var
        CompItem: Record Item;
        OldTempTrackingSpecification: Record "Tracking Specification" temporary;
        OutputQtyBase: Decimal;
        QtyToPost: Decimal;
        CalcBasedOn: Option "Actual Output","Expected Output";
        PostItemJnlLine: Boolean;
        DimsAreTaken: Boolean;
        TrackingSpecExists: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostFlushedConsump(ProdOrder, ProdOrderLine, ProdOrderComp, ProdOrderRoutingLine, OldItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        OutputQtyBase := OldItemJnlLine."Output Quantity (Base)" + OldItemJnlLine."Scrap Quantity (Base)";

        CompItem.Get(ProdOrderComp."Item No.");
        CompItem.TestField("Rounding Precision");

        OnPostFlushedConsumptionOnBeforeCalcQtyToPost(ProdOrder, ProdOrderLine, ProdOrderComp, ProdOrderRoutingLine, OldItemJnlLine, OutputQtyBase);
        if ProdOrderComp."Flushing Method" in
           [ProdOrderComp."Flushing Method"::Backward, ProdOrderComp."Flushing Method"::"Pick + Backward"]
        then begin
            QtyToPost :=
              CostCalcMgt.CalcActNeededQtyBase(ProdOrderLine, ProdOrderComp, OutputQtyBase) / ProdOrderComp."Qty. per Unit of Measure";
            if (ProdOrderLine."Remaining Qty. (Base)" = OutputQtyBase) and
               (ProdOrderComp."Remaining Quantity" <> 0) and
               (Abs(Round(QtyToPost, CompItem."Rounding Precision") - ProdOrderComp."Remaining Quantity") <= CompItem."Rounding Precision") and
               (Abs(Round(QtyToPost, CompItem."Rounding Precision") - ProdOrderComp."Remaining Quantity") < 1)
            then
                QtyToPost := ProdOrderComp."Remaining Quantity";
        end else
            QtyToPost := ProdOrderComp.GetNeededQty(CalcBasedOn::"Expected Output", true);
        QtyToPost := UOMMgt.RoundToItemRndPrecision(QtyToPost, CompItem."Rounding Precision");
        OnPostFlushedConsumpOnAfterCalcQtyToPost(ProdOrder, ProdOrderLine, ProdOrderComp, OutputQtyBase, QtyToPost, OldItemJnlLine);
        if QtyToPost = 0 then
            exit;

        GetMfgSetup();
        with ItemJnlLine do begin
            Init();
            "Line No." := 0;
            "Entry Type" := "Entry Type"::Consumption;
            Validate("Posting Date", OldItemJnlLine."Posting Date");
            if MfgSetup."Doc. No. Is Prod. Order No." then
                "Document No." := ProdOrderLine."Prod. Order No."
            else
                "Document No." := OldItemJnlLine."Document No.";
            "Source No." := ProdOrderLine."Item No.";
            "Order Type" := "Order Type"::Production;
            "Order No." := ProdOrderLine."Prod. Order No.";
            Validate("Order Line No.", ProdOrderLine."Line No.");
            Validate("Item No.", ProdOrderComp."Item No.");
            Validate("Prod. Order Comp. Line No.", ProdOrderComp."Line No.");
            Validate("Unit of Measure Code", ProdOrderComp."Unit of Measure Code");
            Description := ProdOrderComp.Description;
            Validate(Quantity, QtyToPost);
            Validate("Unit Cost", ProdOrderComp."Unit Cost");
            "Location Code" := ProdOrderComp."Location Code";
            "Bin Code" := ProdOrderComp."Bin Code";
            "Variant Code" := ProdOrderComp."Variant Code";
            "Source Code" := SourceCodeSetup.Flushing;
            "Gen. Bus. Posting Group" := ProdOrder."Gen. Bus. Posting Group";
            "Gen. Prod. Posting Group" := CompItem."Gen. Prod. Posting Group";
            OnPostFlushedConsumpOnAfterCopyProdOrderFieldsToItemJnlLine(ItemJnlLine, OldItemJnlLine, ProdOrderLine, ProdOrderComp, CompItem);

            OldTempTrackingSpecification.Reset();
            OldTempTrackingSpecification.DeleteAll();
            TempTrackingSpecification.Reset();
            if TempTrackingSpecification.FindSet() then
                repeat
                    OldTempTrackingSpecification := TempTrackingSpecification;
                    OldTempTrackingSpecification.Insert();
                until TempTrackingSpecification.Next() = 0;
            OnPostFlushedConsumpOnBeforeProdOrderCompReserveTransferPOCompToItemJnlLine(ItemJnlLine, ProdOrderComp);
            ProdOrderCompReserve.TransferPOCompToItemJnlLine(
              ProdOrderComp, ItemJnlLine, Round(QtyToPost * ProdOrderComp."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision()));

            OnBeforePostFlushedConsumpItemJnlLine(ItemJnlLine);

            PrepareItem(ItemJnlLine);
            TrackingSpecExists := ItemTrackingMgt.RetrieveItemTracking(ItemJnlLine, TempTrackingSpecification);
            OnPostFlushedConsumpOnBeforeSetupSplitJnlLine(ItemJnlLine);
            PostItemJnlLine := SetupSplitJnlLine(ItemJnlLine, TrackingSpecExists);

            while SplitItemJnlLine(ItemJnlLine, PostItemJnlLine) do begin
                ItemJnlLine.CheckTrackingIfRequiredNotBlank(GlobalItemTrackingSetup);

                if not DimsAreTaken then begin
                    "Dimension Set ID" := GetCombinedDimSetID(ProdOrderLine."Dimension Set ID", ProdOrderComp."Dimension Set ID");
                    OnPostFlushedConsumptionOnAfterSetDimensionSetID(ItemJnlLine, ProdOrderLine);
                    DimsAreTaken := true;
                end;
                ItemJnlCheckLine.RunCheck(ItemJnlLine);
                ProdOrderCompModified := true;
                Quantity := "Quantity (Base)";
                "Invoiced Quantity" := "Invoiced Qty. (Base)";
                QtyPerUnitOfMeasure := "Qty. per Unit of Measure";

                "Unit Amount" := Round(
                    "Unit Amount" / QtyPerUnitOfMeasure, GLSetup."Unit-Amount Rounding Precision");
                "Unit Cost" := Round(
                    "Unit Cost" / QtyPerUnitOfMeasure, GLSetup."Unit-Amount Rounding Precision");
                "Unit Cost (ACY)" := Round(
                    "Unit Cost (ACY)" / QtyPerUnitOfMeasure, Currency."Unit-Amount Rounding Precision");
                PostConsumption();
            end;

            TempTrackingSpecification.Reset();
            TempTrackingSpecification.DeleteAll();
            if OldTempTrackingSpecification.FindSet() then
                repeat
                    TempTrackingSpecification := OldTempTrackingSpecification;
                    TempTrackingSpecification.Insert();
                until OldTempTrackingSpecification.Next() = 0;
        end;

        OnAfterPostFlushedConsump(ProdOrderComp, ProdOrderRoutingLine, OldItemJnlLine);
    end;

    procedure UpdateUnitCost(ValueEntry: Record "Value Entry")
    var
        ItemCostMgt: Codeunit ItemCostManagement;
        LastDirectCost: Decimal;
        TotalAmount: Decimal;
        IsHandled: Boolean;
        UpdateSKU: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateUnitCost(ValueEntry, IsHandled, ItemJnlLine);
        if IsHandled then
            exit;

        with ValueEntry do
            if ("Valued Quantity" > 0) and not ("Expected Cost" or ItemJnlLine.Adjustment) then begin
                Item.LockTable();
                if not Item.Find() then
                    exit;

                if IsInbound() and
                   (("Cost Amount (Actual)" + "Discount Amount" > 0) or Item.IsNonInventoriableType()) and
                   (ItemJnlLine."Value Entry Type" = ItemJnlLine."Value Entry Type"::"Direct Cost") and
                   (ItemJnlLine."Item Charge No." = '') and not Item."Inventory Value Zero"
                then begin
                    TotalAmount := ItemJnlLine.Amount + ItemJnlLine."Discount Amount";
                    IsHandled := false;
                    OnUpdateUnitCostOnBeforeCalculateLastDirectCost(TotalAmount, ItemJnlLine, ValueEntry, Item, IsHandled);
                    if not IsHandled then
                        LastDirectCost := Round(TotalAmount / "Valued Quantity", GLSetup."Unit-Amount Rounding Precision")
                end;

                if "Drop Shipment" then begin
                    if LastDirectCost <> 0 then begin
                        Item."Last Direct Cost" := LastDirectCost;
                        OnUpdateUnitCostOnAfterAssignLastDirectCost(ValueEntry, Item, LastDirectCost);
                        Item.Modify();
                        ItemCostMgt.SetProperties(false, "Invoiced Quantity");
                        ItemCostMgt.FindUpdateUnitCostSKU(Item, "Location Code", "Variant Code", true, LastDirectCost);
                    end;
                end else begin
                    UpdateSKU := true;
                    OnUpdateUnitCostOnBeforeUpdateUnitCost(ItemJnlLine, ValueEntry, Item, UpdateSKU);
                    ItemCostMgt.SetProperties(false, "Invoiced Quantity");
                    ItemCostMgt.UpdateUnitCost(Item, "Location Code", "Variant Code", LastDirectCost, 0, UpdateSKU, true, false, 0);
                end;
            end;
        OnAfterUpdateUnitCost(ValueEntry, LastDirectCost, ItemJnlLine);
    end;

    procedure UnApply(ItemApplnEntry: Record "Item Application Entry")
    var
        ItemLedgEntry1: Record "Item Ledger Entry";
        ItemLedgEntry2: Record "Item Ledger Entry";
        CostItemLedgEntry: Record "Item Ledger Entry";
        InventoryPeriod: Record "Inventory Period";
        Valuationdate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUnApply(ItemApplnEntry, IsHandled);
        if IsHandled then
            exit;

        if not InventoryPeriod.IsValidDate(ItemApplnEntry."Posting Date") then
            InventoryPeriod.ShowError(ItemApplnEntry."Posting Date");

        // If we can't get both entries then the application is not a real application or a date compression might have been done
        ItemLedgEntry1.Get(ItemApplnEntry."Inbound Item Entry No.");
        ItemLedgEntry2.Get(ItemApplnEntry."Outbound Item Entry No.");

        if ItemApplnEntry."Item Ledger Entry No." = ItemApplnEntry."Inbound Item Entry No." then
            CheckItemCorrection(ItemLedgEntry1);
        if ItemApplnEntry."Item Ledger Entry No." = ItemApplnEntry."Outbound Item Entry No." then
            CheckItemCorrection(ItemLedgEntry2);

        if ItemLedgEntry1."Drop Shipment" and ItemLedgEntry2."Drop Shipment" then
            Error(Text024);

        if ItemLedgEntry2."Entry Type" = ItemLedgEntry2."Entry Type"::Transfer then
            Error(Text023);

        ItemApplnEntry.TestField("Transferred-from Entry No.", 0);

        // We won't allow deletion of applications for deleted items
        GetItem(ItemLedgEntry1."Item No.", true);
        CostItemLedgEntry.Get(ItemApplnEntry.CostReceiver()); // costreceiver

        OnUnApplyOnBeforeUpdateItemLedgerEntries(ItemLedgEntry1, ItemLedgEntry2, ItemApplnEntry);

        if ItemLedgEntry1."Applies-to Entry" = ItemLedgEntry2."Entry No." then
            ItemLedgEntry1."Applies-to Entry" := 0;

        if ItemLedgEntry2."Applies-to Entry" = ItemLedgEntry1."Entry No." then
            ItemLedgEntry2."Applies-to Entry" := 0;

        // only if real/quantity application
        if not ItemApplnEntry.CostApplication() then begin
            ItemLedgEntry1."Remaining Quantity" := ItemLedgEntry1."Remaining Quantity" - ItemApplnEntry.Quantity;
            ItemLedgEntry1.Open := ItemLedgEntry1."Remaining Quantity" <> 0;
            ItemLedgEntry1.Modify();

            ItemLedgEntry2."Remaining Quantity" := ItemLedgEntry2."Remaining Quantity" + ItemApplnEntry.Quantity;
            ItemLedgEntry2.Open := ItemLedgEntry2."Remaining Quantity" <> 0;
            ItemLedgEntry2.Modify();
        end else begin
            ItemLedgEntry2."Shipped Qty. Not Returned" := ItemLedgEntry2."Shipped Qty. Not Returned" - Abs(ItemApplnEntry.Quantity);
            if Abs(ItemLedgEntry2."Shipped Qty. Not Returned") > Abs(ItemLedgEntry2.Quantity) then
                ItemLedgEntry2.FieldError("Shipped Qty. Not Returned", Text004); // Assert - should never happen
            ItemLedgEntry2.Modify();

            OnUnApplyOnBeforeInsertApplEntry(ItemApplnEntry);
            // If cost application we need to insert a 0 application instead if there is none before
            if ItemApplnEntry.Quantity > 0 then
                if not ZeroApplication(ItemApplnEntry."Item Ledger Entry No.") then
                    InsertApplEntry(
                      ItemApplnEntry."Item Ledger Entry No.", ItemApplnEntry."Inbound Item Entry No.",
                      0, 0, ItemApplnEntry."Posting Date", ItemApplnEntry.Quantity, true);
        end;

        if Item."Costing Method" = Item."Costing Method"::Average then
            if not ItemApplnEntry.Fixed() then
                UpdateValuedByAverageCost(CostItemLedgEntry."Entry No.", true);

        ItemApplnEntry.InsertHistory();
        TouchEntry(ItemApplnEntry."Inbound Item Entry No.");
        SaveTouchedEntry(ItemApplnEntry."Inbound Item Entry No.", true);
        if ItemApplnEntry."Outbound Item Entry No." <> 0 then begin
            TouchEntry(ItemApplnEntry."Outbound Item Entry No.");
            SaveTouchedEntry(ItemApplnEntry."Inbound Item Entry No.", false);
        end;

        OnUnApplyOnBeforeItemApplnEntryDelete(ItemApplnEntry);
        ItemApplnEntry.Delete();

        Valuationdate := GetMaxAppliedValuationdate(CostItemLedgEntry);
        if Valuationdate = 0D then
            Valuationdate := CostItemLedgEntry."Posting Date"
        else
            Valuationdate := Max(CostItemLedgEntry."Posting Date", Valuationdate);

        SetValuationDateAllValueEntrie(CostItemLedgEntry."Entry No.", Valuationdate, false);

        UpdateLinkedValuationUnapply(Valuationdate, CostItemLedgEntry."Entry No.", CostItemLedgEntry.Positive);
    end;

    procedure ReApply(ItemLedgEntry: Record "Item Ledger Entry"; ApplyWith: Integer)
    var
        ItemLedgEntry2: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        InventoryPeriod: Record "Inventory Period";
        CostApplication: Boolean;
    begin
        GetItem(ItemLedgEntry."Item No.", true);

        if not InventoryPeriod.IsValidDate(ItemLedgEntry."Posting Date") then
            InventoryPeriod.ShowError(ItemLedgEntry."Posting Date");

        GlobalItemTrackingCode.Code := Item."Item Tracking Code";
        OnReApplyOnBeforeGetItemTrackingSetup(Item, GlobalItemTrackingCode);
        ItemTrackingMgt.GetItemTrackingSetup(
            GlobalItemTrackingCode, ItemJnlLine."Entry Type",
            ItemJnlLine.Signed(ItemJnlLine."Quantity (Base)") > 0, GlobalItemTrackingSetup);

        TotalAppliedQty := 0;
        CostApplication := false;
        if ApplyWith <> 0 then begin
            ItemLedgEntry2.Get(ApplyWith);
            if ItemLedgEntry2.Quantity > 0 then begin
                // Switch around so ItemLedgEntry is positive and ItemLedgEntry2 is negative
                OldItemLedgEntry := ItemLedgEntry;
                ItemLedgEntry := ItemLedgEntry2;
                ItemLedgEntry2 := OldItemLedgEntry;
            end;

            OnReApplyOnBeforeStartApply(ItemLedgEntry, ItemLedgEntry2);

            if not ((ItemLedgEntry.Quantity > 0) and // not(Costprovider(ItemLedgEntry))
                    ((ItemLedgEntry."Entry Type" = ItemLedgEntry2."Entry Type"::Purchase) or
                     (ItemLedgEntry."Entry Type" = ItemLedgEntry2."Entry Type"::"Positive Adjmt.") or
                     (ItemLedgEntry."Entry Type" = ItemLedgEntry2."Entry Type"::Output) or
                     (ItemLedgEntry."Entry Type" = ItemLedgEntry2."Entry Type"::"Assembly Output"))
                    )
            then
                CostApplication := true;
            if (ItemLedgEntry."Remaining Quantity" <> 0) and (ItemLedgEntry2."Remaining Quantity" <> 0) then
                CostApplication := false;
            if CostApplication then
                CostApply(ItemLedgEntry, ItemLedgEntry2)
            else begin
                CreateItemJnlLineFromEntry(ItemLedgEntry2, ItemLedgEntry2."Remaining Quantity", ItemJnlLine);
                if ApplyWith = ItemLedgEntry2."Entry No." then
                    ItemLedgEntry2."Applies-to Entry" := ItemLedgEntry."Entry No."
                else
                    ItemLedgEntry2."Applies-to Entry" := ApplyWith;
                ItemJnlLine."Applies-to Entry" := ItemLedgEntry2."Applies-to Entry";
                GlobalItemLedgEntry := ItemLedgEntry2;
                ApplyItemLedgEntry(ItemLedgEntry2, OldItemLedgEntry, ValueEntry, false);
                TouchItemEntryCost(ItemLedgEntry2, false);
                ItemLedgEntry2.Modify();
                EnsureValueEntryLoaded(ValueEntry, ItemLedgEntry2);
                GetValuationDate(ValueEntry, ItemLedgEntry);
                UpdateLinkedValuationDate(ValueEntry."Valuation Date", GlobalItemLedgEntry."Entry No.", GlobalItemLedgEntry.Positive);
            end;

            if ItemApplnEntry.Fixed() and (ItemApplnEntry.CostReceiver() <> 0) then
                if GetItem(ItemLedgEntry."Item No.", false) then
                    if Item."Costing Method" = Item."Costing Method"::Average then
                        UpdateValuedByAverageCost(ItemApplnEntry.CostReceiver(), false);
        end else begin  // ApplyWith is 0
            ItemLedgEntry."Applies-to Entry" := ApplyWith;
            CreateItemJnlLineFromEntry(ItemLedgEntry, ItemLedgEntry."Remaining Quantity", ItemJnlLine);
            ItemJnlLine."Applies-to Entry" := ItemLedgEntry."Applies-to Entry";
            GlobalItemLedgEntry := ItemLedgEntry;
            ApplyItemLedgEntry(ItemLedgEntry, OldItemLedgEntry, ValueEntry, false);
            TouchItemEntryCost(ItemLedgEntry, false);
            ItemLedgEntry.Modify();
            EnsureValueEntryLoaded(ValueEntry, ItemLedgEntry);
            GetValuationDate(ValueEntry, ItemLedgEntry);
            UpdateLinkedValuationDate(ValueEntry."Valuation Date", GlobalItemLedgEntry."Entry No.", GlobalItemLedgEntry.Positive);
        end;
    end;

    local procedure CostApply(var ItemLedgEntry: Record "Item Ledger Entry"; ItemLedgEntry2: Record "Item Ledger Entry")
    var
        ApplyWithItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        if ItemLedgEntry.Quantity > 0 then begin
            GlobalItemLedgEntry := ItemLedgEntry;
            ApplyWithItemLedgEntry := ItemLedgEntry2;
        end
        else begin
            GlobalItemLedgEntry := ItemLedgEntry2;
            ApplyWithItemLedgEntry := ItemLedgEntry;
        end;
        if not ItemApplnEntry.CheckIsCyclicalLoop(ApplyWithItemLedgEntry, GlobalItemLedgEntry) then begin
            CreateItemJnlLineFromEntry(GlobalItemLedgEntry, GlobalItemLedgEntry.Quantity, ItemJnlLine);
            OnCostApplyOnBeforeInsertApplEntry(GlobalItemLedgEntry, ApplyWithItemLedgEntry);
            InsertApplEntry(
              GlobalItemLedgEntry."Entry No.", GlobalItemLedgEntry."Entry No.",
              ApplyWithItemLedgEntry."Entry No.", 0, GlobalItemLedgEntry."Posting Date",
              GlobalItemLedgEntry.Quantity, true);
            UpdateOutboundItemLedgEntry(ApplyWithItemLedgEntry."Entry No.");
            OldItemLedgEntry.Get(ApplyWithItemLedgEntry."Entry No.");
            EnsureValueEntryLoaded(ValueEntry, GlobalItemLedgEntry);
            ItemJnlLine."Applies-from Entry" := ApplyWithItemLedgEntry."Entry No.";
            GetAppliedFromValues(ValueEntry);
            SetValuationDateAllValueEntrie(GlobalItemLedgEntry."Entry No.", ValueEntry."Valuation Date", false);
            UpdateLinkedValuationDate(ValueEntry."Valuation Date", GlobalItemLedgEntry."Entry No.", GlobalItemLedgEntry.Positive);
            TouchItemEntryCost(ItemLedgEntry2, false);
        end;
    end;

    local procedure ZeroApplication(EntryNo: Integer): Boolean
    var
        Application: Record "Item Application Entry";
    begin
        Application.SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.");
        Application.SetRange("Item Ledger Entry No.", EntryNo);
        Application.SetRange("Inbound Item Entry No.", EntryNo);
        Application.SetRange("Outbound Item Entry No.", 0);
        exit(not Application.IsEmpty);
    end;

    procedure ApplyItemLedgEntry(var ItemLedgEntry: Record "Item Ledger Entry"; var OldItemLedgEntry: Record "Item Ledger Entry"; var ValueEntry: Record "Value Entry"; CausedByTransfer: Boolean)
    var
        ItemLedgEntry2: Record "Item Ledger Entry";
        OldValueEntry: Record "Value Entry";
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        AppliesFromItemLedgEntry: Record "Item Ledger Entry";
        EntryFindMethod: Text[1];
        AppliedQty: Decimal;
        FirstReservation: Boolean;
        FirstApplication: Boolean;
        StartApplication: Boolean;
        UseReservationApplication: Boolean;
        Handled: Boolean;
    begin
        OnBeforeApplyItemLedgEntry(ItemLedgEntry, OldItemLedgEntry, ValueEntry, CausedByTransfer, Handled, ItemJnlLine, ItemApplnEntryNo);
        if Handled then
            exit;

        if (ItemLedgEntry."Remaining Quantity" = 0) or
           (ItemLedgEntry."Drop Shipment" and (ItemLedgEntry."Applies-to Entry" = 0)) or
           ((Item."Costing Method" = Item."Costing Method"::Specific) and ItemLedgEntry.Positive) or
           (ItemJnlLine."Direct Transfer" and (ItemLedgEntry."Location Code" = '') and ItemLedgEntry.Positive)
        then
            exit;

        Clear(OldItemLedgEntry);
        FirstReservation := true;
        FirstApplication := true;
        StartApplication := false;
        repeat
            if ItemJnlLine."Assemble to Order" then
                VerifyItemJnlLineAsembleToOrder(ItemJnlLine)
            else
                VerifyItemJnlLineApplication(ItemJnlLine, ItemLedgEntry);

            if not CausedByTransfer and not PostponeReservationHandling then begin
                if Item."Costing Method" = Item."Costing Method"::Specific then
                    ItemJnlLine.TestField("Serial No.");

                Handled := false;
                OnApplyItemLedgEntryOnBeforeFirstReservationSetFilters(ItemJnlLine, StartApplication, FirstReservation, Handled);
                if not Handled then
                    if FirstReservation then begin
                        FirstReservation := false;
                        ReservEntry.Reset();
                        ReservEntry.SetCurrentKey(
                          "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
                          "Source Batch Name", "Source Prod. Order Line", "Reservation Status");
                        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
                        ItemJnlLine.SetReservationFilters(ReservEntry);
                        ReservEntry.SetRange("Item No.", ItemJnlLine."Item No.");
                    end;

                UseReservationApplication := ReservEntry.FindFirst();

                Handled := false;
                OnApplyItemLedgEntryOnBeforeCloseSurplusTrackingEntry(ItemJnlLine, StartApplication, UseReservationApplication, Handled);
                if not Handled then
                    if not UseReservationApplication then begin // No reservations exist
                        ReservEntry.SetRange(
                          "Reservation Status", ReservEntry."Reservation Status"::Tracking,
                          ReservEntry."Reservation Status"::Prospect);
                        if ReservEntry.FindSet() then
                            repeat
                                ReservEngineMgt.CloseSurplusTrackingEntry(ReservEntry);
                            until ReservEntry.Next() = 0;
                        StartApplication := true;
                    end;

                if UseReservationApplication then begin
                    ReservEntry2.Get(ReservEntry."Entry No.", not ReservEntry.Positive);
                    if ReservEntry2."Source Type" <> DATABASE::"Item Ledger Entry" then
                        if ItemLedgEntry.Quantity < 0 then
                            Error(Text003, ReservEntry."Item No.");
                    OldItemLedgEntry.Get(ReservEntry2."Source Ref. No.");
                    if ItemLedgEntry.Quantity < 0 then
                        if OldItemLedgEntry."Remaining Quantity" < ReservEntry2."Quantity (Base)" then
                            Error(Text003, ReservEntry2."Item No.");

                    OldItemLedgEntry.TestField("Item No.", ItemJnlLine."Item No.");
                    OldItemLedgEntry.TestField("Variant Code", ItemJnlLine."Variant Code");
                    OldItemLedgEntry.TestField("Location Code", ItemJnlLine."Location Code");
                    OnApplyItemLedgEntryOnBeforeCloseReservEntry(OldItemLedgEntry, ItemJnlLine, ItemLedgEntry);
                    ReservEngineMgt.CloseReservEntry(ReservEntry, false, false);
                    OnApplyItemLedgEntryOnAfterCloseReservEntry(OldItemLedgEntry, ItemJnlLine, ItemLedgEntry, ReservEntry);
                    OldItemLedgEntry.CalcReservedQuantity();
                    AppliedQty := -Abs(ReservEntry."Quantity (Base)");
                end;
            end else
                StartApplication := true;

            OnApplyItemLedgEntryOnBeforeStartApplication(ItemLedgEntry, OldItemLedgEntry, StartApplication, AppliedQty);

            if StartApplication then begin
                ItemLedgEntry.CalcReservedQuantity();
                if ItemLedgEntry."Applies-to Entry" <> 0 then begin
                    if FirstApplication then begin
                        FirstApplication := false;
                        OldItemLedgEntry.Get(ItemLedgEntry."Applies-to Entry");
                        TestFirstApplyItemLedgEntry(OldItemLedgEntry, ItemLedgEntry);
                    end else
                        exit;
                end else begin
                    if FirstApplication then begin
                        FirstApplication := false;
                        ApplyItemLedgEntrySetFilters(ItemLedgEntry2, ItemLedgEntry, GlobalItemTrackingCode);

                        if Item."Costing Method" = Item."Costing Method"::LIFO then
                            EntryFindMethod := '+'
                        else
                            EntryFindMethod := '-';
                        if not ItemLedgEntry2.Find(EntryFindMethod) then
                            exit;
                    end else
                        case EntryFindMethod of
                            '-':
                                if ItemLedgEntry2.Next() = 0 then
                                    exit;
                            '+':
                                if ItemLedgEntry2.Next(-1) = 0 then
                                    exit;
                        end;
                    OldItemLedgEntry.Copy(ItemLedgEntry2)
                end;

                OldItemLedgEntry.CalcReservedQuantity();
                OnAfterApplyItemLedgEntryOnBeforeCalcAppliedQty(OldItemLedgEntry, ItemLedgEntry);

                if Abs(OldItemLedgEntry."Remaining Quantity" - OldItemLedgEntry."Reserved Quantity") >
                   Abs(ItemLedgEntry."Remaining Quantity" - ItemLedgEntry."Reserved Quantity")
                then
                    AppliedQty := ItemLedgEntry."Remaining Quantity" - ItemLedgEntry."Reserved Quantity"
                else
                    AppliedQty := -(OldItemLedgEntry."Remaining Quantity" - OldItemLedgEntry."Reserved Quantity");

                OnApplyItemLedgEntryOnAfterCalcAppliedQty(OldItemLedgEntry, ItemLedgEntry, AppliedQty);

                if ItemLedgEntry."Entry Type" = ItemLedgEntry."Entry Type"::Transfer then
                    if (OldItemLedgEntry."Entry No." > ItemLedgEntry."Entry No.") and not ItemLedgEntry.Positive then
                        AppliedQty := 0;
                if (OldItemLedgEntry."Order Type" = OldItemLedgEntry."Order Type"::Production) and
                   (OldItemLedgEntry."Order No." <> '')
                then
                    if not AllowProdApplication(OldItemLedgEntry, ItemLedgEntry) then
                        AppliedQty := 0;
                if ItemJnlLine."Applies-from Entry" <> 0 then begin
                    AppliesFromItemLedgEntry.Get(ItemJnlLine."Applies-from Entry");
                    if ItemApplnEntry.CheckIsCyclicalLoop(AppliesFromItemLedgEntry, OldItemLedgEntry) then
                        AppliedQty := 0;
                end;
                OnApplyItemLedgEntryOnAfterSetAppliedQtyZero(OldItemLedgEntry, ItemLedgEntry, AppliedQty);
            end;

            CheckIsCyclicalLoop(ItemLedgEntry, OldItemLedgEntry, PrevAppliedItemLedgEntry, AppliedQty);

            if AppliedQty <> 0 then begin
                if not OldItemLedgEntry.Positive and
                   (OldItemLedgEntry."Remaining Quantity" = -AppliedQty) and
                   (OldItemLedgEntry."Entry No." = ItemLedgEntry."Applies-to Entry")
                then begin
                    OldValueEntry.SetCurrentKey("Item Ledger Entry No.");
                    OldValueEntry.SetRange("Item Ledger Entry No.", OldItemLedgEntry."Entry No.");
                    if OldValueEntry.Find('-') then
                        repeat
                            if OldValueEntry."Valued By Average Cost" then begin
                                OldValueEntry."Valued By Average Cost" := false;
                                OldValueEntry.Modify();
                            end;
                        until OldValueEntry.Next() = 0;
                end;

                UpdateOldItemLedgerEntryRemainingQuantity(OldItemLedgEntry, AppliedQty);

                if ItemLedgEntry.Positive then begin
                    OnApplyItemLedgEntryOnItemLedgEntryPositiveOnBeforeInsertApplEntry(OldItemLedgEntry, ItemLedgEntry, GlobalItemLedgEntry, AppliedQty);
                    if ItemLedgEntry."Posting Date" >= OldItemLedgEntry."Posting Date" then
                        InsertApplEntry(
                          OldItemLedgEntry."Entry No.", ItemLedgEntry."Entry No.",
                          OldItemLedgEntry."Entry No.", 0, ItemLedgEntry."Posting Date", -AppliedQty, false)
                    else
                        InsertApplEntry(
                          OldItemLedgEntry."Entry No.", ItemLedgEntry."Entry No.",
                          OldItemLedgEntry."Entry No.", 0, OldItemLedgEntry."Posting Date", -AppliedQty, false);

                    if ItemApplnEntry."Cost Application" then
                        ItemLedgEntry."Applied Entry to Adjust" := true;
                end else begin
                    OnApplyItemLedgEntryOnBeforeCheckApplyEntry(OldItemLedgEntry);

                    CheckPostingDateWithExpirationDate(ItemLedgEntry);

                    OnApplyItemLedgEntryOnBeforeInsertApplEntry(ItemLedgEntry, ItemJnlLine, OldItemLedgEntry, GlobalItemLedgEntry, AppliedQty);

                    InsertApplEntry(
                      ItemLedgEntry."Entry No.", OldItemLedgEntry."Entry No.", ItemLedgEntry."Entry No.", 0,
                      ItemLedgEntry."Posting Date", AppliedQty, true);

                    if ItemApplnEntry."Cost Application" then
                        OldItemLedgEntry."Applied Entry to Adjust" := true;
                end;

                OnApplyItemLedgEntryOnBeforeOldItemLedgEntryModify(ItemLedgEntry, OldItemLedgEntry, ItemJnlLine);
                OldItemLedgEntry.Modify();
                AutoTrack(OldItemLedgEntry, true);

                EnsureValueEntryLoaded(ValueEntry, ItemLedgEntry);
                GetValuationDate(ValueEntry, OldItemLedgEntry);

                if (ItemLedgEntry."Entry Type" = ItemLedgEntry."Entry Type"::Transfer) and
                   (AppliedQty < 0) and
                   not CausedByTransfer and
                   not ItemLedgEntry.Correction
                then begin
                    if ItemLedgEntry."Completely Invoiced" then
                        ItemLedgEntry."Completely Invoiced" := OldItemLedgEntry."Completely Invoiced";
                    if AverageTransfer then
                        TotalAppliedQty := TotalAppliedQty + AppliedQty
                    else
                        InsertTransferEntry(ItemLedgEntry, OldItemLedgEntry, AppliedQty);
                end;

                UpdateItemLedgerEntryRemainingQuantity(ItemLedgEntry, AppliedQty, OldItemLedgEntry, CausedByTransfer);

                ItemLedgEntry.CalcReservedQuantity();
                if ItemLedgEntry."Remaining Quantity" + ItemLedgEntry."Reserved Quantity" = 0 then
                    exit;
            end;
            OnApplyItemLedgEntryOnApplicationLoop(ItemLedgEntry);
        until false;
#if not CLEAN21
        OnAfterApplyItemLedgEntry(GlobalItemLedgEntry, OldItemLedgEntry, ItemJnlLine);
#endif        
    end;

    local procedure UpdateItemLedgerEntryRemainingQuantity(var ItemLedgerEntry: Record "Item Ledger Entry"; AppliedQty: Decimal; var OldItemLedgEntry: Record "Item Ledger Entry"; CausedByTransfer: Boolean)
    begin
        OnBeforeUpdateItemLedgerEntryRemainingQuantity(ItemLedgerEntry, OldItemLedgEntry, AppliedQty, CausedByTransfer, AverageTransfer);

        ItemLedgerEntry."Remaining Quantity" := ItemLedgerEntry."Remaining Quantity" - AppliedQty;
        ItemLedgerEntry.Open := ItemLedgerEntry."Remaining Quantity" <> 0;

        OnAfterUpdateItemLedgerEntryRemainingQuantity(ItemLedgerEntry, AppliedQty);
    end;

    local procedure CheckPostingDateWithExpirationDate(var ItemLedgEntry: Record "Item Ledger Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPostingDateWithExpirationDate(ItemLedgEntry, GlobalItemTrackingCode, OldItemLedgEntry, IsHandled, ItemJnlLine);
        if IsHandled then
            exit;

        if GlobalItemTrackingCode."Strict Expiration Posting" and (OldItemLedgEntry."Expiration Date" <> 0D) and
           not ItemLedgEntry.Correction and
           not (ItemLedgEntry."Document Type" in
                [ItemLedgEntry."Document Type"::"Purchase Return Shipment", ItemLedgEntry."Document Type"::"Purchase Credit Memo"])
        then
            if ItemLedgEntry."Posting Date" > OldItemLedgEntry."Expiration Date" then
                if (ItemLedgEntry."Entry Type" <> ItemLedgEntry."Entry Type"::"Negative Adjmt.") and
                   not ItemJnlLine.IsReclass(ItemJnlLine)
                then
                    OldItemLedgEntry.FieldError("Expiration Date", Text017);
    end;

    local procedure ApplyItemLedgEntrySetFilters(var ToItemLedgEntry: Record "Item Ledger Entry"; FromItemLedgEntry: Record "Item Ledger Entry"; ItemTrackingCode: Record "Item Tracking Code")
    var
        Location: Record Location;
        ItemTrackingSetup2: Record "Item Tracking Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeApplyItemLedgEntrySetFilters(ToItemLedgEntry, FromItemLedgEntry, ItemTrackingCode, IsHandled);
        if IsHandled then
            exit;

        if FromItemLedgEntry."Serial No." <> '' then
            ToItemLedgEntry.SetCurrentKey("Serial No.", "Item No.", Open, "Variant Code", Positive, "Location Code", "Posting Date")
        else
            ToItemLedgEntry.SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Location Code", "Posting Date");
        ToItemLedgEntry.SetRange("Item No.", FromItemLedgEntry."Item No.");
        ToItemLedgEntry.SetRange(Open, true);
        ToItemLedgEntry.SetRange("Variant Code", FromItemLedgEntry."Variant Code");
        ToItemLedgEntry.SetRange(Positive, not FromItemLedgEntry.Positive);
        ToItemLedgEntry.SetRange("Location Code", FromItemLedgEntry."Location Code");
        if FromItemLedgEntry."Job Purchase" then begin
            ToItemLedgEntry.SetRange("Job No.", FromItemLedgEntry."Job No.");
            ToItemLedgEntry.SetRange("Job Task No.", FromItemLedgEntry."Job Task No.");
            ToItemLedgEntry.SetRange("Document Type", FromItemLedgEntry."Document Type");
            ToItemLedgEntry.SetRange("Document No.", FromItemLedgEntry."Document No.");
        end;
        ItemTrackingSetup2.CopyTrackingFromItemTrackingCodeSpecificTracking(ItemTrackingCode);
        ItemTrackingSetup2.CopyTrackingFromItemLedgerEntry(FromItemLedgEntry);
        ToItemLedgEntry.SetTrackingFilterFromItemTrackingSetupIfRequired(ItemTrackingSetup2);
        if (Location.Get(FromItemLedgEntry."Location Code") and Location."Use As In-Transit") or
           (FromItemLedgEntry."Location Code" = '') and
           (FromItemLedgEntry."Document Type" = FromItemLedgEntry."Document Type"::"Transfer Receipt")
        then begin
            ToItemLedgEntry.SetRange("Order Type", FromItemLedgEntry."Order Type"::Transfer);
            ToItemLedgEntry.SetRange("Order No.", FromItemLedgEntry."Order No.");
        end;

        OnAfterApplyItemLedgEntrySetFilters(ToItemLedgEntry, FromItemLedgEntry, ItemJnlLine);
    end;

    local procedure TestFirstApplyItemLedgEntry(var OldItemLedgEntry: Record "Item Ledger Entry"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
        OnBeforeTestFirstApplyItemLedgEntry(OldItemLedgEntry, ItemLedgEntry, ItemJnlLine);

        OldItemLedgEntry.TestField("Item No.", ItemLedgEntry."Item No.");
        OldItemLedgEntry.TestField("Variant Code", ItemLedgEntry."Variant Code");
        OldItemLedgEntry.TestField(Positive, not ItemLedgEntry.Positive);
        OldItemLedgEntry.TestField("Location Code", ItemLedgEntry."Location Code");
        if Location.Get(ItemLedgEntry."Location Code") then
            if Location."Use As In-Transit" then begin
                OldItemLedgEntry.TestField("Order Type", OldItemLedgEntry."Order Type"::Transfer);
                OldItemLedgEntry.TestField("Order No.", ItemLedgEntry."Order No.");
            end;

        TestFirstApplyItemLedgerEntryTracking(ItemLedgEntry, OldItemLedgEntry, GlobalItemTrackingCode);

        if not (OldItemLedgEntry.Open and
                (Abs(OldItemLedgEntry."Remaining Quantity" - OldItemLedgEntry."Reserved Quantity") >=
                 Abs(ItemLedgEntry."Remaining Quantity" - ItemLedgEntry."Reserved Quantity")))
        then
            if (Abs(OldItemLedgEntry."Remaining Quantity" - OldItemLedgEntry."Reserved Quantity") <=
                Abs(ItemLedgEntry."Remaining Quantity" - ItemLedgEntry."Reserved Quantity"))
            then begin
                if not MoveApplication(ItemLedgEntry, OldItemLedgEntry) then
                    OldItemLedgEntry.FieldError("Remaining Quantity", Text004);
            end else
                OldItemLedgEntry.TestField(Open, true);

        OnTestFirstApplyItemLedgEntryOnAfterTestFields(ItemLedgEntry, OldItemLedgEntry, ItemJnlLine);

        OldItemLedgEntry.CalcReservedQuantity();
        CheckApplication(ItemLedgEntry, OldItemLedgEntry);

        if Abs(OldItemLedgEntry."Remaining Quantity") <= Abs(OldItemLedgEntry."Reserved Quantity") then
            ReservationPreventsApplication(ItemLedgEntry."Applies-to Entry", ItemLedgEntry."Item No.", OldItemLedgEntry);

        if (OldItemLedgEntry."Order Type" = OldItemLedgEntry."Order Type"::Production) and
           (OldItemLedgEntry."Order No." <> '')
        then
            if not AllowProdApplication(OldItemLedgEntry, ItemLedgEntry) then
                Error(
                  Text022,
                  ItemLedgEntry."Entry Type", OldItemLedgEntry."Entry Type", OldItemLedgEntry."Item No.", OldItemLedgEntry."Order No.");
    end;

    local procedure TestFirstApplyItemLedgerEntryTracking(ItemLedgEntry: Record "Item Ledger Entry"; OldItemLedgEntry: Record "Item Ledger Entry"; ItemTrackingCode: Record "Item Tracking Code");
    begin
        if ItemTrackingCode."SN Specific Tracking" then
            OldItemLedgEntry.TestField("Serial No.", ItemLedgEntry."Serial No.");
        if ItemLedgEntry."Drop Shipment" and (OldItemLedgEntry."Serial No." <> '') then
            OldItemLedgEntry.TestField("Serial No.", ItemLedgEntry."Serial No.");

        if ItemTrackingCode."Lot Specific Tracking" then
            OldItemLedgEntry.TestField("Lot No.", ItemLedgEntry."Lot No.");
        if ItemLedgEntry."Drop Shipment" and (OldItemLedgEntry."Lot No." <> '') then
            OldItemLedgEntry.TestField("Lot No.", ItemLedgEntry."Lot No.");

        OnAfterTestFirstApplyItemLedgerEntryTracking(ItemLedgEntry, OldItemLedgEntry, ItemTrackingCode);
    end;

    local procedure UpdateOldItemLedgerEntryRemainingQuantity(var OldItemLedgerEntry: Record "Item Ledger Entry"; AppliedQty: Decimal)
    begin
        OldItemLedgerEntry."Remaining Quantity" := OldItemLedgerEntry."Remaining Quantity" + AppliedQty;
        OldItemLedgerEntry.Open := OldItemLedgerEntry."Remaining Quantity" <> 0;

        OnAfterUpdateOldItemLedgerEntryRemainingQuantity(OldItemLedgerEntry, AppliedQty);
    end;

    local procedure EnsureValueEntryLoaded(var ValueEntry: Record "Value Entry"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
        if ValueEntry.Find('-') then;
    end;

    local procedure AllowProdApplication(OldItemLedgEntry: Record "Item Ledger Entry"; ItemLedgEntry: Record "Item Ledger Entry"): Boolean
    var
        AllowApplication: Boolean;
    begin
        AllowApplication :=
          (OldItemLedgEntry."Entry Type" = ItemLedgEntry."Entry Type") or
          (OldItemLedgEntry."Order No." <> ItemLedgEntry."Order No.") or
          ((OldItemLedgEntry."Order No." = ItemLedgEntry."Order No.") and
           (OldItemLedgEntry."Order Line No." <> ItemLedgEntry."Order Line No."));

        OnBeforeAllowProdApplication(OldItemLedgEntry, ItemLedgEntry, AllowApplication);
        exit(AllowApplication);
    end;

    local procedure InitValueEntryNo()
    begin
        if ValueEntryNo > 0 then
            exit;

        GlobalValueEntry.LockTable();
        ValueEntryNo := GlobalValueEntry.GetLastEntryNo();
    end;

    local procedure InsertTransferEntry(var ItemLedgEntry: Record "Item Ledger Entry"; var OldItemLedgEntry: Record "Item Ledger Entry"; AppliedQty: Decimal)
    var
        NewItemLedgEntry: Record "Item Ledger Entry";
        NewValueEntry: Record "Value Entry";
        ItemLedgEntry2: Record "Item Ledger Entry";
        IsReserved: Boolean;
        IsHandled: Boolean;
    begin
        with ItemJnlLine do begin
            InitItemLedgEntry(NewItemLedgEntry);
            NewItemLedgEntry."Applies-to Entry" := 0;
            NewItemLedgEntry.Quantity := -AppliedQty;
            NewItemLedgEntry."Invoiced Quantity" := NewItemLedgEntry.Quantity;
            NewItemLedgEntry."Remaining Quantity" := NewItemLedgEntry.Quantity;
            NewItemLedgEntry.Open := NewItemLedgEntry."Remaining Quantity" <> 0;
            NewItemLedgEntry.Positive := NewItemLedgEntry."Remaining Quantity" > 0;
            NewItemLedgEntry."Location Code" := "New Location Code";
            NewItemLedgEntry."Country/Region Code" := "Country/Region Code";
            InsertCountryCode(NewItemLedgEntry, ItemLedgEntry);
            NewItemLedgEntry.CopyTrackingFromNewItemJnlLine(ItemJnlLine);
            NewItemLedgEntry."Expiration Date" := "New Item Expiration Date";
            IsHandled := false;
            OnInsertTransferEntryOnTransferValues(NewItemLedgEntry, OldItemLedgEntry, ItemLedgEntry, ItemJnlLine, TempItemEntryRelation, IsHandled);
            if not IsHandled then
                if Item."Item Tracking Code" <> '' then begin
                    TempItemEntryRelation."Item Entry No." := NewItemLedgEntry."Entry No."; // Save Entry No. in a global variable
                    TempItemEntryRelation.CopyTrackingFromItemLedgEntry(NewItemLedgEntry);
                    OnBeforeTempItemEntryRelationInsert(TempItemEntryRelation, NewItemLedgEntry);
                    TempItemEntryRelation.Insert();
                end;
            OnInsertTransferEntryOnBeforeInitTransValueEntry(TempItemEntryRelation, NewItemLedgEntry, Item);
            InitTransValueEntry(NewValueEntry, NewItemLedgEntry);

            OnInsertTransferEntryOnBeforeInsertApplEntry(NewItemLedgEntry, ItemLedgEntry);
            if AverageTransfer then begin
                InsertApplEntry(
                  NewItemLedgEntry."Entry No.", NewItemLedgEntry."Entry No.", ItemLedgEntry."Entry No.",
                  0, NewItemLedgEntry."Posting Date", NewItemLedgEntry.Quantity, true);
                NewItemLedgEntry."Completely Invoiced" := ItemLedgEntry."Completely Invoiced";
            end else begin
                InsertApplEntry(
                  NewItemLedgEntry."Entry No.", NewItemLedgEntry."Entry No.", ItemLedgEntry."Entry No.",
                  OldItemLedgEntry."Entry No.", NewItemLedgEntry."Posting Date", NewItemLedgEntry.Quantity, true);
                NewItemLedgEntry."Completely Invoiced" := OldItemLedgEntry."Completely Invoiced";
            end;

            IsHandled := false;
            OnInsertTransferEntryOnBeforeCalcIsReserved(ItemJnlLine, TempTrackingSpecification, NewItemLedgEntry, ItemLedgEntry, IsReserved, IsHandled);
            if not IsHandled then
                if NewItemLedgEntry.Quantity > 0 then
                    IsReserved :=
                        ItemJnlLineReserve.TransferItemJnlToItemLedgEntry(
                            ItemJnlLine, NewItemLedgEntry, NewItemLedgEntry."Remaining Quantity", true);

            ApplyItemLedgEntry(NewItemLedgEntry, ItemLedgEntry2, NewValueEntry, true);
            AutoTrack(NewItemLedgEntry, IsReserved);

            OnBeforeInsertTransferEntry(NewItemLedgEntry, OldItemLedgEntry, ItemJnlLine);

            InsertItemLedgEntry(NewItemLedgEntry, true);
            InsertValueEntry(NewValueEntry, NewItemLedgEntry, true);

            UpdateUnitCost(NewValueEntry);

            OnAfterInsertTransferEntry(ItemJnlLine, NewItemLedgEntry, OldItemLedgEntry);
        end;
    end;

    procedure InitItemLedgEntry(var ItemLedgEntry: Record "Item Ledger Entry")
    begin
        ItemLedgEntryNo := ItemLedgEntryNo + 1;

        with ItemJnlLine do begin
            ItemLedgEntry.Init();
            ItemLedgEntry."Entry No." := ItemLedgEntryNo;
            ItemLedgEntry."Item No." := "Item No.";
            ItemLedgEntry."Posting Date" := "Posting Date";
            ItemLedgEntry."Document Date" := "Document Date";
            ItemLedgEntry."Entry Type" := "Entry Type";
            ItemLedgEntry."Source No." := "Source No.";
            ItemLedgEntry."Document No." := "Document No.";
            ItemLedgEntry."Document Type" := "Document Type";
            ItemLedgEntry."Document Line No." := "Document Line No.";
            ItemLedgEntry."Order Type" := "Order Type";
            ItemLedgEntry."Order No." := "Order No.";
            ItemLedgEntry."Order Line No." := "Order Line No.";
            ItemLedgEntry."External Document No." := "External Document No.";
            ItemLedgEntry.Description := Description;
            ItemLedgEntry."Location Code" := "Location Code";
            ItemLedgEntry."Applies-to Entry" := "Applies-to Entry";
            ItemLedgEntry."Source Type" := "Source Type";
            ItemLedgEntry."Transaction Type" := "Transaction Type";
            ItemLedgEntry."Transport Method" := "Transport Method";
            ItemLedgEntry."Country/Region Code" := "Country/Region Code";
            if ("Entry Type" = "Entry Type"::Transfer) and ("New Location Code" <> '') then begin
                if NewLocation.Code <> "New Location Code" then
                    NewLocation.Get("New Location Code");
                ItemLedgEntry."Country/Region Code" := NewLocation."Country/Region Code";
            end;
            ItemLedgEntry."Entry/Exit Point" := "Entry/Exit Point";
            ItemLedgEntry.Area := Area;
            ItemLedgEntry."Transaction Specification" := "Transaction Specification";
            ItemLedgEntry."Drop Shipment" := "Drop Shipment";
            ItemLedgEntry."Assemble to Order" := "Assemble to Order";
            ItemLedgEntry."No. Series" := "Posting No. Series";
            GetInvtSetup();
            if (ItemLedgEntry.Description = Item.Description) and not InvtSetup."Copy Item Descr. to Entries" then
                ItemLedgEntry.Description := '';
            ItemLedgEntry."Prod. Order Comp. Line No." := "Prod. Order Comp. Line No.";
            ItemLedgEntry."Variant Code" := "Variant Code";
            ItemLedgEntry."Unit of Measure Code" := "Unit of Measure Code";
            ItemLedgEntry."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
            ItemLedgEntry."Derived from Blanket Order" := "Derived from Blanket Order";
            ItemLedgEntry."Item Reference No." := "Item Reference No.";
            ItemLedgEntry."Originally Ordered No." := "Originally Ordered No.";
            ItemLedgEntry."Originally Ordered Var. Code" := "Originally Ordered Var. Code";
            ItemLedgEntry."Out-of-Stock Substitution" := "Out-of-Stock Substitution";
            ItemLedgEntry."Item Category Code" := "Item Category Code";
            ItemLedgEntry.Nonstock := Nonstock;
            ItemLedgEntry."Purchasing Code" := "Purchasing Code";
            ItemLedgEntry."Return Reason Code" := "Return Reason Code";
            ItemLedgEntry."Job No." := "Job No.";
            ItemLedgEntry."Job Task No." := "Job Task No.";
            ItemLedgEntry."Job Purchase" := "Job Purchase";
            ItemLedgEntry.CopyTrackingFromItemJnlLine(ItemJnlLine);
            ItemLedgEntry."Warranty Date" := "Warranty Date";
            ItemLedgEntry."Expiration Date" := "Item Expiration Date";
            ItemLedgEntry."Shpt. Method Code" := "Shpt. Method Code";

            ItemLedgEntry.Correction := Correction;

            if "Entry Type" in
               ["Entry Type"::Sale,
                "Entry Type"::"Negative Adjmt.",
                "Entry Type"::Transfer,
                "Entry Type"::Consumption,
                "Entry Type"::"Assembly Consumption"]
            then begin
                ItemLedgEntry.Quantity := -Quantity;
                ItemLedgEntry."Invoiced Quantity" := -"Invoiced Quantity";
            end else begin
                ItemLedgEntry.Quantity := Quantity;
                ItemLedgEntry."Invoiced Quantity" := "Invoiced Quantity";
            end;
            if (ItemLedgEntry.Quantity < 0) and ("Entry Type" <> "Entry Type"::Transfer) then
                ItemLedgEntry."Shipped Qty. Not Returned" := ItemLedgEntry.Quantity;
        end;

        OnAfterInitItemLedgEntry(ItemLedgEntry, ItemJnlLine, ItemLedgEntryNo);
    end;

    procedure InsertItemLedgEntry(var ItemLedgEntry: Record "Item Ledger Entry"; TransferItem: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertItemLedgEntryProcedure(ItemLedgEntry, IsHandled, ItemJnlLine);
        if IsHandled then
            exit;

        with ItemJnlLine do begin
            if ItemLedgEntry.Open then begin
                IsHandled := false;
                OnInsertItemLedgEntryOnBeforeVerifyOnInventory(ItemJnlLine, ItemLedgEntry, IsHandled);
                if not IsHandled then
                    ItemLedgEntry.VerifyOnInventory();

                IsHandled := false;
                OnInsertItemLedgEntryOnCheckItemTracking(ItemJnlLine, ItemLedgEntry, GlobalItemTrackingCode, IsHandled);
                if not IsHandled then
                    if not (("Document Type" in ["Document Type"::"Purchase Return Shipment", "Document Type"::"Purchase Receipt"]) and
                            ("Job No." <> ''))
                    then
                        if (ItemLedgEntry.Quantity < 0) and GlobalItemTrackingCode.IsSpecific() then
                            Error(Text018, "Serial No.", "Lot No.", "Item No.", "Variant Code");

                if GlobalItemTrackingCode."SN Specific Tracking" then begin
                    if ItemLedgEntry.Quantity > 0 then
                        CheckItemSerialNo(ItemJnlLine);

                    IsHandled := false;
                    OnInsertItemLedgEntryOnBeforeSNQtyCheck(ItemJnlLine, IsHandled);
                    if not IsHandled then
                        if not (ItemLedgEntry.Quantity in [-1, 0, 1]) then
                            Error(Text033);
                end;

                if ("Document Type" <> "Document Type"::"Purchase Return Shipment") and ("Job No." = '') then
                    if (Item.Reserve = Item.Reserve::Always) and (ItemLedgEntry.Quantity < 0) then begin
                        IsHandled := false;
                        OnInsertItemLedgEntryOnBeforeReservationError(ItemJnlLine, ItemLedgEntry, IsHandled, Location);
                        if not IsHandled then
                            Error(Text012, ItemLedgEntry."Item No.");
                    end;
            end;

            if IsWarehouseReclassification(ItemJnlLine) then begin
                ItemLedgEntry."Global Dimension 1 Code" := OldItemLedgEntry."Global Dimension 1 Code";
                ItemLedgEntry."Global Dimension 2 Code" := OldItemLedgEntry."Global Dimension 2 Code";
                ItemLedgEntry."Dimension Set ID" := OldItemLedgEntry."Dimension Set ID"
            end else
                if TransferItem then begin
                    ItemLedgEntry."Global Dimension 1 Code" := "New Shortcut Dimension 1 Code";
                    ItemLedgEntry."Global Dimension 2 Code" := "New Shortcut Dimension 2 Code";
                    ItemLedgEntry."Dimension Set ID" := "New Dimension Set ID";
                end else begin
                    ItemLedgEntry."Global Dimension 1 Code" := "Shortcut Dimension 1 Code";
                    ItemLedgEntry."Global Dimension 2 Code" := "Shortcut Dimension 2 Code";
                    ItemLedgEntry."Dimension Set ID" := "Dimension Set ID";
                end;

            if not ("Entry Type" in ["Entry Type"::Transfer, "Entry Type"::Output]) and
               (ItemLedgEntry.Quantity = ItemLedgEntry."Invoiced Quantity")
            then
                ItemLedgEntry."Completely Invoiced" := true;

            if ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and ("Item Charge No." = '') and
               ("Invoiced Quantity" <> 0) and ("Posting Date" > ItemLedgEntry."Last Invoice Date")
            then
                ItemLedgEntry."Last Invoice Date" := "Posting Date";

            if "Entry Type" = "Entry Type"::Consumption then
                ItemLedgEntry."Applied Entry to Adjust" := true;

            if "Job No." <> '' then begin
                ItemLedgEntry."Job No." := "Job No.";
                ItemLedgEntry."Job Task No." := "Job Task No.";
                ItemLedgEntry."Order Line No." := "Job Contract Entry No.";
            end;

            ItemLedgEntry.UpdateItemTracking();

            OnBeforeInsertItemLedgEntry(ItemLedgEntry, ItemJnlLine, TransferItem, OldItemLedgEntry, ItemJnlLineOrigin);
            ItemLedgEntry.Insert(true);
            OnAfterInsertItemLedgEntry(ItemLedgEntry, ItemJnlLine, ItemLedgEntryNo, ValueEntryNo, ItemApplnEntryNo, GlobalValueEntry, TransferItem, InventoryPostingToGL, OldItemLedgEntry);

            InsertItemReg(ItemLedgEntry."Entry No.", 0, 0, 0);
        end;
    end;

    local procedure InsertItemReg(ItemLedgEntryNo: Integer; PhysInvtEntryNo: Integer; ValueEntryNo: Integer; CapLedgEntryNo: Integer)
    begin
        with ItemJnlLine do
            if ItemReg."No." = 0 then begin
                ItemReg.LockTable();
                ItemReg."No." := ItemReg.GetLastEntryNo() + 1;
                ItemReg.Init();
                ItemReg."From Entry No." := ItemLedgEntryNo;
                ItemReg."To Entry No." := ItemLedgEntryNo;
                ItemReg."From Phys. Inventory Entry No." := PhysInvtEntryNo;
                ItemReg."To Phys. Inventory Entry No." := PhysInvtEntryNo;
                ItemReg."From Value Entry No." := ValueEntryNo;
                ItemReg."To Value Entry No." := ValueEntryNo;
                ItemReg."From Capacity Entry No." := CapLedgEntryNo;
                ItemReg."To Capacity Entry No." := CapLedgEntryNo;
                ItemReg."Creation Date" := Today;
                ItemReg."Creation Time" := Time;
                ItemReg."Source Code" := "Source Code";
                ItemReg."Journal Batch Name" := "Journal Batch Name";
                ItemReg."User ID" := CopyStr(UserId(), 1, MaxStrLen(ItemReg."User ID"));
                OnInsertItemRegOnBeforeItemRegInsert(ItemReg, ItemJnlLine);
                ItemReg.Insert();
            end else begin
                if ((ItemLedgEntryNo < ItemReg."From Entry No.") and (ItemLedgEntryNo <> 0)) or
                   ((ItemReg."From Entry No." = 0) and (ItemLedgEntryNo > 0))
                then
                    ItemReg."From Entry No." := ItemLedgEntryNo;
                if ItemLedgEntryNo > ItemReg."To Entry No." then
                    ItemReg."To Entry No." := ItemLedgEntryNo;

                if ((PhysInvtEntryNo < ItemReg."From Phys. Inventory Entry No.") and (PhysInvtEntryNo <> 0)) or
                   ((ItemReg."From Phys. Inventory Entry No." = 0) and (PhysInvtEntryNo > 0))
                then
                    ItemReg."From Phys. Inventory Entry No." := PhysInvtEntryNo;
                if PhysInvtEntryNo > ItemReg."To Phys. Inventory Entry No." then
                    ItemReg."To Phys. Inventory Entry No." := PhysInvtEntryNo;

                if ((ValueEntryNo < ItemReg."From Value Entry No.") and (ValueEntryNo <> 0)) or
                   ((ItemReg."From Value Entry No." = 0) and (ValueEntryNo > 0))
                then
                    ItemReg."From Value Entry No." := ValueEntryNo;
                if ValueEntryNo > ItemReg."To Value Entry No." then
                    ItemReg."To Value Entry No." := ValueEntryNo;
                if ((CapLedgEntryNo < ItemReg."From Capacity Entry No.") and (CapLedgEntryNo <> 0)) or
                   ((ItemReg."From Capacity Entry No." = 0) and (CapLedgEntryNo > 0))
                then
                    ItemReg."From Capacity Entry No." := CapLedgEntryNo;
                if CapLedgEntryNo > ItemReg."To Capacity Entry No." then
                    ItemReg."To Capacity Entry No." := CapLedgEntryNo;

                ItemReg.Modify();
            end;
    end;

    procedure InsertPhysInventoryEntry(var ItemJournalLine: Record "Item Journal Line")
    var
        PhysInvtLedgEntry: Record "Phys. Inventory Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertPhysInventoryEntry(ItemJournalLine, IsHandled);
        if IsHandled then
            exit;

        with ItemJournalLine do begin
            if PhysInvtEntryNo = 0 then begin
                PhysInvtLedgEntry.LockTable();
                PhysInvtEntryNo := PhysInvtLedgEntry.GetLastEntryNo();
            end;

            PhysInvtEntryNo := PhysInvtEntryNo + 1;

            PhysInvtLedgEntry.Init();
            PhysInvtLedgEntry."Entry No." := PhysInvtEntryNo;
            PhysInvtLedgEntry."Item No." := "Item No.";
            PhysInvtLedgEntry."Posting Date" := "Posting Date";
            PhysInvtLedgEntry."Document Date" := "Document Date";
            PhysInvtLedgEntry."Entry Type" := "Entry Type";
            PhysInvtLedgEntry."Document No." := "Document No.";
            PhysInvtLedgEntry."External Document No." := "External Document No.";
            PhysInvtLedgEntry.Description := Description;
            PhysInvtLedgEntry."Location Code" := "Location Code";
            PhysInvtLedgEntry."Inventory Posting Group" := "Inventory Posting Group";
            PhysInvtLedgEntry."Unit Cost" := "Unit Cost";
            PhysInvtLedgEntry.Amount := Amount;
            PhysInvtLedgEntry."Salespers./Purch. Code" := "Salespers./Purch. Code";
            PhysInvtLedgEntry."Source Code" := "Source Code";
            PhysInvtLedgEntry."Global Dimension 1 Code" := "Shortcut Dimension 1 Code";
            PhysInvtLedgEntry."Global Dimension 2 Code" := "Shortcut Dimension 2 Code";
            PhysInvtLedgEntry."Dimension Set ID" := "Dimension Set ID";
            PhysInvtLedgEntry."Journal Batch Name" := "Journal Batch Name";
            PhysInvtLedgEntry."Reason Code" := "Reason Code";
            PhysInvtLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(PhysInvtLedgEntry."User ID"));
            PhysInvtLedgEntry."No. Series" := "Posting No. Series";
            GetInvtSetup();
            if (PhysInvtLedgEntry.Description = Item.Description) and not InvtSetup."Copy Item Descr. to Entries" then
                PhysInvtLedgEntry.Description := '';
            PhysInvtLedgEntry."Variant Code" := "Variant Code";
            PhysInvtLedgEntry."Unit of Measure Code" := "Unit of Measure Code";

            PhysInvtLedgEntry.Quantity := Quantity;
            PhysInvtLedgEntry."Unit Amount" := "Unit Amount";
            PhysInvtLedgEntry."Qty. (Calculated)" := "Qty. (Calculated)";
            PhysInvtLedgEntry."Qty. (Phys. Inventory)" := "Qty. (Phys. Inventory)";
            PhysInvtLedgEntry."Last Item Ledger Entry No." := "Last Item Ledger Entry No.";

            PhysInvtLedgEntry."Phys Invt Counting Period Code" :=
              "Phys Invt Counting Period Code";
            PhysInvtLedgEntry."Phys Invt Counting Period Type" :=
              "Phys Invt Counting Period Type";

            OnBeforeInsertPhysInvtLedgEntry(PhysInvtLedgEntry, ItemJournalLine, ItemJnlLine);
            PhysInvtLedgEntry.Insert();

            InsertItemReg(0, PhysInvtLedgEntry."Entry No.", 0, 0);
        end;

        OnAfterInsertPhysInventoryEntry(PhysInvtLedgEntry, ItemJnlLineOrigin);
    end;

    procedure PostInventoryToGL(var ValueEntry: Record "Value Entry")
    var
        IsHandled: Boolean;
    begin
        with ValueEntry do begin
            IsHandled := false;
            OnBeforePostInventoryToGL(ValueEntry, IsHandled, ItemJnlLine, PostToGL);
            if IsHandled then
                exit;

            if not Inventoriable or
               not CalledFromAdjustment and Item."Inventory Value Zero" or
               CalledFromAdjustment and not PostToGL
            then
                exit;

            InventoryPostingToGL.SetRunOnlyCheck(true, not PostToGL, false);
            OnPostInventoryToGLOnBeforePostInvtBuffer(InventoryPostingToGL, PostToGL);
            PostInvtBuffer(ValueEntry);
            OnPostInventoryToGLOnAfterPostInvtBuffer(ValueEntry);

            if "Expected Cost" then begin
                if ("Cost Amount (Expected)" = 0) and ("Cost Amount (Expected) (ACY)" = 0) then
                    SetValueEntry(ValueEntry, 1, 1, false)
                else
                    SetValueEntry(ValueEntry, "Cost Amount (Expected)", "Cost Amount (Expected) (ACY)", false);
                InventoryPostingToGL.SetRunOnlyCheck(true, true, false);
                PostInvtBuffer(ValueEntry);
                SetValueEntry(ValueEntry, 0, 0, true);
            end else
                if ("Cost Amount (Actual)" = 0) and ("Cost Amount (Actual) (ACY)" = 0) then begin
                    SetValueEntry(ValueEntry, 1, 1, false);
                    InventoryPostingToGL.SetRunOnlyCheck(true, true, false);
                    PostInvtBuffer(ValueEntry);
                    SetValueEntry(ValueEntry, 0, 0, false);
                end;
        end;

        OnAfterPostInventoryToGL(ValueEntry);
    end;

    local procedure SetValueEntry(var ValueEntry: Record "Value Entry"; CostAmtActual: Decimal; CostAmtActACY: Decimal; ExpectedCost: Boolean)
    begin
        ValueEntry."Cost Amount (Actual)" := CostAmtActual;
        ValueEntry."Cost Amount (Actual) (ACY)" := CostAmtActACY;
        ValueEntry."Expected Cost" := ExpectedCost;
    end;

    procedure InsertApplEntry(ItemLedgEntryNo: Integer; InboundItemEntry: Integer; OutboundItemEntry: Integer; TransferedFromEntryNo: Integer; PostingDate: Date; Quantity: Decimal; CostToApply: Boolean)
    var
        ApplItemLedgEntry: Record "Item Ledger Entry";
        OldItemApplnEntry: Record "Item Application Entry";
        ItemApplHistoryEntry: Record "Item Application Entry History";
        ItemApplnEntryExists: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertApplEntry(
            ItemLedgEntryNo, InboundItemEntry, OutboundItemEntry, TransferedFromEntryNo, PostingDate, Quantity, CostToApply, IsHandled);
        if IsHandled then
            exit;

        if Item.IsNonInventoriableType() then
            exit;

        if ItemApplnEntryNo = 0 then begin
            ItemApplnEntry.Reset();
            ItemApplnEntry.LockTable();
            ItemApplnEntryNo := ItemApplnEntry.GetLastEntryNo();
            if ItemApplnEntryNo > 0 then begin
                ItemApplHistoryEntry.Reset();
                ItemApplHistoryEntry.LockTable();
                ItemApplHistoryEntry.SetCurrentKey("Entry No.");
                if ItemApplHistoryEntry.FindLast() then
                    if ItemApplHistoryEntry."Entry No." > ItemApplnEntryNo then
                        ItemApplnEntryNo := ItemApplHistoryEntry."Entry No.";
            end
            else
                ItemApplnEntryNo := 0;
        end;

        if Quantity < 0 then begin
            OldItemApplnEntry.SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.");
            OldItemApplnEntry.SetRange("Inbound Item Entry No.", InboundItemEntry);
            OldItemApplnEntry.SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
            OldItemApplnEntry.SetRange("Outbound Item Entry No.", OutboundItemEntry);
            if OldItemApplnEntry.FindFirst() then begin
                ItemApplnEntry := OldItemApplnEntry;
                ItemApplnEntry.Quantity := ItemApplnEntry.Quantity + Quantity;
                ItemApplnEntry."Last Modified Date" := CurrentDateTime;
                ItemApplnEntry."Last Modified By User" := UserId;

                OnInsertApplEntryOnBeforeModify(ItemApplnEntry);

                ItemApplnEntry.Modify();
                ItemApplnEntryExists := true;
            end;
        end;

        if not ItemApplnEntryExists then begin
            ItemApplnEntryNo := ItemApplnEntryNo + 1;
            ItemApplnEntry.Init();
            ItemApplnEntry."Entry No." := ItemApplnEntryNo;
            ItemApplnEntry."Item Ledger Entry No." := ItemLedgEntryNo;
            ItemApplnEntry."Inbound Item Entry No." := InboundItemEntry;
            ItemApplnEntry."Outbound Item Entry No." := OutboundItemEntry;
            ItemApplnEntry."Transferred-from Entry No." := TransferedFromEntryNo;
            ItemApplnEntry.Quantity := Quantity;
            ItemApplnEntry."Posting Date" := PostingDate;
            ItemApplnEntry."Output Completely Invd. Date" := GetOutputComplInvcdDate(ItemApplnEntry);

            if AverageTransfer then begin
                if (Quantity > 0) or (ItemJnlLine."Document Type" = ItemJnlLine."Document Type"::"Transfer Receipt") then
                    ItemApplnEntry."Cost Application" :=
                      ItemApplnEntry.IsOutbndItemApplEntryCostApplication(ItemLedgEntryNo) and IsNotValuedByAverageCost(ItemLedgEntryNo);
            end else
                case true of
                    Item."Costing Method" <> Item."Costing Method"::Average,
                  ItemJnlLine.Correction and (ItemJnlLine."Document Type" = ItemJnlLine."Document Type"::"Posted Assembly"):
                        ItemApplnEntry."Cost Application" := true;
                    ItemJnlLine.Correction:
                        begin
                            ApplItemLedgEntry.Get(ItemApplnEntry."Item Ledger Entry No.");
                            ItemApplnEntry."Cost Application" :=
                              (ApplItemLedgEntry.Quantity > 0) or (ApplItemLedgEntry."Applies-to Entry" <> 0);
                        end;
                    else
                        if (ItemJnlLine."Applies-to Entry" <> 0) or
                           (CostToApply and ItemJnlLine.IsInbound())
                        then
                            ItemApplnEntry."Cost Application" := true;
                end;

            ItemApplnEntry."Creation Date" := CurrentDateTime;
            ItemApplnEntry."Created By User" := UserId;
            OnBeforeItemApplnEntryInsert(ItemApplnEntry, GlobalItemLedgEntry, OldItemLedgEntry);
            ItemApplnEntry.Insert(true);
            OnAfterItemApplnEntryInsert(ItemApplnEntry, GlobalItemLedgEntry, OldItemLedgEntry);
        end;
    end;

    local procedure UpdateItemApplnEntry(ItemLedgEntryNo: Integer; PostingDate: Date)
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        with ItemApplnEntry do begin
            SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
            SetRange("Output Completely Invd. Date", 0D);
            if not IsEmpty() then
                ModifyAll("Output Completely Invd. Date", PostingDate);
        end;
    end;

    local procedure GetOutputComplInvcdDate(ItemApplnEntry: Record "Item Application Entry"): Date
    var
        OutbndItemLedgEntry: Record "Item Ledger Entry";
    begin
        with ItemApplnEntry do begin
            if Quantity > 0 then
                exit("Posting Date");
            if OutbndItemLedgEntry.Get("Outbound Item Entry No.") then
                if OutbndItemLedgEntry."Completely Invoiced" then
                    exit(OutbndItemLedgEntry."Last Invoice Date");
        end;
    end;

    local procedure InitValueEntry(var ValueEntry: Record "Value Entry"; ItemLedgEntry: Record "Item Ledger Entry")
    var
        CalcUnitCost: Boolean;
        InvoicedQuantityNotEmpty: Boolean;
        CostAmt: Decimal;
        CostAmtACY: Decimal;
    begin
        OnBeforeInitValueEntry(ValueEntry, ValueEntryNo, ItemJnlLine);

        ValueEntryNo := ValueEntryNo + 1;

        with ItemJnlLine do begin
            ValueEntry.Init();
            ValueEntry."Entry No." := ValueEntryNo;
            if "Value Entry Type" = "Value Entry Type"::Variance then
                ValueEntry."Variance Type" := "Variance Type";
            ValueEntry."Item Ledger Entry No." := ItemLedgEntry."Entry No.";
            ValueEntry."Item No." := "Item No.";
            ValueEntry."Item Charge No." := "Item Charge No.";
            ValueEntry."Order Type" := ItemLedgEntry."Order Type";
            ValueEntry."Order No." := ItemLedgEntry."Order No.";
            ValueEntry."Order Line No." := ItemLedgEntry."Order Line No.";
            ValueEntry."Item Ledger Entry Type" := "Entry Type";
            ValueEntry.Type := Type;
            ValueEntry."Posting Date" := "Posting Date";
            ValueEntry."VAT Reporting Date" := "VAT Reporting Date";
            if "Partial Revaluation" then
                ValueEntry."Partial Revaluation" := true;

            OnInitValueEntryOnAfterAssignFields(ValueEntry, ItemLedgEntry, ItemJnlLine);

            if (ItemLedgEntry.Quantity > 0) or
               (ItemLedgEntry."Invoiced Quantity" > 0) or
               (("Value Entry Type" = "Value Entry Type"::"Direct Cost") and ("Item Charge No." = '')) or
               ("Entry Type" in ["Entry Type"::Output, "Entry Type"::"Assembly Output"]) or
               Adjustment
            then
                ValueEntry.Inventoriable := Item.Type = Item.Type::Inventory;

            OnInitValueEntryOnAfterSetValueEntryInventoriable(ValueEntry, ItemJnlLine);

            if ((Quantity = 0) and ("Invoiced Quantity" <> 0)) or
               ("Value Entry Type" <> "Value Entry Type"::"Direct Cost") or
               ("Item Charge No." <> '') or Adjustment
            then begin
                GetLastDirectCostValEntry(ValueEntry."Item Ledger Entry No.");
                if ValueEntry.Inventoriable and ("Item Charge No." = '') then
                    ValueEntry."Valued By Average Cost" := DirCostValueEntry."Valued By Average Cost";
            end;

            case true of
                ((Quantity = 0) and ("Invoiced Quantity" <> 0)) or
              (("Value Entry Type" = "Value Entry Type"::"Direct Cost") and ("Item Charge No." <> '')) or
              Adjustment or ("Value Entry Type" = "Value Entry Type"::Rounding):
                    ValueEntry."Valuation Date" := DirCostValueEntry."Valuation Date";
                ("Value Entry Type" = "Value Entry Type"::Revaluation):
                    if "Posting Date" < DirCostValueEntry."Valuation Date" then
                        ValueEntry."Valuation Date" := DirCostValueEntry."Valuation Date"
                    else
                        ValueEntry."Valuation Date" := "Posting Date";
                (ItemLedgEntry.Quantity > 0) and ("Applies-from Entry" <> 0):
                    GetAppliedFromValues(ValueEntry);
                else
                    ValueEntry."Valuation Date" := "Posting Date";
            end;

            GetInvtSetup();
            if (Description = Item.Description) and not InvtSetup."Copy Item Descr. to Entries" then
                ValueEntry.Description := ''
            else
                ValueEntry.Description := Description;

            SetValueEntrySourceFieldsFromItemJnlLine(ValueEntry, ItemJnlLine);
            if ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and ("Item Charge No." = '') then
                ValueEntry."Inventory Posting Group" := "Inventory Posting Group"
            else
                ValueEntry."Inventory Posting Group" := DirCostValueEntry."Inventory Posting Group";
            ValueEntry."Source Posting Group" := "Source Posting Group";
            ValueEntry."Salespers./Purch. Code" := "Salespers./Purch. Code";
            ValueEntry."Location Code" := ItemLedgEntry."Location Code";
            ValueEntry."Variant Code" := ItemLedgEntry."Variant Code";
            ValueEntry."Journal Batch Name" := "Journal Batch Name";
            ValueEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(ValueEntry."User ID"));
            ValueEntry."Drop Shipment" := "Drop Shipment";
            ValueEntry."Reason Code" := "Reason Code";
            ValueEntry."Return Reason Code" := "Return Reason Code";
            ValueEntry."External Document No." := "External Document No.";
            ValueEntry."Document Date" := "Document Date";
            ValueEntry."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
            ValueEntry."Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";
            ValueEntry."Discount Amount" := "Discount Amount";
            ValueEntry."Entry Type" := "Value Entry Type";
            if "Job No." <> '' then begin
                ValueEntry."Job No." := "Job No.";
                ValueEntry."Job Task No." := "Job Task No.";
            end;
            InvoicedQuantityNotEmpty := "Invoiced Quantity" <> 0;
            OnInitValueEntryOnAfterCalcInvoicedQuantityNotEmpty(ItemJnlLine, InvoicedQuantityNotEmpty);
            if InvoicedQuantityNotEmpty then begin
                ValueEntry."Valued Quantity" := "Invoiced Quantity";
                if ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
                   ("Item Charge No." = '')
                then
                    if ("Entry Type" <> "Entry Type"::Output) or
                       (ItemLedgEntry."Invoiced Quantity" = 0)
                    then
                        ValueEntry."Invoiced Quantity" := "Invoiced Quantity";
                ValueEntry."Expected Cost" := false;
            end else begin
                ValueEntry."Valued Quantity" := Quantity;
                ValueEntry."Expected Cost" := "Value Entry Type" <> "Value Entry Type"::Revaluation;
            end;

            ValueEntry."Document Type" := "Document Type";
            if ValueEntry."Expected Cost" or ("Invoice No." = '') then
                ValueEntry."Document No." := "Document No."
            else begin
                ValueEntry."Document No." := "Invoice No.";
                if "Document Type" in [
                                       "Document Type"::"Purchase Receipt", "Document Type"::"Purchase Return Shipment",
                                       "Document Type"::"Sales Shipment", "Document Type"::"Sales Return Receipt",
                                       "Document Type"::"Service Shipment"]
                then
                    ValueEntry."Document Type" := "Item Ledger Document Type".FromInteger("Document Type".AsInteger() + 1);
            end;
            ValueEntry."Document Line No." := "Document Line No.";

            if Adjustment then begin
                ValueEntry."Invoiced Quantity" := 0;
                ValueEntry."Applies-to Entry" := "Applies-to Value Entry";
                ValueEntry.Adjustment := true;
            end;

            if "Value Entry Type" <> "Value Entry Type"::Rounding then begin
                if ("Entry Type" = "Entry Type"::Output) and
                   ("Value Entry Type" <> "Value Entry Type"::Revaluation)
                then begin
                    CostAmt := Amount;
                    CostAmtACY := "Amount (ACY)";
                end else begin
                    ValueEntry."Cost per Unit" := RetrieveCostPerUnit(ItemJnlLine, SKU, SKUExists);
                    if GLSetup."Additional Reporting Currency" <> '' then
                        ValueEntry."Cost per Unit (ACY)" := RetrieveCostPerUnitACY(ValueEntry."Cost per Unit");

                    if (ValueEntry."Valued Quantity" > 0) and
                       (ValueEntry."Item Ledger Entry Type" in [ValueEntry."Item Ledger Entry Type"::Purchase,
                                                                ValueEntry."Item Ledger Entry Type"::"Assembly Output"]) and
                       (ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Direct Cost") and
                       not Adjustment
                    then begin
                        if Item."Costing Method" = Item."Costing Method"::Standard then
                            "Unit Cost" := ValueEntry."Cost per Unit";
                        CalcPosShares(
                          CostAmt, OverheadAmount, VarianceAmount, CostAmtACY, OverheadAmountACY, VarianceAmountACY,
                          CalcUnitCost, (Item."Costing Method" = Item."Costing Method"::Standard) and
                          (not ValueEntry."Expected Cost"), ValueEntry."Expected Cost");
                        if (OverheadAmount <> 0) or
                           (Round(VarianceAmount, GLSetup."Amount Rounding Precision") <> 0) or
                           CalcUnitCost or ValueEntry."Expected Cost"
                        then begin
                            ValueEntry."Cost per Unit" :=
                              CalcCostPerUnit(CostAmt, ValueEntry."Valued Quantity", false);

                            if GLSetup."Additional Reporting Currency" <> '' then
                                ValueEntry."Cost per Unit (ACY)" :=
                                  CalcCostPerUnit(CostAmtACY, ValueEntry."Valued Quantity", true);
                        end;
                    end else
                        if not Adjustment then
                            CalcOutboundCostAmt(ValueEntry, CostAmt, CostAmtACY)
                        else begin
                            CostAmt := Amount;
                            CostAmtACY := "Amount (ACY)";
                        end;

                    if ("Invoiced Quantity" < 0) and ("Applies-to Entry" <> 0) and
                       ("Entry Type" = "Entry Type"::Purchase) and ("Item Charge No." = '') and
                       (ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Direct Cost")
                    then begin
                        CalcPurchCorrShares(OverheadAmount, OverheadAmountACY, VarianceAmount, VarianceAmountACY);
                        OnAfterCalcPurchCorrShares(
                          ValueEntry, ItemJnlLine, OverheadAmount, OverheadAmountACY, VarianceAmount, VarianceAmountACY);
                    end;
                end;
                OnInitValueEntryOnAfterCalcDirestCost(CostAmt, VarianceAmount, Item, ItemJnlLine, ValueEntry);
            end else begin
                CostAmt := "Unit Cost";
                CostAmtACY := "Unit Cost (ACY)";
            end;

            if (ValueEntry."Entry Type" <> ValueEntry."Entry Type"::Revaluation) and not Adjustment then
                if (ValueEntry."Item Ledger Entry Type" in
                    [ValueEntry."Item Ledger Entry Type"::Sale,
                     ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.",
                     ValueEntry."Item Ledger Entry Type"::Consumption,
                     ValueEntry."Item Ledger Entry Type"::"Assembly Consumption"]) or
                   ((ValueEntry."Item Ledger Entry Type" = ValueEntry."Item Ledger Entry Type"::Transfer) and
                    ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and ("Item Charge No." = ''))
                then begin
                    ValueEntry."Valued Quantity" := -ValueEntry."Valued Quantity";
                    ValueEntry."Invoiced Quantity" := -ValueEntry."Invoiced Quantity";
                    if ValueEntry."Item Ledger Entry Type" = ValueEntry."Item Ledger Entry Type"::Transfer then
                        ValueEntry."Discount Amount" := 0
                    else
                        ValueEntry."Discount Amount" := -ValueEntry."Discount Amount";

                    if "Value Entry Type" <> "Value Entry Type"::Rounding then begin
                        CostAmt := -CostAmt;
                        CostAmtACY := -CostAmtACY;
                    end;
                end;
            if not Adjustment then
                if Item."Inventory Value Zero" or
                   (("Entry Type" = "Entry Type"::Transfer) and
                    (ValueEntry."Valued Quantity" < 0) and not AverageTransfer) or
                   (("Entry Type" = "Entry Type"::Sale) and
                    ("Item Charge No." <> ''))
                then begin
                    CostAmt := 0;
                    CostAmtACY := 0;
                    ValueEntry."Cost per Unit" := 0;
                    ValueEntry."Cost per Unit (ACY)" := 0;
                    OnInitValueEntryOnAfterNotAdjustmentCheckClearCostAmount(ValueEntry, ItemJnlLine);
                end;

            case true of
                (not ValueEntry."Expected Cost") and ValueEntry.Inventoriable and
                IsInterimRevaluation():
                    begin
                        ValueEntry."Cost Amount (Expected)" := Round(CostAmt * "Applied Amount" / Amount);
                        ValueEntry."Cost Amount (Expected) (ACY)" := Round(CostAmtACY * "Applied Amount" / Amount,
                            Currency."Amount Rounding Precision");

                        CostAmt := Round(CostAmt);
                        CostAmtACY := Round(CostAmtACY, Currency."Amount Rounding Precision");
                        ValueEntry."Cost Amount (Actual)" := CostAmt - ValueEntry."Cost Amount (Expected)";
                        ValueEntry."Cost Amount (Actual) (ACY)" := CostAmtACY - ValueEntry."Cost Amount (Expected) (ACY)";
                    end;
                (not ValueEntry."Expected Cost") and ValueEntry.Inventoriable:
                    begin
                        if not Adjustment and ("Value Entry Type" = "Value Entry Type"::"Direct Cost") then
                            case "Entry Type" of
                                "Entry Type"::Sale:
                                    ValueEntry."Sales Amount (Actual)" := Amount;
                                "Entry Type"::Purchase:
                                    ValueEntry."Purchase Amount (Actual)" := Amount;
                            end;
                        ValueEntry."Cost Amount (Actual)" := CostAmt;
                        ValueEntry."Cost Amount (Actual) (ACY)" := CostAmtACY;
                    end;
                ValueEntry."Expected Cost" and ValueEntry.Inventoriable:
                    begin
                        if not Adjustment then
                            case "Entry Type" of
                                "Entry Type"::Sale:
                                    ValueEntry."Sales Amount (Expected)" := Amount;
                                "Entry Type"::Purchase:
                                    ValueEntry."Purchase Amount (Expected)" := Amount;
                            end;
                        ValueEntry."Cost Amount (Expected)" := CostAmt;
                        ValueEntry."Cost Amount (Expected) (ACY)" := CostAmtACY;
                    end;
                (not ValueEntry."Expected Cost") and (not ValueEntry.Inventoriable):
                    if "Entry Type" = "Entry Type"::Sale then begin
                        ValueEntry."Sales Amount (Actual)" := Amount;
                        if Item.IsNonInventoriableType() then begin
                            ValueEntry."Cost Amount (Non-Invtbl.)" := CostAmt;
                            ValueEntry."Cost Amount (Non-Invtbl.)(ACY)" := CostAmtACY;
                        end else begin
                            ValueEntry."Cost per Unit" := 0;
                            ValueEntry."Cost per Unit (ACY)" := 0;
                        end;
                    end else begin
                        if "Entry Type" = "Entry Type"::Purchase then
                            ValueEntry."Purchase Amount (Actual)" := Amount;
                        ValueEntry."Cost Amount (Non-Invtbl.)" := CostAmt;
                        ValueEntry."Cost Amount (Non-Invtbl.)(ACY)" := CostAmtACY;
                    end;
            end;

            OnInitValueEntryOnBeforeRoundAmtValueEntry(ValueEntry, ItemJnlLine);

            RoundAmtValueEntry(ValueEntry);

            OnAfterInitValueEntry(ValueEntry, ItemJnlLine, ValueEntryNo, ItemLedgEntry);
        end;
    end;

    local procedure SetValueEntrySourceFieldsFromItemJnlLine(var ValueEntry: Record "Value Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
        OnBeforeSetValueEntrySourceFieldsFromItemJnlLine(ValueEntry, ItemJournalLine);

        ValueEntry."Source Code" := ItemJournalLine."Source Code";
        ValueEntry."Source Type" := ItemJournalLine."Source Type";
        ValueEntry."Source No." := GetSourceNo(ItemJournalLine);
    end;

    local procedure CalcOutboundCostAmt(ValueEntry: Record "Value Entry"; var CostAmt: Decimal; var CostAmtACY: Decimal)
    begin
        if ItemJnlLine."Item Charge No." <> '' then begin
            CostAmt := ItemJnlLine.Amount;
            if GLSetup."Additional Reporting Currency" <> '' then
                CostAmtACY := ACYMgt.CalcACYAmt(CostAmt, ValueEntry."Posting Date", false);
        end else begin
            CostAmt :=
              ValueEntry."Cost per Unit" * ValueEntry."Valued Quantity";
            CostAmtACY :=
              ValueEntry."Cost per Unit (ACY)" * ValueEntry."Valued Quantity";

            if MustConsiderUnitCostRoundingOnRevaluation(ItemJnlLine) then begin
                CostAmt += RoundingResidualAmount;
                CostAmtACY += RoundingResidualAmountACY;
            end;
        end;
    end;

    procedure InsertValueEntry(var ValueEntry: Record "Value Entry"; var ItemLedgEntry: Record "Item Ledger Entry"; TransferItem: Boolean)
    var
        InvdValueEntry: Record "Value Entry";
        InvoicedQty: Decimal;
        ShouldCalcExpectedCost: Boolean;
    begin
        OnBeforeInsertValueEntryProcedure(ItemLedgEntry, ItemJnlLine);
        with ItemJnlLine do begin
            if IsWarehouseReclassification(ItemJnlLine) then begin
                ValueEntry."Dimension Set ID" := OldItemLedgEntry."Dimension Set ID";
                ValueEntry."Global Dimension 1 Code" := OldItemLedgEntry."Global Dimension 1 Code";
                ValueEntry."Global Dimension 2 Code" := OldItemLedgEntry."Global Dimension 2 Code";
            end else
                if TransferItem then begin
                    ValueEntry."Global Dimension 1 Code" := "New Shortcut Dimension 1 Code";
                    ValueEntry."Global Dimension 2 Code" := "New Shortcut Dimension 2 Code";
                    ValueEntry."Dimension Set ID" := "New Dimension Set ID";
                end else
                    if (GlobalValueEntry."Entry Type" = GlobalValueEntry."Entry Type"::"Direct Cost") and
                       (GlobalValueEntry."Item Charge No." <> '') and
                       (ValueEntry."Entry Type" = ValueEntry."Entry Type"::Variance)
                    then begin
                        GetLastDirectCostValEntry(ValueEntry."Item Ledger Entry No.");
                        ValueEntry."Gen. Prod. Posting Group" := DirCostValueEntry."Gen. Prod. Posting Group";
                        MoveValEntryDimToValEntryDim(ValueEntry, DirCostValueEntry);
                    end else begin
                        ValueEntry."Global Dimension 1 Code" := "Shortcut Dimension 1 Code";
                        ValueEntry."Global Dimension 2 Code" := "Shortcut Dimension 2 Code";
                        ValueEntry."Dimension Set ID" := "Dimension Set ID";
                    end;
            OnInsertValueEntryOnBeforeRoundAmtValueEntry(ValueEntry, ItemLedgEntry, ItemJnlLine, TransferItem);
            RoundAmtValueEntry(ValueEntry);

            if ValueEntry."Entry Type" = ValueEntry."Entry Type"::Rounding then begin
                ValueEntry."Valued Quantity" := ItemLedgEntry.Quantity;
                ValueEntry."Invoiced Quantity" := 0;
                ValueEntry."Cost per Unit" := 0;
                ValueEntry."Sales Amount (Actual)" := 0;
                ValueEntry."Purchase Amount (Actual)" := 0;
                ValueEntry."Cost per Unit (ACY)" := 0;
                ValueEntry."Item Ledger Entry Quantity" := 0;
            end else begin
                if IsFirstValueEntry(ValueEntry."Item Ledger Entry No.") then
                    ValueEntry."Item Ledger Entry Quantity" := ValueEntry."Valued Quantity"
                else
                    ValueEntry."Item Ledger Entry Quantity" := 0;
                RecalculateCostPerUnit(ValueEntry, ItemLedgEntry);
                if UpdateItemLedgEntry(ValueEntry, ItemLedgEntry) then
                    ItemLedgEntry.Modify();
            end;

            ShouldCalcExpectedCost :=
                ((ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Direct Cost") and
                    (ValueEntry."Item Charge No." = '')) and
                (((Quantity = 0) and ("Invoiced Quantity" <> 0)) or
                    (Adjustment and not ValueEntry."Expected Cost")) and
                not ExpectedCostPosted(ValueEntry);
            OnInsertValueEntryOnBeforeCalcExpectedCost(ItemJnlLine, ItemLedgEntry, ValueEntry, TransferItem, InventoryPostingToGL, ShouldCalcExpectedCost);
            if ShouldCalcExpectedCost then begin
                if ValueEntry."Invoiced Quantity" = 0 then begin
                    if InvdValueEntry.Get(ValueEntry."Applies-to Entry") then
                        InvoicedQty := InvdValueEntry."Invoiced Quantity"
                    else
                        InvoicedQty := ValueEntry."Valued Quantity";
                end else
                    InvoicedQty := ValueEntry."Invoiced Quantity";
                CalcExpectedCost(
                  ValueEntry,
                  ItemLedgEntry."Entry No.",
                  InvoicedQty,
                  ItemLedgEntry.Quantity,
                  ValueEntry."Cost Amount (Expected)",
                  ValueEntry."Cost Amount (Expected) (ACY)",
                  ValueEntry."Sales Amount (Expected)",
                  ValueEntry."Purchase Amount (Expected)",
                  ItemLedgEntry.Quantity = ItemLedgEntry."Invoiced Quantity");
            end;

            OnBeforeInsertValueEntry(ValueEntry, ItemJnlLine, ItemLedgEntry, ValueEntryNo, InventoryPostingToGL, CalledFromAdjustment,
                OldItemLedgEntry, Item, TransferItem, GlobalValueEntry);

            PostInventoryToGL(ValueEntry);

            ValueEntry.Insert();

            OnAfterInsertValueEntry(ValueEntry, ItemJnlLine, ItemLedgEntry, ValueEntryNo);

            ItemApplnEntry.SetOutboundsNotUpdated(ItemLedgEntry);

            UpdateAdjmtProperties(ValueEntry, ItemLedgEntry."Posting Date");

            InsertItemReg(0, 0, ValueEntry."Entry No.", 0);

            OnInsertValueEntryOnBeforeInsertPostValueEntryToGL(ValueEntry);
            InsertPostValueEntryToGL(ValueEntry);
            OnInsertValueEntryOnAfterInsertPostValueEntryToGL(ValueEntry);

            if Item."Item Tracking Code" <> '' then begin
                TempValueEntryRelation.Init();
                TempValueEntryRelation."Value Entry No." := ValueEntry."Entry No.";
                TempValueEntryRelation.Insert();
            end;
            OnInsertValueEntryOnAfterTempValueEntryRelationInsert(ValueEntry, ItemJnlLine, TempValueEntryRelation);
        end;
    end;

    local procedure RecalculateCostPerUnit(var ValueEntry: Record "Value Entry"; var ItemLedgEntry: Record "Item Ledger Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRecalculateCostPerUnit(ValueEntry, ItemJnlLine, ItemLedgEntry, IsHandled);
        if IsHandled then
            exit;

        if ValueEntry."Cost per Unit" = 0 then begin
            ValueEntry."Cost per Unit" :=
              CalcCostPerUnit(ValueEntry."Cost Amount (Actual)", ValueEntry."Valued Quantity", false);
            ValueEntry."Cost per Unit (ACY)" :=
              CalcCostPerUnit(ValueEntry."Cost Amount (Actual) (ACY)", ValueEntry."Valued Quantity", true);
        end else begin
            ValueEntry."Cost per Unit" := Round(
                ValueEntry."Cost per Unit", GLSetup."Unit-Amount Rounding Precision");
            ValueEntry."Cost per Unit (ACY)" := Round(
                ValueEntry."Cost per Unit (ACY)", Currency."Unit-Amount Rounding Precision");
            if ItemJnlLine."Source Currency Code" = GLSetup."Additional Reporting Currency" then
                if ValueEntry."Expected Cost" then
                    ValueEntry."Cost per Unit" :=
                      CalcCostPerUnit(ValueEntry."Cost Amount (Expected)", ValueEntry."Valued Quantity", false)
                else
                    if ValueEntry."Entry Type" = ValueEntry."Entry Type"::Revaluation then
                        ValueEntry."Cost per Unit" :=
                          CalcCostPerUnit(ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)",
                            ValueEntry."Valued Quantity", false)
                    else
                        if not ValueEntry.Inventoriable and (ValueEntry."Item Charge No." = '') then
                            ValueEntry."Cost per Unit" :=
                                CalcCostPerUnit(ValueEntry."Cost Amount (Non-Invtbl.)", ValueEntry."Valued Quantity", false)
                        else
                            ValueEntry."Cost per Unit" :=
                              CalcCostPerUnit(ValueEntry."Cost Amount (Actual)", ValueEntry."Valued Quantity", false);
        end;
    end;

    local procedure InsertOHValueEntry(ValueEntry: Record "Value Entry"; OverheadAmount: Decimal; OverheadAmountACY: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertOHValueEntry(ValueEntry, Item, OverheadAmount, OverheadAmountACY, IsHandled);
        if IsHandled then
            exit;

        if Item."Inventory Value Zero" or not ValueEntry.Inventoriable then
            exit;

        ValueEntryNo := ValueEntryNo + 1;

        ValueEntry."Entry No." := ValueEntryNo;
        ValueEntry."Item Charge No." := '';
        ValueEntry."Entry Type" := ValueEntry."Entry Type"::"Indirect Cost";
        ValueEntry.Description := '';
        ValueEntry."Cost per Unit" := 0;
        ValueEntry."Cost per Unit (ACY)" := 0;
        ValueEntry."Cost Posted to G/L" := 0;
        ValueEntry."Cost Posted to G/L (ACY)" := 0;
        ValueEntry."Invoiced Quantity" := 0;
        ValueEntry."Sales Amount (Actual)" := 0;
        ValueEntry."Sales Amount (Expected)" := 0;
        ValueEntry."Purchase Amount (Actual)" := 0;
        ValueEntry."Purchase Amount (Expected)" := 0;
        ValueEntry."Discount Amount" := 0;
        ValueEntry."Cost Amount (Actual)" := OverheadAmount;
        ValueEntry."Cost Amount (Expected)" := 0;
        ValueEntry."Cost Amount (Expected) (ACY)" := 0;

        if GLSetup."Additional Reporting Currency" <> '' then
            ValueEntry."Cost Amount (Actual) (ACY)" :=
              Round(OverheadAmountACY, Currency."Amount Rounding Precision");

        IsHandled := false;
        OnInsertOHValueEntryOnBeforeInsertValueEntry(ValueEntry, ItemJnlLine, IsHandled, GlobalItemLedgEntry, ValueEntryNo);
        if not IsHandled then
            InsertValueEntry(ValueEntry, GlobalItemLedgEntry, false);

        OnAfterInsertOHValueEntry(ValueEntry, Item, OverheadAmount, OverheadAmountACY);
    end;

    local procedure InsertVarValueEntry(ValueEntry: Record "Value Entry"; VarianceAmount: Decimal; VarianceAmountACY: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertVarValueEntry(ValueEntry, Item, VarianceAmount, VarianceAmountACY, IsHandled);
        if IsHandled then
            exit;

        if (not ValueEntry.Inventoriable) or Item."Inventory Value Zero" then
            exit;
        if (VarianceAmount = 0) and (VarianceAmountACY = 0) then
            exit;

        ValueEntryNo := ValueEntryNo + 1;

        ValueEntry."Entry No." := ValueEntryNo;
        ValueEntry."Item Charge No." := '';
        ValueEntry."Entry Type" := ValueEntry."Entry Type"::Variance;
        ValueEntry.Description := '';
        ValueEntry."Cost Posted to G/L" := 0;
        ValueEntry."Cost Posted to G/L (ACY)" := 0;
        ValueEntry."Invoiced Quantity" := 0;
        ValueEntry."Sales Amount (Actual)" := 0;
        ValueEntry."Sales Amount (Expected)" := 0;
        ValueEntry."Purchase Amount (Actual)" := 0;
        ValueEntry."Purchase Amount (Expected)" := 0;
        ValueEntry."Discount Amount" := 0;
        ValueEntry."Cost Amount (Actual)" := VarianceAmount;
        ValueEntry."Cost Amount (Expected)" := 0;
        ValueEntry."Cost Amount (Expected) (ACY)" := 0;
        ValueEntry."Variance Type" := ValueEntry."Variance Type"::Purchase;
        OnInsertVarValueEntryOnAfterInitValueEntryFields(ValueEntry);

        if GLSetup."Additional Reporting Currency" <> '' then begin
            if Round(VarianceAmount, GLSetup."Amount Rounding Precision") =
               Round(-GlobalValueEntry."Cost Amount (Actual)", GLSetup."Amount Rounding Precision")
            then
                ValueEntry."Cost Amount (Actual) (ACY)" := -GlobalValueEntry."Cost Amount (Actual) (ACY)"
            else
                ValueEntry."Cost Amount (Actual) (ACY)" :=
                  Round(VarianceAmountACY, Currency."Amount Rounding Precision");
        end;

        ValueEntry."Cost per Unit" :=
          CalcCostPerUnit(ValueEntry."Cost Amount (Actual)", ValueEntry."Valued Quantity", false);
        ValueEntry."Cost per Unit (ACY)" :=
          CalcCostPerUnit(ValueEntry."Cost Amount (Actual) (ACY)", ValueEntry."Valued Quantity", true);

        InsertValueEntry(ValueEntry, GlobalItemLedgEntry, false);
    end;

    local procedure UpdateItemLedgEntry(ValueEntry: Record "Value Entry"; var ItemLedgEntry: Record "Item Ledger Entry") ModifyEntry: Boolean
    var
        IsHandled: Boolean;
    begin
        with ItemLedgEntry do
            if not (ValueEntry."Entry Type" in
                    [ValueEntry."Entry Type"::Variance,
                     ValueEntry."Entry Type"::"Indirect Cost",
                     ValueEntry."Entry Type"::Rounding])
            then begin
                if ValueEntry.Inventoriable and (not ItemJnlLine.Adjustment or ("Entry Type" = "Entry Type"::"Assembly Output")) then
                    UpdateAvgCostAdjmtBuffer(ItemLedgEntry, ValueEntry."Valuation Date");

                if (Positive or "Job Purchase") and
                   (Quantity <> "Remaining Quantity") and not "Applied Entry to Adjust" and
                   (Item.Type = Item.Type::Inventory) and
                   (not CalledFromAdjustment or AppliedEntriesToReadjust(ItemLedgEntry))
                then begin
                    "Applied Entry to Adjust" := true;
                    ModifyEntry := true;
                end;

                if (ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Direct Cost") and
                   (ItemJnlLine."Item Charge No." = '') and
                   (ItemJnlLine.Quantity = 0) and (ValueEntry."Invoiced Quantity" <> 0)
                then begin
                    if ValueEntry."Invoiced Quantity" <> 0 then begin
                        "Invoiced Quantity" := "Invoiced Quantity" + ValueEntry."Invoiced Quantity";
                        CheckInvoicedQuantity(ItemLedgEntry, ValueEntry, ModifyEntry);
                    end;

                    if ("Entry Type" <> "Entry Type"::Output) and
                       ("Invoiced Quantity" = Quantity) and
                       not "Completely Invoiced"
                    then begin
                        "Completely Invoiced" := true;
                        ModifyEntry := true;
                    end;

                    if "Last Invoice Date" < ValueEntry."Posting Date" then begin
                        "Last Invoice Date" := ValueEntry."Posting Date";
                        ModifyEntry := true;
                    end;
                end;
                IsHandled := false;
                OnUpdateItemLedgEntryOnBeforeUpdateOutboundItemLedgEntry(ValueEntry, IsHandled);
                if not IsHandled then
                    if ItemJnlLine."Applies-from Entry" <> 0 then
                        UpdateOutboundItemLedgEntry(ItemJnlLine."Applies-from Entry");
            end;

        exit(ModifyEntry);
    end;

    local procedure UpdateAvgCostAdjmtBuffer(OldItemLedgEntry: Record "Item Ledger Entry"; ValuationDate: Date)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.Init();
        ValueEntry."Item No." := OldItemLedgEntry."Item No.";
        ValueEntry."Valuation Date" := ValuationDate;
        ValueEntry."Location Code" := OldItemLedgEntry."Location Code";
        ValueEntry."Variant Code" := OldItemLedgEntry."Variant Code";
        OnUpdateAvgCostAdjmtBufferOnAfterSetValueEntry(ValueEntry, OldItemLedgEntry);

        AvgCostEntryPointHandler.LockBuffer();
        AvgCostEntryPointHandler.UpdateValuationDate(ValueEntry);
    end;

    local procedure UpdateOutboundItemLedgEntry(OutboundItemEntryNo: Integer)
    var
        OutboundItemLedgEntry: Record "Item Ledger Entry";
    begin
        with OutboundItemLedgEntry do begin
            Get(OutboundItemEntryNo);
            if Quantity > 0 then
                FieldError(Quantity);
            if GlobalItemLedgEntry.Quantity < 0 then
                GlobalItemLedgEntry.FieldError(Quantity);

            "Shipped Qty. Not Returned" := "Shipped Qty. Not Returned" + Abs(ItemJnlLine.Quantity);
            if "Shipped Qty. Not Returned" > 0 then
                FieldError("Shipped Qty. Not Returned", Text004);
            "Applied Entry to Adjust" := true;
            Modify();
        end;
    end;

    procedure InitTransValueEntry(var ValueEntry: Record "Value Entry"; ItemLedgEntry: Record "Item Ledger Entry")
    var
        AdjCostInvoicedLCY: Decimal;
        AdjCostInvoicedACY: Decimal;
        DiscountAmount: Decimal;
        IsHandled: Boolean;
    begin
        InitValueEntry(ValueEntry, ItemLedgEntry);
        OnInitTransValueEntryOnAfterInitValueEntry(ValueEntry, ItemLedgEntry);
        ValueEntry."Valued Quantity" := ItemLedgEntry.Quantity;
        ValueEntry."Invoiced Quantity" := ValueEntry."Valued Quantity";
        ValueEntry."Location Code" := ItemLedgEntry."Location Code";
        ValueEntry."Valuation Date" := GlobalValueEntry."Valuation Date";
        if AverageTransfer then begin
            ValuateAppliedAvgEntry(GlobalValueEntry, Item);
            OnInitTransValueEntryOnBeforeCalcCostAmounts(GlobalValueEntry, ValueEntry, GlobalItemTrackingSetup, IsHandled);
            if not IsHandled then begin
                ValueEntry."Cost Amount (Actual)" := -GlobalValueEntry."Cost Amount (Actual)";
                ValueEntry."Cost Amount (Actual) (ACY)" := -GlobalValueEntry."Cost Amount (Actual) (ACY)";
            end;
            ValueEntry."Cost per Unit" := 0;
            ValueEntry."Cost per Unit (ACY)" := 0;
            ValueEntry."Valued By Average Cost" :=
                not (ItemLedgEntry.Positive or
                    (ValueEntry."Document Type" = ValueEntry."Document Type"::"Transfer Receipt"));
        end else begin
            CalcAdjustedCost(
                OldItemLedgEntry, ValueEntry."Valued Quantity",
                AdjCostInvoicedLCY, AdjCostInvoicedACY, DiscountAmount);
            ValueEntry."Cost Amount (Actual)" := AdjCostInvoicedLCY;
            ValueEntry."Cost Amount (Actual) (ACY)" := AdjCostInvoicedACY;
            ValueEntry."Cost per Unit" := 0;
            ValueEntry."Cost per Unit (ACY)" := 0;

            GlobalValueEntry."Cost Amount (Actual)" := GlobalValueEntry."Cost Amount (Actual)" - ValueEntry."Cost Amount (Actual)";
            if GLSetup."Additional Reporting Currency" <> '' then
                GlobalValueEntry."Cost Amount (Actual) (ACY)" :=
                    CurrExchRate.ExchangeAmtLCYToFCY(
                    ValueEntry."Posting Date", GLSetup."Additional Reporting Currency",
                    Round(GlobalValueEntry."Cost Amount (Actual)", GLSetup."Amount Rounding Precision"),
                    CurrExchRate.ExchangeRate(
                        ValueEntry."Posting Date", GLSetup."Additional Reporting Currency"));
        end;

        GlobalValueEntry."Discount Amount" := 0;
        ValueEntry."Discount Amount" := 0;
        GlobalValueEntry."Cost per Unit" := 0;
        GlobalValueEntry."Cost per Unit (ACY)" := 0;
    end;

    local procedure ValuateAppliedAvgEntry(var ValueEntry: Record "Value Entry"; Item: Record Item)
    begin
        with ValueEntry do
            if (ItemJnlLine."Applies-to Entry" = 0) and
               ("Item Ledger Entry Type" <> "Item Ledger Entry Type"::Output)
            then begin
                if (ItemJnlLine.Quantity = 0) and (ItemJnlLine."Invoiced Quantity" <> 0) then begin
                    GetLastDirectCostValEntry("Item Ledger Entry No.");
                    "Valued By Average Cost" := DirCostValueEntry."Valued By Average Cost";
                end else
                    "Valued By Average Cost" := not ("Document Type" = "Document Type"::"Transfer Receipt");

                if Item."Inventory Value Zero" then begin
                    "Cost per Unit" := 0;
                    "Cost per Unit (ACY)" := 0;
                end else begin
                    if "Item Ledger Entry Type" = "Item Ledger Entry Type"::Transfer then begin
                        if SKUExists and (InvtSetup."Average Cost Calc. Type" <> InvtSetup."Average Cost Calc. Type"::Item) then
                            "Cost per Unit" := SKU."Unit Cost"
                        else
                            "Cost per Unit" := Item."Unit Cost";
                    end else
                        "Cost per Unit" := ItemJnlLine."Unit Cost";

                    OnValuateAppliedAvgEntryOnAfterSetCostPerUnit(ValueEntry, ItemJnlLine, InvtSetup, SKU, SKUExists);

                    if GLSetup."Additional Reporting Currency" <> '' then begin
                        if (ItemJnlLine."Source Currency Code" = GLSetup."Additional Reporting Currency") and
                           ("Item Ledger Entry Type" <> "Item Ledger Entry Type"::Transfer)
                        then
                            "Cost per Unit (ACY)" := ItemJnlLine."Unit Cost (ACY)"
                        else
                            "Cost per Unit (ACY)" :=
                              Round(
                                CurrExchRate.ExchangeAmtLCYToFCY(
                                  "Posting Date", GLSetup."Additional Reporting Currency", "Cost per Unit",
                                  CurrExchRate.ExchangeRate(
                                    "Posting Date", GLSetup."Additional Reporting Currency")),
                                Currency."Unit-Amount Rounding Precision");
                    end;
                end;

                OnValuateAppliedAvgEntryOnAfterUpdateCostAmounts(ValueEntry, ItemJnlLine);

                if "Expected Cost" then begin
                    "Cost Amount (Expected)" := "Valued Quantity" * "Cost per Unit";
                    "Cost Amount (Expected) (ACY)" := "Valued Quantity" * "Cost per Unit (ACY)";
                end else begin
                    "Cost Amount (Actual)" := "Valued Quantity" * "Cost per Unit";
                    "Cost Amount (Actual) (ACY)" := "Valued Quantity" * "Cost per Unit (ACY)";
                end;
            end;
    end;

    local procedure CalcAdjustedCost(PosItemLedgEntry: Record "Item Ledger Entry"; AppliedQty: Decimal; var AdjustedCostLCY: Decimal; var AdjustedCostACY: Decimal; var DiscountAmount: Decimal)
    var
        PosValueEntry: Record "Value Entry";
    begin
        AdjustedCostLCY := 0;
        AdjustedCostACY := 0;
        DiscountAmount := 0;
        with PosValueEntry do begin
            SetCurrentKey("Item Ledger Entry No.");
            SetRange("Item Ledger Entry No.", PosItemLedgEntry."Entry No.");
            FindSet();
            repeat
                if "Partial Revaluation" then begin
                    AdjustedCostLCY := AdjustedCostLCY +
                      "Cost Amount (Actual)" / "Valued Quantity" * PosItemLedgEntry.Quantity;
                    AdjustedCostACY := AdjustedCostACY +
                      "Cost Amount (Actual) (ACY)" / "Valued Quantity" * PosItemLedgEntry.Quantity;
                end else begin
                    AdjustedCostLCY := AdjustedCostLCY + "Cost Amount (Actual)" + "Cost Amount (Expected)";
                    AdjustedCostACY := AdjustedCostACY + "Cost Amount (Actual) (ACY)" + "Cost Amount (Expected) (ACY)";
                    DiscountAmount := DiscountAmount - "Discount Amount";
                end;
            until Next() = 0;

            AdjustedCostLCY := AdjustedCostLCY * AppliedQty / PosItemLedgEntry.Quantity;
            AdjustedCostACY := AdjustedCostACY * AppliedQty / PosItemLedgEntry.Quantity;
            DiscountAmount := DiscountAmount * AppliedQty / PosItemLedgEntry.Quantity;
        end;
        OnAfterCalcAdjustedCost(ItemJnlLine, AdjustedCostLCY, AdjustedCostACY);
    end;

    local procedure GetMaxValuationDate(ItemLedgerEntry: Record "Item Ledger Entry"): Date
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Revaluation);
        if not ValueEntry.FindLast() then begin
            ValueEntry.SetRange("Entry Type");
            ValueEntry.FindLast();
        end;
        exit(ValueEntry."Valuation Date");
    end;

    local procedure GetValuationDate(var ValueEntry: Record "Value Entry"; OldItemLedgEntry: Record "Item Ledger Entry")
    var
        OldValueEntry: Record "Value Entry";
        IsHandled: Boolean;
    begin
        with OldItemLedgEntry do begin
            OldValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
            OldValueEntry.SetRange("Item Ledger Entry No.", "Entry No.");
            OldValueEntry.SetRange("Entry Type", OldValueEntry."Entry Type"::Revaluation);
            OnGetValuationDateOnAfterOldValueEntrySetFilters(OldValueEntry, ValueEntry, OldItemLedgEntry);
            if not OldValueEntry.FindLast() then begin
                OldValueEntry.SetRange("Entry Type");
                IsHandled := false;
                OnGetValuationDateOnBeforeFindOldValueEntry(OldValueEntry, IsHandled);
                if IsHandled then
                    exit;
                OldValueEntry.FindLast();
            end;
            if Positive then begin
                if (ValueEntry."Posting Date" < OldValueEntry."Valuation Date") or
                   (ItemJnlLine."Applies-to Entry" <> 0)
                then begin
                    ValueEntry."Valuation Date" := OldValueEntry."Valuation Date";
                    SetValuationDateAllValueEntrie(
                      ValueEntry."Item Ledger Entry No.",
                      OldValueEntry."Valuation Date",
                      ItemJnlLine."Applies-to Entry" <> 0)
                end else
                    if ValueEntry."Valuation Date" <= ValueEntry."Posting Date" then begin
                        ValueEntry."Valuation Date" := ValueEntry."Posting Date";
                        SetValuationDateAllValueEntrie(
                          ValueEntry."Item Ledger Entry No.",
                          ValueEntry."Posting Date",
                          ItemJnlLine."Applies-to Entry" <> 0)
                    end
            end else
                if OldValueEntry."Valuation Date" < ValueEntry."Valuation Date" then begin
                    UpdateAvgCostAdjmtBuffer(OldItemLedgEntry, OldValueEntry."Valuation Date");
                    OldValueEntry.ModifyAll("Valuation Date", ValueEntry."Valuation Date");
                    UpdateLinkedValuationDate(ValueEntry."Valuation Date", "Entry No.", Positive);
                end;
        end;
    end;

    local procedure UpdateLinkedValuationDate(FromValuationDate: Date; FromItemledgEntryNo: Integer; FromInbound: Boolean)
    var
        ToItemApplnEntry: Record "Item Application Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateLinkedValuationDate(GlobalItemLedgEntry, FromItemledgEntryNo, IsHandled);
        if IsHandled then
            exit;

        with ToItemApplnEntry do begin
            if FromInbound then begin
                SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.");
                SetRange("Inbound Item Entry No.", FromItemledgEntryNo);
                SetFilter("Outbound Item Entry No.", '<>%1', 0);
            end else begin
                SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.");
                SetRange("Outbound Item Entry No.", FromItemledgEntryNo);
            end;
            SetFilter("Item Ledger Entry No.", '<>%1', FromItemledgEntryNo);
            if FindSet() then
                repeat
                    if FromInbound or ("Inbound Item Entry No." <> 0) then begin
                        GetLastDirectCostValEntry("Inbound Item Entry No.");
                        if DirCostValueEntry."Valuation Date" < FromValuationDate then begin
                            UpdateValuationDate(FromValuationDate, "Item Ledger Entry No.", FromInbound);
                            UpdateLinkedValuationDate(FromValuationDate, "Item Ledger Entry No.", not FromInbound);
                        end;
                    end;
                until Next() = 0;
        end;
    end;

    local procedure UpdateLinkedValuationUnapply(FromValuationDate: Date; FromItemLedgEntryNo: Integer; FromInbound: Boolean)
    var
        ToItemApplnEntry: Record "Item Application Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        with ToItemApplnEntry do begin
            if FromInbound then begin
                SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.");
                SetRange("Inbound Item Entry No.", FromItemLedgEntryNo);
                SetFilter("Outbound Item Entry No.", '<>%1', 0);
            end else begin
                SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.");
                SetRange("Outbound Item Entry No.", FromItemLedgEntryNo);
            end;
            SetFilter("Item Ledger Entry No.", '<>%1', FromItemLedgEntryNo);
            if Find('-') then
                repeat
                    if FromInbound or ("Inbound Item Entry No." <> 0) then begin
                        GetLastDirectCostValEntry("Inbound Item Entry No.");
                        if DirCostValueEntry."Valuation Date" < FromValuationDate then begin
                            UpdateValuationDate(FromValuationDate, "Item Ledger Entry No.", FromInbound);
                            UpdateLinkedValuationUnapply(FromValuationDate, "Item Ledger Entry No.", not FromInbound);
                        end
                        else begin
                            ItemLedgerEntry.Get("Inbound Item Entry No.");
                            FromValuationDate := GetMaxAppliedValuationdate(ItemLedgerEntry);
                            if FromValuationDate < DirCostValueEntry."Valuation Date" then begin
                                UpdateValuationDate(FromValuationDate, ItemLedgerEntry."Entry No.", FromInbound);
                                UpdateLinkedValuationUnapply(FromValuationDate, ItemLedgerEntry."Entry No.", not FromInbound);
                            end;
                        end;
                    end;
                until Next() = 0;
        end;
    end;

    local procedure UpdateValuationDate(FromValuationDate: Date; FromItemLedgEntryNo: Integer; FromInbound: Boolean)
    var
        ToValueEntry2: Record "Value Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateValuationDate(GlobalItemLedgEntry, FromItemLedgEntryNo, IsHandled);
        if IsHandled then
            exit;

        ToValueEntry2.SetCurrentKey("Item Ledger Entry No.");
        ToValueEntry2.SetRange("Item Ledger Entry No.", FromItemLedgEntryNo);
        ToValueEntry2.Find('-');
        if FromInbound then begin
            if ToValueEntry2."Valuation Date" < FromValuationDate then
                ToValueEntry2.ModifyAll("Valuation Date", FromValuationDate);
        end else
            repeat
                if ToValueEntry2."Entry Type" = ToValueEntry2."Entry Type"::Revaluation then begin
                    if ToValueEntry2."Valuation Date" < FromValuationDate then begin
                        ToValueEntry2."Valuation Date" := FromValuationDate;
                        ToValueEntry2.Modify();
                    end;
                end else begin
                    ToValueEntry2."Valuation Date" := FromValuationDate;
                    ToValueEntry2.Modify();
                end;
            until ToValueEntry2.Next() = 0;
    end;

    local procedure CreateItemJnlLineFromEntry(ItemLedgEntry: Record "Item Ledger Entry"; NewQuantity: Decimal; var ItemJnlLine: Record "Item Journal Line")
    begin
        Clear(ItemJnlLine);
        with ItemJnlLine do begin
            "Entry Type" := ItemLedgEntry."Entry Type"; // no mapping needed
            Quantity := Signed(NewQuantity);
            "Item No." := ItemLedgEntry."Item No.";
            CopyTrackingFromItemLedgEntry(ItemLedgEntry);
        end;

        OnAfterCreateItemJnlLineFromEntry(ItemJnlLine, ItemLedgEntry);
    end;

    local procedure GetAppliedFromValues(var ValueEntry: Record "Value Entry")
    var
        NegValueEntry: Record "Value Entry";
    begin
        with NegValueEntry do begin
            SetCurrentKey("Item Ledger Entry No.", "Entry Type");
            SetRange("Item Ledger Entry No.", ItemJnlLine."Applies-from Entry");
            SetRange("Entry Type", "Entry Type"::Revaluation);
            if not FindLast() then begin
                SetRange("Entry Type");
                FindLast();
            end;

            if "Valuation Date" > ValueEntry."Posting Date" then
                ValueEntry."Valuation Date" := "Valuation Date"
            else
                ValueEntry."Valuation Date" := ItemJnlLine."Posting Date";
        end;

        OnAfterGetAppliedFromValues(ValueEntry, NegValueEntry);
    end;

    local procedure RoundAmtValueEntry(var ValueEntry: Record "Value Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRoundAmtValueEntry(ValueEntry, IsHandled);
        if IsHandled then
            exit;

        with ValueEntry do begin
            "Sales Amount (Actual)" := Round("Sales Amount (Actual)");
            "Sales Amount (Expected)" := Round("Sales Amount (Expected)");
            "Purchase Amount (Actual)" := Round("Purchase Amount (Actual)");
            "Purchase Amount (Expected)" := Round("Purchase Amount (Expected)");
            "Discount Amount" := Round("Discount Amount");
            "Cost Amount (Actual)" := Round("Cost Amount (Actual)");
            "Cost Amount (Expected)" := Round("Cost Amount (Expected)");
            "Cost Amount (Non-Invtbl.)" := Round("Cost Amount (Non-Invtbl.)");
            "Cost Amount (Actual) (ACY)" := Round("Cost Amount (Actual) (ACY)", Currency."Amount Rounding Precision");
            "Cost Amount (Expected) (ACY)" := Round("Cost Amount (Expected) (ACY)", Currency."Amount Rounding Precision");
            "Cost Amount (Non-Invtbl.)(ACY)" := Round("Cost Amount (Non-Invtbl.)(ACY)", Currency."Amount Rounding Precision");
        end;
    end;

    local procedure RetrieveCostPerUnit(ItemJnlLine: Record "Item Journal Line"; SKU: Record "Stockkeeping Unit"; SKUExists: Boolean): Decimal
    var
        UnitCost: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRetrieveCostPerUnit(ItemJnlLine, SKU, SKUExists, UnitCost, IsHandled);
        if IsHandled then
            exit(UnitCost);

        with ItemJnlLine do begin
            if (Item."Costing Method" = Item."Costing Method"::Standard) and
               ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
               ("Item Charge No." = '') and
               ("Applies-from Entry" = 0) and
               not Adjustment
            then begin
                if SKUExists then
                    exit(SKU."Unit Cost");
                exit(Item."Unit Cost");
            end;
            exit("Unit Cost");
        end;
    end;

    local procedure RetrieveCostPerUnitACY(CostPerUnit: Decimal): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PostingDate: Date;
    begin
        with ItemJnlLine do begin
            if Adjustment or ("Source Currency Code" = GLSetup."Additional Reporting Currency") and
               ((Item."Costing Method" <> Item."Costing Method"::Standard) or
                (("Discount Amount" = 0) and ("Indirect Cost %" = 0) and ("Overhead Rate" = 0)))
            then
                exit("Unit Cost (ACY)");
            if ("Value Entry Type" = "Value Entry Type"::Revaluation) and ItemLedgerEntry.Get("Applies-to Entry") then
                PostingDate := ItemLedgerEntry."Posting Date"
            else
                PostingDate := "Posting Date";
            exit(Round(CurrExchRate.ExchangeAmtLCYToFCY(
                  PostingDate, GLSetup."Additional Reporting Currency",
                  CostPerUnit, CurrExchRate.ExchangeRate(
                    PostingDate, GLSetup."Additional Reporting Currency")),
                Currency."Unit-Amount Rounding Precision"));
        end;
    end;

    local procedure CalcCostPerUnit(Cost: Decimal; Quantity: Decimal; IsACY: Boolean): Decimal
    var
        RndgPrec: Decimal;
    begin
        GetGLSetup();

        if IsACY then
            RndgPrec := Currency."Unit-Amount Rounding Precision"
        else
            RndgPrec := GLSetup."Unit-Amount Rounding Precision";

        if Quantity <> 0 then
            exit(Round(Cost / Quantity, RndgPrec));
        exit(0);
    end;

    local procedure CalcPosShares(var DirCost: Decimal; var OvhdCost: Decimal; var PurchVar: Decimal; var DirCostACY: Decimal; var OvhdCostACY: Decimal; var PurchVarACY: Decimal; var CalcUnitCost: Boolean; CalcPurchVar: Boolean; Expected: Boolean)
    var
        CostCalcMgt: Codeunit "Cost Calculation Management";
    begin
        with ItemJnlLine do begin
            if Expected then begin
                DirCost := "Unit Cost" * Quantity + RoundingResidualAmount;
                PurchVar := 0;
                PurchVarACY := 0;
                OvhdCost := 0;
                OvhdCostACY := 0;
            end else begin
                OvhdCost :=
                  Round(
                    CostCalcMgt.CalcOvhdCost(
                      Amount, "Indirect Cost %", "Overhead Rate", "Invoiced Quantity"),
                    GLSetup."Amount Rounding Precision");
                DirCost := Amount;
                if CalcPurchVar then
                    PurchVar := "Unit Cost" * "Invoiced Quantity" - DirCost - OvhdCost
                else begin
                    PurchVar := 0;
                    PurchVarACY := 0;
                end;
            end;

            if GLSetup."Additional Reporting Currency" <> '' then begin
                DirCostACY := ACYMgt.CalcACYAmt(DirCost, "Posting Date", false);
                OvhdCostACY := ACYMgt.CalcACYAmt(OvhdCost, "Posting Date", false);
                "Unit Cost (ACY)" :=
                  Round(
                    CurrExchRate.ExchangeAmtLCYToFCY(
                      "Posting Date", GLSetup."Additional Reporting Currency", "Unit Cost",
                      CurrExchRate.ExchangeRate(
                        "Posting Date", GLSetup."Additional Reporting Currency")),
                    Currency."Unit-Amount Rounding Precision");
                PurchVarACY := "Unit Cost (ACY)" * "Invoiced Quantity" - DirCostACY - OvhdCostACY;
            end;
            CalcUnitCost := (DirCost <> 0) and ("Unit Cost" = 0);
        end;

        OnAfterCalcPosShares(ItemJnlLine, DirCost, OvhdCost, PurchVar, DirCostACY, OvhdCostACY, PurchVarACY, CalcUnitCost, CalcPurchVar, Expected, GlobalItemLedgEntry);
    end;

    local procedure CalcPurchCorrShares(var OverheadAmount: Decimal; var OverheadAmountACY: Decimal; var VarianceAmount: Decimal; var VarianceAmountACY: Decimal)
    var
        OldItemLedgEntry: Record "Item Ledger Entry";
        OldValueEntry: Record "Value Entry";
        CostAmt: Decimal;
        CostAmtACY: Decimal;
    begin
        with ItemJnlLine do begin
            OldValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
            OldValueEntry.SetRange("Item Ledger Entry No.", "Applies-to Entry");
            OldValueEntry.SetRange("Entry Type", OldValueEntry."Entry Type"::"Indirect Cost");
            if OldValueEntry.FindSet() then
                repeat
                    if not OldValueEntry."Partial Revaluation" then begin
                        CostAmt := CostAmt + OldValueEntry."Cost Amount (Actual)";
                        CostAmtACY := CostAmtACY + OldValueEntry."Cost Amount (Actual) (ACY)";
                    end;
                until OldValueEntry.Next() = 0;
            if (CostAmt <> 0) or (CostAmtACY <> 0) then begin
                OldItemLedgEntry.Get("Applies-to Entry");
                OverheadAmount := Round(
                    CostAmt / OldItemLedgEntry."Invoiced Quantity" * "Invoiced Quantity",
                    GLSetup."Amount Rounding Precision");
                OverheadAmountACY := Round(
                    CostAmtACY / OldItemLedgEntry."Invoiced Quantity" * "Invoiced Quantity",
                    Currency."Unit-Amount Rounding Precision");
                if Item."Costing Method" = Item."Costing Method"::Standard then begin
                    VarianceAmount := -OverheadAmount;
                    VarianceAmountACY := -OverheadAmountACY;
                end else begin
                    VarianceAmount := 0;
                    VarianceAmountACY := 0;
                end;
            end else
                if Item."Costing Method" = Item."Costing Method"::Standard then begin
                    OldValueEntry.SetRange("Entry Type", OldValueEntry."Entry Type"::Variance);
                    VarianceRequired := OldValueEntry.FindFirst();
                end;
        end;
    end;

    local procedure GetLastDirectCostValEntry(ItemLedgEntryNo: Decimal)
    var
        Found: Boolean;
    begin
        if ItemLedgEntryNo = DirCostValueEntry."Item Ledger Entry No." then
            exit;
        DirCostValueEntry.Reset();
        DirCostValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        DirCostValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
        DirCostValueEntry.SetRange("Entry Type", DirCostValueEntry."Entry Type"::"Direct Cost");
        DirCostValueEntry.SetFilter("Item Charge No.", '%1', '');
        Found := DirCostValueEntry.FindLast();
        DirCostValueEntry.SetRange("Item Charge No.");
        if not Found then
            DirCostValueEntry.FindLast();
    end;

    local procedure IsFirstValueEntry(ItemLedgEntryNo: Integer): Boolean
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
        exit(ValueEntry.IsEmpty);
    end;

    local procedure CalcExpectedCost(var InvdValueEntry: Record "Value Entry"; ItemLedgEntryNo: Integer; InvoicedQty: Decimal; Quantity: Decimal; var ExpectedCost: Decimal; var ExpectedCostACY: Decimal; var ExpectedSalesAmt: Decimal; var ExpectedPurchAmt: Decimal; CalcReminder: Boolean)
    var
        ValueEntry: Record "Value Entry";
    begin
        ExpectedCost := 0;
        ExpectedCostACY := 0;
        ExpectedSalesAmt := 0;
        ExpectedPurchAmt := 0;

        with ValueEntry do begin
            SetCurrentKey("Item Ledger Entry No.", "Entry Type");
            SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
            SetFilter("Entry Type", '<>%1', "Entry Type"::Revaluation);
            OnCalcExpectedCostOnBeforeFindValueEntry(
              ValueEntry, ItemLedgEntryNo, InvoicedQty, Quantity, ExpectedCost, ExpectedCostACY, ExpectedSalesAmt, ExpectedPurchAmt, CalcReminder, InvdValueEntry, ItemJnlLine);
            if FindSet() and "Expected Cost" then
                if CalcReminder then begin
                    CalcSums(
                      "Cost Amount (Expected)", "Cost Amount (Expected) (ACY)",
                      "Sales Amount (Expected)", "Purchase Amount (Expected)");
                    ExpectedCost := -"Cost Amount (Expected)";
                    ExpectedCostACY := -"Cost Amount (Expected) (ACY)";
                    if not CalledFromAdjustment then begin
                        ExpectedSalesAmt := -"Sales Amount (Expected)";
                        ExpectedPurchAmt := -"Purchase Amount (Expected)";
                    end
                end else
                    if InvdValueEntry.Adjustment and
                       (InvdValueEntry."Entry Type" = InvdValueEntry."Entry Type"::"Direct Cost")
                    then begin
                        ExpectedCost := -InvdValueEntry."Cost Amount (Actual)";
                        ExpectedCostACY := -InvdValueEntry."Cost Amount (Actual) (ACY)";
                        if not CalledFromAdjustment then begin
                            ExpectedSalesAmt := -InvdValueEntry."Sales Amount (Actual)";
                            ExpectedPurchAmt := -InvdValueEntry."Purchase Amount (Actual)";
                        end
                    end else begin
                        repeat
                            if "Expected Cost" and not Adjustment then begin
                                ExpectedCost := ExpectedCost + "Cost Amount (Expected)";
                                ExpectedCostACY := ExpectedCostACY + "Cost Amount (Expected) (ACY)";
                                if not CalledFromAdjustment then begin
                                    ExpectedSalesAmt := ExpectedSalesAmt + "Sales Amount (Expected)";
                                    ExpectedPurchAmt := ExpectedPurchAmt + "Purchase Amount (Expected)";
                                end;
                            end;
                        until Next() = 0;
                        ExpectedCost :=
                          CalcExpCostToBalance(ExpectedCost, InvoicedQty, Quantity, GLSetup."Amount Rounding Precision");
                        ExpectedCostACY :=
                          CalcExpCostToBalance(ExpectedCostACY, InvoicedQty, Quantity, Currency."Amount Rounding Precision");
                        if not CalledFromAdjustment then begin
                            ExpectedSalesAmt :=
                              CalcExpCostToBalance(ExpectedSalesAmt, InvoicedQty, Quantity, GLSetup."Amount Rounding Precision");
                            ExpectedPurchAmt :=
                              CalcExpCostToBalance(ExpectedPurchAmt, InvoicedQty, Quantity, GLSetup."Amount Rounding Precision");
                        end;
                    end;
        end;

        OnAfterCalcExpectedCost(ValueEntry, ItemLedgEntryNo, ExpectedCost, ExpectedCostACY, ExpectedSalesAmt, ExpectedPurchAmt)
    end;

    local procedure CalcExpCostToBalance(ExpectedCost: Decimal; InvoicedQty: Decimal; Quantity: Decimal; RoundPrecision: Decimal): Decimal
    begin
        exit(-Round(InvoicedQty / Quantity * ExpectedCost, RoundPrecision));
    end;

    local procedure MoveValEntryDimToValEntryDim(var ToValueEntry: Record "Value Entry"; FromValueEntry: Record "Value Entry")
    begin
        ToValueEntry."Global Dimension 1 Code" := FromValueEntry."Global Dimension 1 Code";
        ToValueEntry."Global Dimension 2 Code" := FromValueEntry."Global Dimension 2 Code";
        ToValueEntry."Dimension Set ID" := FromValueEntry."Dimension Set ID";
        OnAfterMoveValEntryDimToValEntryDim(ToValueEntry, FromValueEntry);
    end;

    procedure AutoTrack(var ItemLedgEntryRec: Record "Item Ledger Entry"; IsReserved: Boolean)
    var
        ReservMgt: Codeunit "Reservation Management";
    begin
        if Item."Order Tracking Policy" = Item."Order Tracking Policy"::None then begin
            if not IsReserved then
                exit;

            // Ensure that Item Tracking is not left on the item ledger entry:
            ReservMgt.SetReservSource(ItemLedgEntryRec);
            ReservMgt.SetItemTrackingHandling(1);
            ReservMgt.ClearSurplus();
            exit;
        end;

        ReservMgt.SetReservSource(ItemLedgEntryRec);
        ReservMgt.SetItemTrackingHandling(1);
        ReservMgt.DeleteReservEntries(false, ItemLedgEntryRec."Remaining Quantity");
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(ItemLedgEntryRec."Remaining Quantity");
    end;

    procedure SetPostponeReservationHandling(Postpone: Boolean)
    begin
        // Used when posting Transfer Order receipts
        PostponeReservationHandling := Postpone;
    end;

    local procedure SetupSplitJnlLine(var ItemJnlLine2: Record "Item Journal Line"; TrackingSpecExists: Boolean): Boolean
    var
        LateBindingMgt: Codeunit "Late Binding Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        NonDistrQuantity: Decimal;
        NonDistrAmount: Decimal;
        NonDistrAmountACY: Decimal;
        NonDistrDiscountAmount: Decimal;
        SignFactor: Integer;
        CalcWarrantyDate: Date;
        CalcExpirationDate: Date;
        Invoice: Boolean;
        ExpirationDateChecked: Boolean;
        PostItemJnlLine: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeSetupSplitJnlLineProcedure(ItemJnlLine2, TrackingSpecExists, CalledFromAdjustment);

        ItemJnlLineOrigin := ItemJnlLine2;
        TempSplitItemJnlLine.Reset();
        TempSplitItemJnlLine.DeleteAll();

        DisableItemTracking := not ItemJnlLine2.ItemPosting();
        Invoice := ItemJnlLine2."Invoiced Qty. (Base)" <> 0;

        if (ItemJnlLine2."Entry Type" = ItemJnlLine2."Entry Type"::Transfer) and PostponeReservationHandling then
            SignFactor := 1
        else
            SignFactor := ItemJnlLine2.Signed(1);

        GlobalItemTrackingCode.Code := Item."Item Tracking Code";
        OnSetupSplitJnlLineOnBeforeGetItemTrackingSetup(ItemJnlLine2, TrackingSpecExists, CalledFromAdjustment, Item, GlobalItemTrackingCode);
        ItemTrackingMgt.GetItemTrackingSetup(
            GlobalItemTrackingCode, ItemJnlLine."Entry Type",
            ItemJnlLine.Signed(ItemJnlLine."Quantity (Base)") > 0, GlobalItemTrackingSetup);

        OnSetupSplitJnlLineOnAfterGetItemTrackingSetup(GlobalItemTrackingCode, ItemJnlLine2, GlobalItemTrackingSetup, ItemJnlLine);

        if Item."Costing Method" = Item."Costing Method"::Specific then begin
            Item.TestField("Item Tracking Code");
            GlobalItemTrackingCode.TestField("SN Specific Tracking", true);
        end;

        OnBeforeSetupSplitJnlLine(ItemJnlLine2, TrackingSpecExists, TempTrackingSpecification);

        if not ItemJnlLine2.Correction and (ItemJnlLine2."Quantity (Base)" <> 0) and TrackingSpecExists then begin
            if DisableItemTracking then begin
                if not TempTrackingSpecification.IsEmpty() then
                    Error(Text021, ItemJnlLine2.FieldCaption("Operation No."), ItemJnlLine2."Operation No.");
            end else begin
                if TempTrackingSpecification.IsEmpty() then
                    Error(Text100);

                CheckItemTrackingIsEmpty(ItemJnlLine2);

                if Format(GlobalItemTrackingCode."Warranty Date Formula") <> '' then
                    CalcWarrantyDate := CalcDate(GlobalItemTrackingCode."Warranty Date Formula", ItemJnlLine2."Document Date");

                IsHandled := false;
                OnBeforeCalcExpirationDate(ItemJnlLine2, CalcExpirationDate, IsHandled, Item);
                if not IsHandled then
                    if Format(Item."Expiration Calculation") <> '' then
                        CalcExpirationDate := CalcDate(Item."Expiration Calculation", ItemJnlLine2."Document Date");

                IsHandled := false;
                OnSetupSplitJnlLineOnBeforeReallocateTrkgSpecification(GlobalItemTrackingCode, TempTrackingSpecification, ItemJnlLine2, SignFactor, IsHandled);
                if not IsHandled then
                    if SignFactor * ItemJnlLine2.Quantity < 0 then // Demand
                        if GlobalItemTrackingCode."SN Specific Tracking" or GlobalItemTrackingCode."Lot Specific Tracking" then
                            LateBindingMgt.ReallocateTrkgSpecification(TempTrackingSpecification);

                TempTrackingSpecification.CalcSums(
                  "Qty. to Handle (Base)", "Qty. to Invoice (Base)", "Qty. to Handle", "Qty. to Invoice");
                TempTrackingSpecification.TestFieldError(TempTrackingSpecification.FieldCaption("Qty. to Handle (Base)"),
                  TempTrackingSpecification."Qty. to Handle (Base)", SignFactor * ItemJnlLine2."Quantity (Base)");

                if Invoice then
                    TempTrackingSpecification.TestFieldError(TempTrackingSpecification.FieldCaption("Qty. to Invoice (Base)"),
                      TempTrackingSpecification."Qty. to Invoice (Base)", SignFactor * ItemJnlLine2."Invoiced Qty. (Base)");

                OnSetupSplitJnlLineOnBeforeCalcNonDistrQuantity(TempTrackingSpecification, ItemJnlLine2, Invoice, SignFactor);
                NonDistrQuantity :=
                    UOMMgt.CalcQtyFromBase(
                        ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code", ItemJnlLine2."Unit of Measure Code",
                        UOMMgt.RoundQty(
                            UOMMgt.CalcBaseQty(
                                ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code", ItemJnlLine2."Unit of Measure Code",
                                ItemJnlLine2.Quantity, ItemJnlLine2."Qty. per Unit of Measure")),
                    ItemJnlLine2."Qty. per Unit of Measure");
                NonDistrAmount := ItemJnlLine2.Amount;
                NonDistrAmountACY := ItemJnlLine2."Amount (ACY)";
                NonDistrDiscountAmount := ItemJnlLine2."Discount Amount";

                OnSetupSplitJnlLineOnBeforeSplitTempLines(TempSplitItemJnlLine, TempTrackingSpecification);

                TempTrackingSpecification.FindSet();
                repeat
                    if GlobalItemTrackingCode."Man. Warranty Date Entry Reqd." then
                        TempTrackingSpecification.TestField("Warranty Date");

                    OnSetupSplitJnlLineOnBeforeCheckUseExpirationDates(ItemJnlLine2, TempTrackingSpecification, Item, CalcExpirationDate);
                    if GlobalItemTrackingCode."Use Expiration Dates" then
                        CheckExpirationDate(ItemJnlLine2, SignFactor, CalcExpirationDate, ExpirationDateChecked);
                    OnSetupSplitJnlLineOnAfterCheckExpirationDate(ItemJnlLine2, TempTrackingSpecification, Item);

                    CheckItemTrackingInformation(
                        ItemJnlLine2, TempTrackingSpecification, SignFactor, GlobalItemTrackingCode, GlobalItemTrackingSetup);

                    if TempTrackingSpecification."Warranty Date" = 0D then
                        TempTrackingSpecification."Warranty Date" := CalcWarrantyDate;

                    TempTrackingSpecification.Modify();
                    TempSplitItemJnlLine := ItemJnlLine2;
                    PostItemJnlLine :=
                      PostItemJnlLine or
                      SetupTempSplitItemJnlLine(
                        ItemJnlLine2, SignFactor, NonDistrQuantity, NonDistrAmount,
                        NonDistrAmountACY, NonDistrDiscountAmount, Invoice);
                    OnSetupSplitJnlLineOnAfterSetupTempSplitItemJnlLine(ItemJnlLine2, TempSplitItemJnlLine, TempTrackingSpecification);
                until TempTrackingSpecification.Next() = 0;
            end;
        end else
            InsertTempSplitItemJnlLine(ItemJnlLine2, PostItemJnlLine);

        OnAfterSetupSplitJnlLine(
            ItemJnlLine2, TempSplitItemJnlLine, ItemJnlLineOrigin, TempTrackingSpecification,
            TrackingSpecExists, CalledFromAdjustment, PostponeReservationHandling, PostItemJnlLine);
        exit(PostItemJnlLine);
    end;

    local procedure InsertTempSplitItemJnlLine(ItemJnlLine2: Record "Item Journal Line"; var PostItemJnlLine: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertTempSplitItemJnlLine(ItemJnlLine2, IsServUndoConsumption, PostponeReservationHandling, TempSplitItemJnlLine, PostItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        TempSplitItemJnlLine := ItemJnlLine2;
        TempSplitItemJnlLine.Insert();

        OnAfterInsertTempSplitItemJnlLine(TempSplitItemJnlLine, ItemJnlLine2)
    end;

    local procedure SplitItemJnlLine(var ItemJnlLine2: Record "Item Journal Line"; PostItemJnlLine: Boolean): Boolean
    var
        FreeEntryNo: Integer;
        JnlLineNo: Integer;
        SignFactor: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnSplitItemJnlLineOnBeforeTracking(
            ItemJnlLine2, PostItemJnlLine, TempTrackingSpecification, GlobalItemLedgEntry, TempItemEntryRelation,
            PostponeReservationHandling, SignFactor, IsHandled);
        if not IsHandled then
            if (ItemJnlLine2."Quantity (Base)" <> 0) and ItemJnlLine2.TrackingExists() then begin
                if (ItemJnlLine2."Entry Type" in
                    [ItemJnlLine2."Entry Type"::Sale,
                    ItemJnlLine2."Entry Type"::"Negative Adjmt.",
                    ItemJnlLine2."Entry Type"::Consumption,
                    ItemJnlLine2."Entry Type"::"Assembly Consumption"]) or
                ((ItemJnlLine2."Entry Type" = ItemJnlLine2."Entry Type"::Transfer) and
                    not PostponeReservationHandling)
                then
                    SignFactor := -1
                else
                    SignFactor := 1;

                TempTrackingSpecification.SetTrackingFilterFromItemJnlLine(ItemJnlLine2);
                if TempTrackingSpecification.FindFirst() then begin
                    FreeEntryNo := TempTrackingSpecification."Entry No.";
                    TempTrackingSpecification.Delete();
                    ItemJnlLine2.CheckTrackingEqualTrackingSpecification(TempTrackingSpecification);
                    TempTrackingSpecification."Quantity (Base)" := SignFactor * ItemJnlLine2."Quantity (Base)";
                    TempTrackingSpecification."Quantity Handled (Base)" := SignFactor * ItemJnlLine2."Quantity (Base)";
                    TempTrackingSpecification."Quantity actual Handled (Base)" := SignFactor * ItemJnlLine2."Quantity (Base)";
                    TempTrackingSpecification."Quantity Invoiced (Base)" := SignFactor * ItemJnlLine2."Invoiced Qty. (Base)";
                    TempTrackingSpecification."Qty. to Invoice (Base)" :=
                    SignFactor * (ItemJnlLine2."Quantity (Base)" - ItemJnlLine2."Invoiced Qty. (Base)");
                    TempTrackingSpecification."Qty. to Handle (Base)" := 0;
                    TempTrackingSpecification."Qty. to Handle" := 0;
                    TempTrackingSpecification."Qty. to Invoice" :=
                    SignFactor * (ItemJnlLine2.Quantity - ItemJnlLine2."Invoiced Quantity");
                    TempTrackingSpecification."Item Ledger Entry No." := GlobalItemLedgEntry."Entry No.";
                    TempTrackingSpecification."Transfer Item Entry No." := TempItemEntryRelation."Item Entry No.";
                    OnSplitItemJnlLineOnBeforePostItemJnlLine(TempTrackingSpecification, GlobalItemLedgEntry);
                    if PostItemJnlLine then
                        TempTrackingSpecification."Entry No." := TempTrackingSpecification."Item Ledger Entry No.";
                    OnSplitItemJnlLineOnBeforeInsertTempTrkgSpecification(TempTrackingSpecification, ItemJnlLine2, SignFactor);
                    InsertTempTrkgSpecification(FreeEntryNo);
                end else
                    if (ItemJnlLine2."Item Charge No." = '') and (ItemJnlLine2."Job No." = '') then
                        if not ItemJnlLine2.Correction then begin // Undo quantity posting
                            IsHandled := false;
                            OnBeforeTrackingSpecificationMissingErr(ItemJnlLine2, IsHandled);
                            if not IsHandled then
                                Error(TrackingSpecificationMissingErr);
                        end;
            end;

        if TempSplitItemJnlLine.FindFirst() then begin
            JnlLineNo := ItemJnlLine2."Line No.";
            ItemJnlLine2 := TempSplitItemJnlLine;
            ItemJnlLine2."Line No." := JnlLineNo;
            TempSplitItemJnlLine.Delete();
            exit(true);
        end;
        if ItemJnlLine."Phys. Inventory" then
            InsertPhysInventoryEntry(ItemJnlLineOrigin);
        exit(false);
    end;

    procedure CollectTrackingSpecification(var TargetTrackingSpecification: Record "Tracking Specification" temporary) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        OnBeforeCollectTrackingSpecification(TempTrackingSpecification, TargetTrackingSpecification, Result, IsHandled);
        if IsHandled then
            exit(Result);

        TempTrackingSpecification.Reset();
        TargetTrackingSpecification.Reset();
        TargetTrackingSpecification.DeleteAll();

        if TempTrackingSpecification.FindSet() then
            repeat
                TargetTrackingSpecification := TempTrackingSpecification;
                TargetTrackingSpecification.Insert();
            until TempTrackingSpecification.Next() = 0
        else
            exit(false);

        TempTrackingSpecification.DeleteAll();

        exit(true);
    end;

    procedure CollectValueEntryRelation(var TargetValueEntryRelation: Record "Value Entry Relation" temporary; RowId: Text[250]): Boolean
    begin
        TempValueEntryRelation.Reset();
        TargetValueEntryRelation.Reset();

        if TempValueEntryRelation.FindSet() then
            repeat
                TargetValueEntryRelation := TempValueEntryRelation;
                TargetValueEntryRelation."Source RowId" := RowId;
                TargetValueEntryRelation.Insert();
            until TempValueEntryRelation.Next() = 0
        else
            exit(false);

        TempValueEntryRelation.DeleteAll();

        exit(true);
    end;

    procedure CollectItemEntryRelation(var TargetItemEntryRelation: Record "Item Entry Relation" temporary): Boolean
    begin
        TempItemEntryRelation.Reset();
        TargetItemEntryRelation.Reset();

        if TempItemEntryRelation.FindSet() then
            repeat
                TargetItemEntryRelation := TempItemEntryRelation;
                TargetItemEntryRelation.Insert();
            until TempItemEntryRelation.Next() = 0
        else
            exit(false);

        TempItemEntryRelation.DeleteAll();

        exit(true);
    end;

    local procedure CheckExpirationDate(var ItemJnlLine2: Record "Item Journal Line"; SignFactor: Integer; CalcExpirationDate: Date; var ExpirationDateChecked: Boolean)
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
        ExistingExpirationDate: Date;
        EntriesExist: Boolean;
        SumOfEntries: Decimal;
        SumLot: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckExpirationDate(
          ItemJnlLine2, TempTrackingSpecification, SignFactor, CalcExpirationDate, ExpirationDateChecked, IsHandled);
        if IsHandled then
            exit;

        ExistingExpirationDate :=
          ItemTrackingMgt.ExistingExpirationDate(TempTrackingSpecification, true, EntriesExist);

        if not (EntriesExist or ExpirationDateChecked) then begin
            ItemTrackingMgt.TestExpDateOnTrackingSpec(TempTrackingSpecification);
            ExpirationDateChecked := true;
        end;
        IsHandled := false;
        OnCheckExpirationDateOnBeforeAssignExpirationDate(TempTrackingSpecification, ExistingExpirationDate, IsHandled);
        if not IsHandled then
            if ItemJnlLine2."Entry Type" = ItemJnlLine2."Entry Type"::Transfer then
                if TempTrackingSpecification."Expiration Date" = 0D then
                    TempTrackingSpecification."Expiration Date" := ExistingExpirationDate;

        // Supply
        if SignFactor * ItemJnlLine2.Quantity > 0 then begin        // Only expiration dates on supply.
            if not (ItemJnlLine2."Entry Type" = ItemJnlLine2."Entry Type"::Transfer) then
                if GlobalItemTrackingCode."Man. Expir. Date Entry Reqd." then begin
                    if ItemJnlLine2."Phys. Inventory" and (ExistingExpirationDate <> 0D) then
                        TempTrackingSpecification."Expiration Date" := ExistingExpirationDate;
                    if not TempTrackingSpecification.Correction then
                        if TempTrackingSpecification."Appl.-from Item Entry" = 0 then
                            TempTrackingSpecification.TestField("Expiration Date");
                end;

            if CalcExpirationDate <> 0D then
                if ExistingExpirationDate <> 0D then
                    CalcExpirationDate := ExistingExpirationDate;

            if ItemJnlLine2."Entry Type" = ItemJnlLine2."Entry Type"::Transfer then
                if TempTrackingSpecification."New Expiration Date" = 0D then
                    TempTrackingSpecification."New Expiration Date" := ExistingExpirationDate;

            if TempTrackingSpecification."Expiration Date" = 0D then
                TempTrackingSpecification."Expiration Date" := CalcExpirationDate;

            OnCheckExpirationDateOnBeforeTestFieldExpirationDate(TempTrackingSpecification, EntriesExist, ExistingExpirationDate);
            if EntriesExist then
                TempTrackingSpecification.TestField("Expiration Date", ExistingExpirationDate);
        end else   // Demand
            if ItemJnlLine2."Entry Type" = ItemJnlLine2."Entry Type"::Transfer then begin
                ItemTrackingSetup.CopyTrackingFromNewTrackingSpec(TempTrackingSpecification);
                ExistingExpirationDate :=
                  ItemTrackingMgt.ExistingExpirationDateAndQty(
                    TempTrackingSpecification."Item No.", TempTrackingSpecification."Variant Code",
                    ItemTrackingSetup, SumOfEntries);

                if (ItemJnlLine2."Order Type" = ItemJnlLine2."Order Type"::Transfer) and
                   (ItemJnlLine2."Order No." <> '')
                then
                    if TempTrackingSpecification."New Expiration Date" = 0D then
                        TempTrackingSpecification."New Expiration Date" := ExistingExpirationDate;

                if (TempTrackingSpecification."New Lot No." <> '') and
                   ((ItemJnlLine2."Order Type" <> ItemJnlLine2."Order Type"::Transfer) or
                    (ItemJnlLine2."Order No." = ''))
                then begin
                    if TempTrackingSpecification."New Serial No." <> '' then
                        SumLot := SignFactor * ItemTrackingMgt.SumNewLotOnTrackingSpec(TempTrackingSpecification)
                    else
                        SumLot := SignFactor * TempTrackingSpecification."Quantity (Base)";
                    OnCheckExpirationDateOnAfterCalcSumLot(SumLot, SignFactor, TempTrackingSpecification);
                    if (SumOfEntries > 0) and
                       ((SumOfEntries <> SumLot) or (TempTrackingSpecification."New Lot No." <> TempTrackingSpecification."Lot No."))
                    then
                        TempTrackingSpecification.TestField("New Expiration Date", ExistingExpirationDate);
                    ItemTrackingMgt.TestExpDateOnTrackingSpecNew(TempTrackingSpecification);
                end;
            end;

        if (ItemJnlLine2."Entry Type" = ItemJnlLine2."Entry Type"::Transfer) and
           ((ItemJnlLine2."Order Type" <> ItemJnlLine2."Order Type"::Transfer) or
            (ItemJnlLine2."Order No." = ''))
        then
            if GlobalItemTrackingCode."Man. Expir. Date Entry Reqd." then
                TempTrackingSpecification.TestField("New Expiration Date");
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            if GLSetup."Additional Reporting Currency" <> '' then begin
                Currency.Get(GLSetup."Additional Reporting Currency");
                Currency.TestField("Unit-Amount Rounding Precision");
                Currency.TestField("Amount Rounding Precision");
            end;
        end;
        GLSetupRead := true;

        OnAfterGetGLSetup(GLSetup);
    end;

    local procedure GetGeneralPostingSetup(ItemJournalLine: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetGeneralPostingSetup(ItemJournalLine, GenPostingSetup, PostToGL, IsHandled);
        if IsHandled then
            exit;

        if (ItemJournalLine."Gen. Bus. Posting Group" <> GenPostingSetup."Gen. Bus. Posting Group") or
            (ItemJournalLine."Gen. Prod. Posting Group" <> GenPostingSetup."Gen. Prod. Posting Group")
        then begin
            GenPostingSetup.Get(ItemJournalLine."Gen. Bus. Posting Group", ItemJournalLine."Gen. Prod. Posting Group");
            GenPostingSetup.TestField(Blocked, false);
        end;
    end;

    local procedure GetMfgSetup()
    begin
        if not MfgSetupRead then
            MfgSetup.Get();
        MfgSetupRead := true;
    end;

    local procedure GetInvtSetup()
    begin
        if not InvtSetupRead then begin
            InvtSetup.Get();
            SourceCodeSetup.Get();
        end;
        InvtSetupRead := true;
    end;

    local procedure UndoQuantityPosting()
    var
        OldItemLedgEntry: Record "Item Ledger Entry";
        OldItemLedgEntry2: Record "Item Ledger Entry";
        NewItemLedgEntry: Record "Item Ledger Entry";
        OldValueEntry: Record "Value Entry";
        NewValueEntry: Record "Value Entry";
        IsReserved: Boolean;
        IsHandled: Boolean;
        ShouldInsertCorrValueEntries: Boolean;
    begin
        IsHandled := false;
        OnBeforeUndoQuantityPosting(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        if ItemJnlLine."Entry Type" in [ItemJnlLine."Entry Type"::"Assembly Consumption",
                                        ItemJnlLine."Entry Type"::"Assembly Output"]
        then
            exit;

        if ItemJnlLine."Applies-to Entry" <> 0 then begin
            OldItemLedgEntry.Get(ItemJnlLine."Applies-to Entry");
            if not OldItemLedgEntry.Positive then
                ItemJnlLine."Applies-from Entry" := ItemJnlLine."Applies-to Entry";
        end else
            OldItemLedgEntry.Get(ItemJnlLine."Applies-from Entry");

        if GetItem(OldItemLedgEntry."Item No.", false) then begin
            Item.TestField(Blocked, false);
            Item.CheckBlockedByApplWorksheet();
        end;

        ItemJnlLine."Item No." := OldItemLedgEntry."Item No.";

        OnUndoQuantityPostingOnBeforeInitCorrItemLedgEntry(ItemJnlLine, OldItemLedgEntry);
        InitCorrItemLedgEntry(OldItemLedgEntry, NewItemLedgEntry);
        OnUndoQuantityPostingOnAfterInitCorrItemLedgEntry(OldItemLedgEntry, NewItemLedgEntry);

        if Item.IsNonInventoriableType() then begin
            NewItemLedgEntry."Remaining Quantity" := 0;
            NewItemLedgEntry.Open := false;
        end;

        InsertItemReg(NewItemLedgEntry."Entry No.", 0, 0, 0);
        GlobalItemLedgEntry := NewItemLedgEntry;

        CalcILEExpectedAmount(OldValueEntry, OldItemLedgEntry."Entry No.");
        if OldValueEntry.Inventoriable then
            AvgCostEntryPointHandler.UpdateValuationDate(OldValueEntry);

        ShouldInsertCorrValueEntries := OldItemLedgEntry."Invoiced Quantity" = 0;
        OnUndoQuantityPostingOnAfterCalcShouldInsertCorrValueEntry(OldItemLedgEntry, ShouldInsertCorrValueEntries);
        if ShouldInsertCorrValueEntries then begin
            IsHandled := false;
            OnUndoQuantityPostingOnBeforeInsertCorrOldItemLedgEntry(OldItemLedgEntry, IsHandled);
            if not IsHandled then
                InsertCorrValueEntry(
                OldValueEntry, NewValueEntry, OldItemLedgEntry, OldValueEntry."Document Line No.", 1,
                0, OldItemLedgEntry.Quantity);
            InsertCorrValueEntry(
              OldValueEntry, NewValueEntry, NewItemLedgEntry, ItemJnlLine."Document Line No.", -1,
              NewItemLedgEntry.Quantity, 0);
            InsertCorrValueEntry(
              OldValueEntry, NewValueEntry, NewItemLedgEntry, ItemJnlLine."Document Line No.", -1,
              0, NewItemLedgEntry.Quantity);
        end else
            InsertCorrValueEntry(
              OldValueEntry, NewValueEntry, NewItemLedgEntry, ItemJnlLine."Document Line No.", -1,
              NewItemLedgEntry.Quantity, NewItemLedgEntry.Quantity);

        OnUndoQuantityPostingOnBeforeUpdateOldItemLedgEntry(OldValueEntry, NewItemLedgEntry, NewValueEntry, ItemJnlLine);
        UpdateOldItemLedgEntry(OldItemLedgEntry, NewItemLedgEntry."Posting Date");
        UpdateItemApplnEntry(OldItemLedgEntry."Entry No.", NewItemLedgEntry."Posting Date");
        OnUndoQuantityPostingOnAfterUpdateItemApplnEntry(ItemJnlLine, OldItemLedgEntry, NewItemLedgEntry, NewValueEntry, InventoryPostingToGL);

        if GlobalItemLedgEntry.Quantity > 0 then
            IsReserved :=
              ItemJnlLineReserve.TransferItemJnlToItemLedgEntry(
                ItemJnlLine, GlobalItemLedgEntry, ItemJnlLine."Quantity (Base)", true);

        if not ItemJnlLine.IsATOCorrection() then begin
            ApplyItemLedgEntry(NewItemLedgEntry, OldItemLedgEntry2, NewValueEntry, false);
            AutoTrack(NewItemLedgEntry, IsReserved);
        end;

        NewItemLedgEntry.Modify();
        UpdateAdjmtProperties(NewValueEntry, NewItemLedgEntry."Posting Date");

        OnUndoQuantityPostingOnBeforeInsertApplEntry(NewItemLedgEntry, OldItemLedgEntry, GlobalItemLedgEntry);
        if NewItemLedgEntry.Positive then begin
            UpdateOrigAppliedFromEntry(OldItemLedgEntry."Entry No.");
            InsertApplEntry(
              NewItemLedgEntry."Entry No.", NewItemLedgEntry."Entry No.",
              OldItemLedgEntry."Entry No.", 0, NewItemLedgEntry."Posting Date",
              -OldItemLedgEntry.Quantity, false);
        end;
        OnAfterUndoQuantityPosting(NewItemLedgEntry, ItemJnlLine);
    end;

    procedure UndoValuePostingWithJob(OldItemLedgEntryNo: Integer; NewItemLedgEntryNo: Integer)
    var
        OldItemLedgEntry: Record "Item Ledger Entry";
        NewItemLedgEntry: Record "Item Ledger Entry";
        OldValueEntry: Record "Value Entry";
        NewValueEntry: Record "Value Entry";
    begin
        OldItemLedgEntry.Get(OldItemLedgEntryNo);
        NewItemLedgEntry.Get(NewItemLedgEntryNo);
        InitValueEntryNo();

        if OldItemLedgEntry."Invoiced Quantity" = 0 then begin
            CalcILEExpectedAmount(OldValueEntry, OldItemLedgEntry."Entry No.");
            InsertCorrValueEntry(
              OldValueEntry, NewValueEntry, OldItemLedgEntry, OldValueEntry."Document Line No.", 1,
              0, OldItemLedgEntry.Quantity);

            CalcILEExpectedAmount(OldValueEntry, NewItemLedgEntry."Entry No.");
            InsertCorrValueEntry(
              OldValueEntry, NewValueEntry, NewItemLedgEntry, NewItemLedgEntry."Document Line No.", 1,
              0, NewItemLedgEntry.Quantity);
        end else
            InsertCorrValueEntry(
              OldValueEntry, NewValueEntry, NewItemLedgEntry, NewItemLedgEntry."Document Line No.", -1,
              NewItemLedgEntry.Quantity, NewItemLedgEntry.Quantity);

        UpdateOldItemLedgEntry(OldItemLedgEntry, NewItemLedgEntry."Posting Date");
        UpdateOldItemLedgEntry(NewItemLedgEntry, NewItemLedgEntry."Posting Date");
        UpdateItemApplnEntry(OldItemLedgEntry."Entry No.", NewItemLedgEntry."Posting Date");

        NewItemLedgEntry.Modify();
        UpdateAdjmtProperties(NewValueEntry, NewItemLedgEntry."Posting Date");

        if NewItemLedgEntry.Positive then
            UpdateOrigAppliedFromEntry(OldItemLedgEntry."Entry No.");
    end;

    local procedure InitCorrItemLedgEntry(var OldItemLedgEntry: Record "Item Ledger Entry"; var NewItemLedgEntry: Record "Item Ledger Entry")
    var
        EntriesExist: Boolean;
    begin
        if ItemLedgEntryNo = 0 then
            ItemLedgEntryNo := GlobalItemLedgEntry."Entry No.";

        ItemLedgEntryNo := ItemLedgEntryNo + 1;
        NewItemLedgEntry := OldItemLedgEntry;
        ItemTrackingMgt.RetrieveAppliedExpirationDate(NewItemLedgEntry);
        OnInitCorrItemLedgEntryOnAfterRetrieveAppliedExpirationDate(NewItemLedgEntry);

        NewItemLedgEntry."Entry No." := ItemLedgEntryNo;
        NewItemLedgEntry.Quantity := -OldItemLedgEntry.Quantity;
        NewItemLedgEntry."Remaining Quantity" := -OldItemLedgEntry.Quantity;
        if NewItemLedgEntry.Quantity > 0 then
            NewItemLedgEntry."Shipped Qty. Not Returned" := 0
        else
            NewItemLedgEntry."Shipped Qty. Not Returned" := NewItemLedgEntry.Quantity;
        NewItemLedgEntry."Invoiced Quantity" := NewItemLedgEntry.Quantity;
        NewItemLedgEntry.Positive := NewItemLedgEntry."Remaining Quantity" > 0;
        NewItemLedgEntry.Open := NewItemLedgEntry."Remaining Quantity" <> 0;
        NewItemLedgEntry."Completely Invoiced" := true;
        NewItemLedgEntry."Last Invoice Date" := NewItemLedgEntry."Posting Date";
        NewItemLedgEntry.Correction := true;
        NewItemLedgEntry."Document Line No." := ItemJnlLine."Document Line No.";
        if OldItemLedgEntry.Positive then
            NewItemLedgEntry."Applies-to Entry" := OldItemLedgEntry."Entry No."
        else
            NewItemLedgEntry."Applies-to Entry" := 0;

        OnBeforeInsertCorrItemLedgEntry(NewItemLedgEntry, OldItemLedgEntry, ItemJnlLine);
        NewItemLedgEntry.Insert();
        OnAfterInsertCorrItemLedgEntry(NewItemLedgEntry, ItemJnlLine, OldItemLedgEntry);

        if NewItemLedgEntry."Item Tracking" <> NewItemLedgEntry."Item Tracking"::None then
            ItemTrackingMgt.ExistingExpirationDate(NewItemLedgEntry, true, EntriesExist);

        OnAfterInitCorrItemLedgEntry(NewItemLedgEntry, EntriesExist);
    end;

    local procedure UpdateOldItemLedgEntry(var OldItemLedgEntry: Record "Item Ledger Entry"; LastInvoiceDate: Date)
    begin
        OldItemLedgEntry."Completely Invoiced" := true;
        OldItemLedgEntry."Last Invoice Date" := LastInvoiceDate;
        OldItemLedgEntry."Invoiced Quantity" := OldItemLedgEntry.Quantity;
        OldItemLedgEntry."Shipped Qty. Not Returned" := 0;
        OnBeforeOldItemLedgEntryModify(OldItemLedgEntry);
        OldItemLedgEntry.Modify();
    end;

    local procedure InsertCorrValueEntry(OldValueEntry: Record "Value Entry"; var NewValueEntry: Record "Value Entry"; ItemLedgEntry: Record "Item Ledger Entry"; DocumentLineNo: Integer; Sign: Integer; QtyToShip: Decimal; QtyToInvoice: Decimal)
    begin
        ValueEntryNo := ValueEntryNo + 1;

        NewValueEntry := OldValueEntry;
        NewValueEntry."Entry No." := ValueEntryNo;
        NewValueEntry."Item Ledger Entry No." := ItemLedgEntry."Entry No.";
        NewValueEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(NewValueEntry."User ID"));
        NewValueEntry."Valued Quantity" := Sign * OldValueEntry."Valued Quantity";
        NewValueEntry."Document Line No." := DocumentLineNo;
        NewValueEntry."Item Ledger Entry Quantity" := QtyToShip;
        NewValueEntry."Invoiced Quantity" := QtyToInvoice;
        NewValueEntry."Expected Cost" := QtyToInvoice = 0;
        if not NewValueEntry."Expected Cost" then begin
            NewValueEntry."Cost Amount (Expected)" := -Sign * OldValueEntry."Cost Amount (Expected)";
            NewValueEntry."Cost Amount (Expected) (ACY)" := -Sign * OldValueEntry."Cost Amount (Expected) (ACY)";
            if QtyToShip = 0 then begin
                NewValueEntry."Cost Amount (Actual)" := Sign * OldValueEntry."Cost Amount (Expected)";
                NewValueEntry."Cost Amount (Actual) (ACY)" := Sign * OldValueEntry."Cost Amount (Expected) (ACY)";
            end else begin
                NewValueEntry."Cost Amount (Actual)" := -NewValueEntry."Cost Amount (Actual)";
                NewValueEntry."Cost Amount (Actual) (ACY)" := -NewValueEntry."Cost Amount (Actual) (ACY)";
            end;
            NewValueEntry."Purchase Amount (Expected)" := -Sign * OldValueEntry."Purchase Amount (Expected)";
            NewValueEntry."Sales Amount (Expected)" := -Sign * OldValueEntry."Sales Amount (Expected)";
        end else begin
            NewValueEntry."Cost Amount (Expected)" := -OldValueEntry."Cost Amount (Expected)";
            NewValueEntry."Cost Amount (Expected) (ACY)" := -OldValueEntry."Cost Amount (Expected) (ACY)";
            NewValueEntry."Cost Amount (Actual)" := 0;
            NewValueEntry."Cost Amount (Actual) (ACY)" := 0;
            NewValueEntry."Sales Amount (Expected)" := -OldValueEntry."Sales Amount (Expected)";
            NewValueEntry."Purchase Amount (Expected)" := -OldValueEntry."Purchase Amount (Expected)";
        end;

        NewValueEntry."Purchase Amount (Actual)" := 0;
        NewValueEntry."Sales Amount (Actual)" := 0;
        NewValueEntry."Cost Amount (Non-Invtbl.)" := Sign * OldValueEntry."Cost Amount (Non-Invtbl.)";
        NewValueEntry."Cost Amount (Non-Invtbl.)(ACY)" := Sign * OldValueEntry."Cost Amount (Non-Invtbl.)(ACY)";
        NewValueEntry."Cost Posted to G/L" := 0;
        NewValueEntry."Cost Posted to G/L (ACY)" := 0;
        NewValueEntry."Expected Cost Posted to G/L" := 0;
        NewValueEntry."Exp. Cost Posted to G/L (ACY)" := 0;

        OnBeforeInsertCorrValueEntry(
          NewValueEntry, OldValueEntry, ItemJnlLine, Sign, CalledFromAdjustment, ItemLedgEntry, ValueEntryNo, InventoryPostingToGL);

        PostInventoryToGL(NewValueEntry);

        NewValueEntry.Insert();

        OnAfterInsertCorrValueEntry(NewValueEntry, ItemJnlLine, ItemLedgEntry, ValueEntryNo);

        ItemApplnEntry.SetOutboundsNotUpdated(ItemLedgEntry);

        UpdateAdjmtProperties(NewValueEntry, ItemLedgEntry."Posting Date");

        InsertItemReg(0, 0, NewValueEntry."Entry No.", 0);
        InsertPostValueEntryToGL(NewValueEntry);
    end;

    local procedure UpdateOrigAppliedFromEntry(OldItemLedgEntryNo: Integer)
    var
        ItemApplEntry: Record "Item Application Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemApplEntry.SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.");
        ItemApplEntry.SetRange("Outbound Item Entry No.", OldItemLedgEntryNo);
        ItemApplEntry.SetFilter("Item Ledger Entry No.", '<>%1', OldItemLedgEntryNo);
        if ItemApplEntry.FindSet() then
            repeat
                if ItemLedgEntry.Get(ItemApplEntry."Inbound Item Entry No.") and
                   not ItemLedgEntry."Applied Entry to Adjust"
                then begin
                    ItemLedgEntry."Applied Entry to Adjust" := true;
                    ItemLedgEntry.Modify();
                end;
                OnUpdateOrigAppliedFromEntryOnItemApplEntryLoop(ItemLedgEntry, ItemApplEntry);
            until ItemApplEntry.Next() = 0;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure GetItem(ItemNo: Code[20]; Unconditionally: Boolean): Boolean
    var
        HasGotItem: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetItem(Item, ItemNo, Unconditionally, HasGotItem, IsHandled);
        if IsHandled then
            exit(HasGotItem);

        if not Unconditionally then
            exit(Item.Get(ItemNo))
        else
            Item.Get(ItemNo);
        exit(true);
    end;

    local procedure CheckItem(ItemNo: Code[20])
    begin
        if GetItem(ItemNo, false) then begin
            if not CalledFromAdjustment then
                Item.TestField(Blocked, false);
            OnCheckItemOnAfterGetItem(Item, ItemJnlLine, CalledFromAdjustment);
        end else
            Item.Init();
    end;

    procedure CheckItemTracking()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemTracking(ItemJnlLine, GlobalItemTrackingSetup, IsHandled, TempTrackingSpecification);
        if IsHandled then
            exit;

        if GlobalItemTrackingSetup."Serial No. Required" and (ItemJnlLine."Serial No." = '') then
            Error(GetTextStringWithLineNo(SerialNoRequiredErr, ItemJnlLine."Item No.", ItemJnlLine."Line No."));
        if GlobalItemTrackingSetup."Lot No. Required" and (ItemJnlLine."Lot No." = '') then
            Error(GetTextStringWithLineNo(LotNoRequiredErr, ItemJnlLine."Item No.", ItemJnlLine."Line No."));

        OnCheckItemTrackingOnAfterCheckRequiredTrackingNos(ItemJnlLine, GlobalItemTrackingSetup);

        if ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Transfer then
            ItemJnlLine.CheckNewTrackingIfRequired(GlobalItemTrackingSetup);

        OnAfterCheckItemTracking(ItemJnlLine, GlobalItemTrackingSetup, GlobalItemTrackingCode);
    end;

    local procedure CheckItemTrackingInformation(var ItemJnlLine2: Record "Item Journal Line"; var TrackingSpecification: Record "Tracking Specification"; SignFactor: Decimal; ItemTrackingCode: Record "Item Tracking Code"; ItemTrackingSetup: Record "Item Tracking Setup")
    var
        SerialNoInfo: Record "Serial No. Information";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemTrackingInformation(ItemJnlLine2, TrackingSpecification, ItemTrackingSetup, SignFactor, ItemTrackingCode, IsHandled, GlobalItemTrackingCode);
        if IsHandled then
            exit;

        if ItemTrackingCode."Create SN Info on Posting" then
            ItemTrackingMgt.CreateSerialNoInformation(TrackingSpecification);

        IsHandled := false;
        OnCheckItemTrackingInformationOnBeforeTestFields(ItemTrackingSetup, TrackingSpecification, ItemJnlLine2, IsHandled);
        if not IsHandled then
            if ItemTrackingSetup."Serial No. Info Required" then begin
                SerialNoInfo.Get(ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code", TrackingSpecification."Serial No.");
                SerialNoInfo.TestField(Blocked, false);
                if TrackingSpecification."New Serial No." <> '' then begin
                    SerialNoInfo.Get(ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code", TrackingSpecification."New Serial No.");
                    SerialNoInfo.TestField(Blocked, false);
                end;
            end else begin
                if SerialNoInfo.Get(ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code", TrackingSpecification."Serial No.") then
                    SerialNoInfo.TestField(Blocked, false);
                if TrackingSpecification."New Serial No." <> '' then
                    if SerialNoInfo.Get(ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code", TrackingSpecification."New Serial No.") then
                        SerialNoInfo.TestField(Blocked, false);
            end;

        if ItemTrackingCode."Create Lot No. Info on posting" then
            ItemTrackingMgt.CreateLotNoInformation(TrackingSpecification);

        CheckLotNoInfoNotBlocked(ItemTrackingSetup, ItemJnlLine2, TrackingSpecification);

        OnAfterCheckItemTrackingInformation(ItemJnlLine2, TrackingSpecification, ItemTrackingSetup, Item);
    end;

    local procedure CheckLotNoInfoNotBlocked(ItemTrackingSetup: Record "Item Tracking Setup"; var ItemJnlLine2: Record "Item Journal Line"; var TrackingSpecification: Record "Tracking Specification")
    var
        LotNoInfo: Record "Lot No. Information";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckLotNoInfoNotBlocked(ItemJnlLine2, IsHandled, ItemTrackingSetup, TrackingSpecification);
        if IsHandled then
            exit;

        if ItemTrackingSetup."Lot No. Info Required" then begin
            LotNoInfo.Get(ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code", TrackingSpecification."Lot No.");
            LotNoInfo.TestField(Blocked, false);
            if TrackingSpecification."New Lot No." <> '' then begin
                LotNoInfo.Get(ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code", TrackingSpecification."New Lot No.");
                LotNoInfo.TestField(Blocked, false);
            end;
        end else begin
            if LotNoInfo.Get(ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code", TrackingSpecification."Lot No.") then
                LotNoInfo.TestField(Blocked, false);
            if TrackingSpecification."New Lot No." <> '' then
                if LotNoInfo.Get(ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code", TrackingSpecification."New Lot No.") then
                    LotNoInfo.TestField(Blocked, false);
        end;
    end;

    local procedure CheckItemTrackingIsEmpty(ItemJnlLine: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemTrackingIsEmpty(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        ItemJnlLine.CheckTrackingIsEmpty();
        ItemJnlLine.CheckNewTrackingIsEmpty();
    end;

    local procedure CheckItemSerialNo(ItemJnlLine: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSerialNo(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        if SkipSerialNoQtyValidation then
            exit;

        with ItemJnlLine do
            if "Entry Type" = "Entry Type"::Transfer then begin
                if ItemTrackingMgt.FindInInventory("Item No.", "Variant Code", "New Serial No.") then
                    Error(Text014, "New Serial No.")
            end else
                if ItemTrackingMgt.FindInInventory("Item No.", "Variant Code", "Serial No.") then
                    Error(Text014, "Serial No.");
    end;

    local procedure CheckItemCorrection(ItemLedgerEntry: Record "Item Ledger Entry")
    var
        RaiseError: Boolean;
    begin
        RaiseError := ItemLedgerEntry.Correction;
        OnBeforeCheckItemCorrection(ItemLedgerEntry, RaiseError);
        if RaiseError then
            Error(CannotUnapplyCorrEntryErr);
    end;

    local procedure InsertTempTrkgSpecification(FreeEntryNo: Integer)
    var
        TempTrackingSpecification2: Record "Tracking Specification" temporary;
    begin
        if not TempTrackingSpecification.Insert() then begin
            TempTrackingSpecification2 := TempTrackingSpecification;
            TempTrackingSpecification.Get(TempTrackingSpecification2."Item Ledger Entry No.");
            TempTrackingSpecification.Delete();
            TempTrackingSpecification."Entry No." := FreeEntryNo;
            TempTrackingSpecification.Insert();
            TempTrackingSpecification := TempTrackingSpecification2;
            TempTrackingSpecification.Insert();
        end;
    end;

    local procedure IsNotInternalWhseMovement(ItemJnlLine: Record "Item Journal Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsNotInternalWhseMovement(ItemJnlLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(ItemJnlLine.IsNotInternalWhseMovement());
    end;

    procedure SetCalledFromInvtPutawayPick(NewCalledFromInvtPutawayPick: Boolean)
    begin
        CalledFromInvtPutawayPick := NewCalledFromInvtPutawayPick;
    end;

    procedure SetCalledFromAdjustment(NewCalledFromAdjustment: Boolean; NewPostToGL: Boolean)
    begin
        OnBeforeSetCalledFromAdjustment(CalledFromAdjustment);

        CalledFromAdjustment := NewCalledFromAdjustment;
        PostToGL := NewPostToGL;
    end;

    procedure NextOperationExist(var ProdOrderRtngLine: Record "Prod. Order Routing Line"): Boolean
    begin
        OnBeforeNextOperationExist(ProdOrderRtngLine);
        exit(ProdOrderRtngLine."Next Operation No." <> '');
    end;

    local procedure UpdateAdjmtProperties(ValueEntry: Record "Value Entry"; OriginalPostingDate: Date)
    begin
        with ValueEntry do
            SetAdjmtProperties(
              "Item No.", "Item Ledger Entry Type", Adjustment,
              "Order Type", "Order No.", "Order Line No.", OriginalPostingDate, "Valuation Date");

        OnAfterUpdateAdjmtProp(ValueEntry, OriginalPostingDate);
    end;

    local procedure SetAdjmtProperties(ItemNo: Code[20]; ItemLedgEntryType: Enum "Item Ledger Entry Type"; Adjustment: Boolean; OrderType: Enum "Inventory Order Type"; OrderNo: Code[20]; OrderLineNo: Integer; OriginalPostingDate: Date; ValuationDate: Date)
    begin
        SetItemAdjmtProperties(ItemNo, ItemLedgEntryType, Adjustment, OriginalPostingDate, ValuationDate);
        SetOrderAdjmtProperties(ItemLedgEntryType, OrderType, OrderNo, OrderLineNo, OriginalPostingDate, ValuationDate);
    end;

    local procedure SetItemAdjmtProperties(ItemNo: Code[20]; ItemLedgEntryType: Enum "Item Ledger Entry Type"; Adjustment: Boolean; OriginalPostingDate: Date; ValuationDate: Date)
    var
        Item2: Record Item;
        ValueEntry: Record "Value Entry";
        ModifyItem: Boolean;
    begin
        if ItemLedgEntryType = ValueEntry."Item Ledger Entry Type"::" " then
            exit;
        if Adjustment then
            if not (ItemLedgEntryType in [ValueEntry."Item Ledger Entry Type"::Output,
                                          ValueEntry."Item Ledger Entry Type"::"Assembly Output"])
            then
                exit;

        with Item2 do
            if Get(ItemNo) and ("Allow Online Adjustment" or "Cost is Adjusted") and (Type = Type::Inventory) then begin
                LockTable();
                if "Cost is Adjusted" then begin
                    "Cost is Adjusted" := false;
                    ModifyItem := true;
                end;
                if "Allow Online Adjustment" then begin
                    if "Costing Method" = "Costing Method"::Average then
                        "Allow Online Adjustment" := AllowAdjmtOnPosting(ValuationDate)
                    else
                        "Allow Online Adjustment" := AllowAdjmtOnPosting(OriginalPostingDate);
                    ModifyItem := ModifyItem or not "Allow Online Adjustment";
                end;
                OnSetItemAdjmtPropertiesOnBeforeCheckModifyItem(Item2, ModifyItem);
                if ModifyItem then
                    Modify();
            end;
    end;

    local procedure SetOrderAdjmtProperties(ItemLedgEntryType: Enum "Item Ledger Entry Type"; OrderType: Enum "Inventory Order Type"; OrderNo: Code[20]; OrderLineNo: Integer; OriginalPostingDate: Date; ValuationDate: Date)
    var
        ValueEntry: Record "Value Entry";
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        ProdOrderLine: Record "Prod. Order Line";
        AssemblyHeader: Record "Assembly Header";
        ModifyOrderAdjmt: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetOrderAdjmtProperties(
            ItemLedgEntryType.AsInteger(), OrderType.AsInteger(), OrderNo, OrderLineNo, OriginalPostingDate, ValuationDate, IsHandled, ItemJnlLine);
        if IsHandled then
            exit;

        if not (OrderType in [ValueEntry."Order Type"::Production,
                              ValueEntry."Order Type"::Assembly])
        then
            exit;

        if ItemLedgEntryType in [ValueEntry."Item Ledger Entry Type"::Output,
                                 ValueEntry."Item Ledger Entry Type"::"Assembly Output"]
        then
            exit;

        if not InventoryAdjmtEntryOrder.Get(OrderType, OrderNo, OrderLineNo) then
            case OrderType of
                InventoryAdjmtEntryOrder."Order Type"::Production:
                    begin
                        GetProdOrderLine(ProdOrderLine, OrderNo, OrderLineNo);
                        InventoryAdjmtEntryOrder.SetProdOrderLine(ProdOrderLine);
                        SetOrderAdjmtProperties(ItemLedgEntryType, OrderType, OrderNo, OrderLineNo, OriginalPostingDate, ValuationDate);
                    end;
                InventoryAdjmtEntryOrder."Order Type"::Assembly:
                    begin
                        if OrderLineNo = 0 then begin
                            AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, OrderNo);
                            InventoryAdjmtEntryOrder.SetAsmOrder(AssemblyHeader);
                        end;
                        SetOrderAdjmtProperties(ItemLedgEntryType, OrderType, OrderNo, 0, OriginalPostingDate, ValuationDate);
                    end;
            end
        else
            if InventoryAdjmtEntryOrder."Allow Online Adjustment" or InventoryAdjmtEntryOrder."Cost is Adjusted" then begin
                InventoryAdjmtEntryOrder.LockTable();
                IsHandled := false;
                OnSetOrderAdjmtPropertiesOnBeforeSetCostIsAdjusted(InventoryAdjmtEntryOrder, ModifyOrderAdjmt, IsHandled, OriginalPostingDate);
                if not IsHandled then
                    if InventoryAdjmtEntryOrder."Cost is Adjusted" then begin
                        InventoryAdjmtEntryOrder."Cost is Adjusted" := false;
                        ModifyOrderAdjmt := true;
                    end;
                IsHandled := false;
                OnSetOrderAdjmtPropertiesOnBeforeSetAllowOnlineAdjustment(InventoryAdjmtEntryOrder, ModifyOrderAdjmt, IsHandled, OriginalPostingDate);
                if not IsHandled then
                    if InventoryAdjmtEntryOrder."Allow Online Adjustment" then begin
                        InventoryAdjmtEntryOrder."Allow Online Adjustment" := AllowAdjmtOnPosting(OriginalPostingDate);
                        ModifyOrderAdjmt := ModifyOrderAdjmt or not InventoryAdjmtEntryOrder."Allow Online Adjustment";
                    end;
                if ModifyOrderAdjmt then
                    InventoryAdjmtEntryOrder.Modify();
            end;
    end;

    procedure AllowAdjmtOnPosting(TheDate: Date): Boolean
    begin
        GetInvtSetup();

        with InvtSetup do
            case "Automatic Cost Adjustment" of
                "Automatic Cost Adjustment"::Never:
                    exit(false);
                "Automatic Cost Adjustment"::Day:
                    exit(TheDate >= CalcDate('<-1D>', WorkDate()));
                "Automatic Cost Adjustment"::Week:
                    exit(TheDate >= CalcDate('<-1W>', WorkDate()));
                "Automatic Cost Adjustment"::Month:
                    exit(TheDate >= CalcDate('<-1M>', WorkDate()));
                "Automatic Cost Adjustment"::Quarter:
                    exit(TheDate >= CalcDate('<-1Q>', WorkDate()));
                "Automatic Cost Adjustment"::Year:
                    exit(TheDate >= CalcDate('<-1Y>', WorkDate()));
                else
                    exit(true);
            end;
    end;

    local procedure InsertBalanceExpCostRevEntry(ValueEntry: Record "Value Entry")
    var
        ValueEntry2: Record "Value Entry";
        ValueEntry3: Record "Value Entry";
        RevExpCostToBalance: Decimal;
        RevExpCostToBalanceACY: Decimal;
    begin
        if GlobalItemLedgEntry.Quantity - (GlobalItemLedgEntry."Invoiced Quantity" - ValueEntry."Invoiced Quantity") = 0 then
            exit;
        with ValueEntry2 do begin
            SetCurrentKey("Item Ledger Entry No.", "Entry Type");
            SetRange("Item Ledger Entry No.", ValueEntry."Item Ledger Entry No.");
            SetRange("Entry Type", "Entry Type"::Revaluation);
            SetRange("Applies-to Entry", 0);
            if FindSet() then
                repeat
                    CalcRevExpCostToBalance(ValueEntry2, ValueEntry."Invoiced Quantity", RevExpCostToBalance, RevExpCostToBalanceACY);
                    if (RevExpCostToBalance <> 0) or (RevExpCostToBalanceACY <> 0) then begin
                        ValueEntryNo := ValueEntryNo + 1;
                        ValueEntry3 := ValueEntry;
                        ValueEntry3."Entry No." := ValueEntryNo;
                        ValueEntry3."Item Charge No." := '';
                        ValueEntry3."Entry Type" := ValueEntry."Entry Type"::Revaluation;
                        ValueEntry3."Valuation Date" := "Valuation Date";
                        ValueEntry3.Description := '';
                        ValueEntry3."Applies-to Entry" := "Entry No.";
                        ValueEntry3."Cost Amount (Expected)" := RevExpCostToBalance;
                        ValueEntry3."Cost Amount (Expected) (ACY)" := RevExpCostToBalanceACY;
                        ValueEntry3."Valued Quantity" := "Valued Quantity";
                        ValueEntry3."Cost per Unit" := CalcCostPerUnit(RevExpCostToBalance, ValueEntry."Valued Quantity", false);
                        ValueEntry3."Cost per Unit (ACY)" := CalcCostPerUnit(RevExpCostToBalanceACY, ValueEntry."Valued Quantity", true);
                        ValueEntry3."Cost Posted to G/L" := 0;
                        ValueEntry3."Cost Posted to G/L (ACY)" := 0;
                        ValueEntry3."Expected Cost Posted to G/L" := 0;
                        ValueEntry3."Exp. Cost Posted to G/L (ACY)" := 0;
                        ValueEntry3."Invoiced Quantity" := 0;
                        ValueEntry3."Sales Amount (Actual)" := 0;
                        ValueEntry3."Purchase Amount (Actual)" := 0;
                        ValueEntry3."Discount Amount" := 0;
                        ValueEntry3."Cost Amount (Actual)" := 0;
                        ValueEntry3."Cost Amount (Actual) (ACY)" := 0;
                        ValueEntry3."Sales Amount (Expected)" := 0;
                        ValueEntry3."Purchase Amount (Expected)" := 0;
                        InsertValueEntry(ValueEntry3, GlobalItemLedgEntry, false);
                    end;
                until Next() = 0;
        end;
    end;

    local procedure IsBalanceExpectedCostFromRev(ItemJnlLine2: Record "Item Journal Line"): Boolean
    begin
        with ItemJnlLine2 do
            exit((Item."Costing Method" = Item."Costing Method"::Standard) and
              (((Quantity = 0) and ("Invoiced Quantity" <> 0)) or
               (Adjustment and not GlobalValueEntry."Expected Cost")));
    end;

    local procedure CalcRevExpCostToBalance(ValueEntry: Record "Value Entry"; InvdQty: Decimal; var RevExpCostToBalance: Decimal; var RevExpCostToBalanceACY: Decimal)
    var
        ValueEntry2: Record "Value Entry";
        OldExpectedQty: Decimal;
    begin
        with ValueEntry2 do begin
            RevExpCostToBalance := -ValueEntry."Cost Amount (Expected)";
            RevExpCostToBalanceACY := -ValueEntry."Cost Amount (Expected) (ACY)";
            OldExpectedQty := GlobalItemLedgEntry.Quantity;
            SetCurrentKey("Item Ledger Entry No.", "Entry Type");
            SetRange("Item Ledger Entry No.", ValueEntry."Item Ledger Entry No.");
            if GlobalItemLedgEntry.Quantity <> GlobalItemLedgEntry."Invoiced Quantity" then begin
                SetRange("Entry Type", "Entry Type"::"Direct Cost");
                SetFilter("Entry No.", '<%1', ValueEntry."Entry No.");
                SetRange("Item Charge No.", '');
                if FindSet() then
                    repeat
                        OldExpectedQty := OldExpectedQty - "Invoiced Quantity";
                    until Next() = 0;

                RevExpCostToBalance := Round(RevExpCostToBalance * InvdQty / OldExpectedQty, GLSetup."Amount Rounding Precision");
                RevExpCostToBalanceACY := Round(RevExpCostToBalanceACY * InvdQty / OldExpectedQty, Currency."Amount Rounding Precision");
            end else begin
                SetRange("Entry Type", "Entry Type"::Revaluation);
                SetRange("Applies-to Entry", ValueEntry."Entry No.");
                if FindSet() then
                    repeat
                        RevExpCostToBalance := RevExpCostToBalance - "Cost Amount (Expected)";
                        RevExpCostToBalanceACY := RevExpCostToBalanceACY - "Cost Amount (Expected) (ACY)";
                    until Next() = 0;
            end;
        end;
    end;

    local procedure IsInterimRevaluation() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsInterimRevaluation(ItemJnlLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        with ItemJnlLine do
            exit(("Value Entry Type" = "Value Entry Type"::Revaluation) and (Quantity <> 0));
    end;

    local procedure InsertPostValueEntryToGL(ValueEntry: Record "Value Entry")
    var
        PostValueEntryToGL: Record "Post Value Entry to G/L";
    begin
        if IsPostToGL(ValueEntry) then begin
            PostValueEntryToGL.Init();
            PostValueEntryToGL."Value Entry No." := ValueEntry."Entry No.";
            PostValueEntryToGL."Item No." := ValueEntry."Item No.";
            PostValueEntryToGL."Posting Date" := ValueEntry."Posting Date";
            OnInsertPostValueEntryToGLOnAfterTransferFields(PostValueEntryToGL, ValueEntry);
            PostValueEntryToGL.Insert();
        end;

        OnAfterInsertPostValueEntryToGL(ValueEntry);
    end;

    local procedure IsPostToGL(ValueEntry: Record "Value Entry") Result: Boolean
    begin
        GetInvtSetup();
        with ValueEntry do
            Result :=
              Inventoriable and not PostToGL and
              (((not "Expected Cost") and (("Cost Amount (Actual)" <> 0) or ("Cost Amount (Actual) (ACY)" <> 0))) or
               (InvtSetup."Expected Cost Posting to G/L" and (("Cost Amount (Expected)" <> 0) or ("Cost Amount (Expected) (ACY)" <> 0))));

        OnAfterIsPostToGL(ValueEntry, Result);
    end;

    local procedure IsWarehouseReclassification(ItemJournalLine: Record "Item Journal Line"): Boolean
    begin
        exit(ItemJournalLine."Warehouse Adjustment" and (ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::Transfer));
    end;

    local procedure IsNotValuedByAverageCost(CostItemLedgEntryNo: Integer): Boolean
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", CostItemLedgEntryNo);
        ValueEntry.SetRange("Valued By Average Cost", true);
        exit(ValueEntry.IsEmpty());
    end;

    local procedure MoveApplication(var ItemLedgEntry: Record "Item Ledger Entry"; var OldItemLedgEntry: Record "Item Ledger Entry"): Boolean
    var
        Application: Record "Item Application Entry";
        Enough: Boolean;
        FixedApplication: Boolean;
    begin
        OnBeforeMoveApplication(ItemLedgEntry, OldItemLedgEntry);

        with ItemLedgEntry do begin
            FixedApplication := false;
            OldItemLedgEntry.TestField(Positive, true);

            if (OldItemLedgEntry."Remaining Quantity" < Abs(Quantity)) and
               (OldItemLedgEntry."Remaining Quantity" < OldItemLedgEntry.Quantity)
            then begin
                Enough := false;
                Application.Reset();
                Application.SetCurrentKey("Inbound Item Entry No.");
                Application.SetRange("Inbound Item Entry No.", "Applies-to Entry");
                Application.SetFilter("Outbound Item Entry No.", '<>0');

                if Application.FindSet() then begin
                    repeat
                        if not Application.Fixed() then begin
                            UnApply(Application);
                            OldItemLedgEntry.Get(OldItemLedgEntry."Entry No.");
                            OldItemLedgEntry.CalcReservedQuantity();
                            Enough :=
                              Abs(OldItemLedgEntry."Remaining Quantity" - OldItemLedgEntry."Reserved Quantity") >=
                              Abs("Remaining Quantity");
                        end else
                            FixedApplication := true;
                    until (Application.Next() = 0) or Enough;
                end else
                    exit(false); // no applications found that could be undone
                if not Enough and FixedApplication then
                    ShowFixedApplicationError();
                exit(Enough);
            end;
            exit(true);
        end;
    end;

    local procedure CheckApplication(ItemLedgEntry: Record "Item Ledger Entry"; OldItemLedgEntry: Record "Item Ledger Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckApplication(ItemLedgEntry, OldItemLedgEntry, IsHandled);
        if IsHandled then
            exit;

        if SkipApplicationCheck then begin
            SkipApplicationCheck := false;
            exit;
        end;

        if Abs(OldItemLedgEntry."Remaining Quantity" - OldItemLedgEntry."Reserved Quantity") <
           Abs(ItemLedgEntry."Remaining Quantity" - ItemLedgEntry."Reserved Quantity")
        then
            OldItemLedgEntry.FieldError("Remaining Quantity", Text004)
    end;

    local procedure CheckApplFromInProduction(var GlobalItemLedgerEntry: Record "Item Ledger Entry"; AppliesFRomEntryNo: Integer)
    var
        OldItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if AppliesFRomEntryNo = 0 then
            exit;

        with GlobalItemLedgerEntry do
            if ("Order Type" = "Order Type"::Production) and ("Order No." <> '') then begin
                OldItemLedgerEntry.Get(AppliesFRomEntryNo);
                if not AllowProdApplication(OldItemLedgerEntry, GlobalItemLedgEntry) then
                    Error(
                      Text022,
                      OldItemLedgerEntry."Entry Type",
                      "Entry Type",
                      "Item No.",
                      "Order No.");

                if ItemApplnEntry.CheckIsCyclicalLoop(GlobalItemLedgerEntry, OldItemLedgerEntry) then
                    Error(
                      Text022,
                      OldItemLedgerEntry."Entry Type",
                      "Entry Type",
                      "Item No.",
                      "Order No.");
            end;
    end;

    procedure RedoApplications()
    var
        TouchedItemLedgEntry: Record "Item Ledger Entry";
        DialogWindow: Dialog;
        "Count": Integer;
        t: Integer;
    begin
        TempTouchedItemLedgerEntries.SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Location Code", "Posting Date");
        if TempTouchedItemLedgerEntries.Find('-') then begin
            DialogWindow.Open(Text01 +
              '@1@@@@@@@@@@@@@@@@@@@@@@@');
            Count := TempTouchedItemLedgerEntries.Count();
            t := 0;

            repeat
                t := t + 1;
                DialogWindow.Update(1, Round(t * 10000 / Count, 1));
                TouchedItemLedgEntry.Get(TempTouchedItemLedgerEntries."Entry No.");
                if TouchedItemLedgEntry."Remaining Quantity" <> 0 then begin
                    ReApply(TouchedItemLedgEntry, 0);
                    TouchedItemLedgEntry.Get(TempTouchedItemLedgerEntries."Entry No.");
                end;
            until TempTouchedItemLedgerEntries.Next() = 0;
            if AnyTouchedEntries() then
                VerifyTouchedOnInventory();
            TempTouchedItemLedgerEntries.DeleteAll();
            DeleteTouchedEntries();
            DialogWindow.Close();
        end;
    end;

    local procedure UpdateValuedByAverageCost(CostItemLedgEntryNo: Integer; ValuedByAverage: Boolean)
    var
        ValueEntry: Record "Value Entry";
    begin
        if CostItemLedgEntryNo = 0 then
            exit;

        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", CostItemLedgEntryNo);
        ValueEntry.SetRange(Inventoriable, true);
        ValueEntry.SetRange("Valued By Average Cost", not ValuedByAverage);
        ValueEntry.ModifyAll("Valued By Average Cost", ValuedByAverage);
    end;

    procedure CostAdjust()
    var
        InvtSetup: Record "Inventory Setup";
        InventoryPeriod: Record "Inventory Period";
        InventoryAdjustmentHandler: Codeunit "Inventory Adjustment Handler";
        Opendate: Date;
    begin
        InvtSetup.Get();
        InventoryPeriod.IsValidDate(Opendate);
        if InvtSetup."Automatic Cost Adjustment" <> InvtSetup."Automatic Cost Adjustment"::Never then begin
            if Opendate <> 0D then
                Opendate := CalcDate('<+1D>', Opendate);

            InventoryAdjustmentHandler.MakeInventoryAdjustment(true, InvtSetup."Automatic Cost Posting");
        end;
    end;

    procedure TouchEntry(EntryNo: Integer)
    var
        TouchedItemLedgEntry: Record "Item Ledger Entry";
    begin
        TouchedItemLedgEntry.Get(EntryNo);
        TempTouchedItemLedgerEntries := TouchedItemLedgEntry;
        if not TempTouchedItemLedgerEntries.Insert() then;
    end;

    local procedure TouchItemEntryCost(var ItemLedgerEntry: Record "Item Ledger Entry"; IsAdjustment: Boolean)
    var
        ValueEntry: Record "Value Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTouchItemEntryCost(ItemLedgerEntry, ItemJnlLine, IsAdjustment, IsHandled);
        if IsHandled then
            exit;

        with ItemLedgerEntry do begin
            "Applied Entry to Adjust" := true;
            SetAdjmtProperties(
              "Item No.", "Entry Type", IsAdjustment, "Order Type", "Order No.", "Order Line No.", "Posting Date", "Posting Date");
        end;

        OnTouchItemEntryCostOnAfterAfterSetAdjmtProp(ItemLedgerEntry, IsAdjustment);

        if not IsAdjustment then begin
            EnsureValueEntryLoaded(ValueEntry, ItemLedgerEntry);
            AvgCostEntryPointHandler.UpdateValuationDate(ValueEntry);
        end;
    end;

    procedure AnyTouchedEntries(): Boolean
    begin
        exit(TempTouchedItemLedgerEntries.Find('-'));
    end;

    local procedure GetMaxAppliedValuationdate(ItemLedgerEntry: Record "Item Ledger Entry"): Date
    var
        ToItemApplnEntry: Record "Item Application Entry";
        FromItemledgEntryNo: Integer;
        FromInbound: Boolean;
        MaxDate: Date;
        NewDate: Date;
    begin
        FromInbound := ItemLedgerEntry.Positive;
        FromItemledgEntryNo := ItemLedgerEntry."Entry No.";
        with ToItemApplnEntry do begin
            if FromInbound then begin
                SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.");
                SetRange("Inbound Item Entry No.", FromItemledgEntryNo);
                SetFilter("Outbound Item Entry No.", '<>%1', 0);
                SetFilter(Quantity, '>%1', 0);
            end else begin
                SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.");
                SetRange("Outbound Item Entry No.", FromItemledgEntryNo);
                SetFilter(Quantity, '<%1', 0);
            end;
            if FindSet() then begin
                MaxDate := 0D;
                repeat
                    if FromInbound then
                        ItemLedgerEntry.Get("Outbound Item Entry No.")
                    else
                        ItemLedgerEntry.Get("Inbound Item Entry No.");
                    NewDate := GetMaxValuationDate(ItemLedgerEntry);
                    MaxDate := Max(NewDate, MaxDate);
                until Next() = 0
            end;
        end;
        exit(MaxDate);
    end;

    local procedure "Max"(Date1: Date; Date2: Date): Date
    begin
        if Date1 > Date2 then
            exit(Date1);
        exit(Date2);
    end;

    procedure SetValuationDateAllValueEntrie(ItemLedgerEntryNo: Integer; ValuationDate: Date; FixedApplication: Boolean)
    var
        ValueEntry: Record "Value Entry";
    begin
        with ValueEntry do begin
            Reset();
            SetCurrentKey("Item Ledger Entry No.");
            SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
            if FindSet() then
                repeat
                    if ("Valuation Date" <> "Posting Date") or
                       ("Valuation Date" < ValuationDate) or
                       (("Valuation Date" > ValuationDate) and FixedApplication)
                    then begin
                        "Valuation Date" := ValuationDate;
                        Modify();
                    end;
                until Next() = 0;
        end;
    end;

    procedure SetServUndoConsumption(Value: Boolean)
    begin
        IsServUndoConsumption := Value;
    end;

    procedure SetProdOrderCompModified(ProdOrderCompIsModified: Boolean)
    begin
        ProdOrderCompModified := ProdOrderCompIsModified;
    end;

    procedure InsertCountryCode(var NewItemLedgEntry: Record "Item Ledger Entry"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
        if ItemLedgEntry."Location Code" = '' then
            exit;
        if NewItemLedgEntry."Location Code" = '' then begin
            Location.Get(ItemLedgEntry."Location Code");
            NewItemLedgEntry."Country/Region Code" := Location."Country/Region Code";
        end else begin
            Location.Get(NewItemLedgEntry."Location Code");
            if not Location."Use As In-Transit" then begin
                Location.Get(ItemLedgEntry."Location Code");
                if not Location."Use As In-Transit" then
                    NewItemLedgEntry."Country/Region Code" := Location."Country/Region Code";
            end;
        end;
    end;

    local procedure ReservationPreventsApplication(ApplicationEntry: Integer; ItemNo: Code[20]; ReservationsEntry: Record "Item Ledger Entry")
    var
        ReservationEntries: Record "Reservation Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReserveItemLedgEntry: Codeunit "Item Ledger Entry-Reserve";
    begin
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservationEntries, true);
        ReserveItemLedgEntry.FilterReservFor(ReservationEntries, ReservationsEntry);
        if ReservationEntries.FindFirst() then;
        Error(
          Text029,
          ReservationsEntry.FieldCaption("Applies-to Entry"),
          ApplicationEntry,
          Item.FieldCaption("No."),
          ItemNo,
          ReservEngineMgt.CreateForText(ReservationEntries));
    end;

    local procedure CheckItemTrackingOfComp(TempHandlingSpecification: Record "Tracking Specification"; ItemJnlLine: Record "Item Journal Line")
    var
        ItemTrackingSetup2: Record "Item Tracking Setup";
    begin
        ItemTrackingSetup2 := GlobalItemTrackingSetup;
        ItemTrackingSetup2.CopyTrackingFromTrackingSpec(TempHandlingSpecification);
        ItemJnlLine.CheckTrackingIfRequired(ItemTrackingSetup2);

        OnAfterCheckItemTrackingOfComp(TempHandlingSpecification, ItemJnlLine);
    end;

    local procedure MaxConsumptionValuationDate(ItemLedgerEntry: Record "Item Ledger Entry"): Date
    var
        ValueEntry: Record "Value Entry";
    begin
        with ValueEntry do begin
            SetCurrentKey("Item Ledger Entry Type", "Order No.", "Valuation Date");
            SetRange("Order Type", "Order Type"::Production);
            SetRange("Order No.", ItemLedgerEntry."Order No.");
            SetRange("Order Line No.", ItemLedgerEntry."Order Line No.");
            SetRange("Item Ledger Entry Type", "Item Ledger Entry Type"::Consumption);
            SetFilter("Entry Type", '<>%1', "Entry Type"::Revaluation);
            if FindLast() then
                exit("Valuation Date");
        end;
    end;

    local procedure CorrectOutputValuationDate(ItemLedgerEntry: Record "Item Ledger Entry")
    var
        ValueEntry: Record "Value Entry";
        TempValueEntry: Record "Value Entry" temporary;
        ProductionOrder: Record "Production Order";
        ValuationDate: Date;
        IsHandled: Boolean;
    begin
        if not (ItemLedgerEntry."Entry Type" in [ItemLedgerEntry."Entry Type"::Consumption, ItemLedgerEntry."Entry Type"::Output]) then
            exit;

        IsHandled := false;
        OnCorrectOutputValuationDateOnBeforeCheckProdOrder(ItemLedgerEntry, IsHandled);
        if not IsHandled then
            if not ProductionOrder.Get(ProductionOrder.Status::Released, ItemLedgerEntry."Order No.") then
                exit;

        ValuationDate := MaxConsumptionValuationDate(ItemLedgerEntry);

        ValueEntry.SetCurrentKey("Order Type", "Order No.");
        ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Production);
        ValueEntry.SetFilter("Valuation Date", '<%1', ValuationDate);
        ValueEntry.SetRange("Order No.", ItemLedgerEntry."Order No.");
        ValueEntry.SetRange("Order Line No.", ItemLedgerEntry."Order Line No.");
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Output);
        if ValueEntry.FindSet() then
            repeat
                TempValueEntry := ValueEntry;
                TempValueEntry.Insert();
            until ValueEntry.Next() = 0;

        UpdateOutputEntryAndChain(TempValueEntry, ValuationDate);
    end;

    local procedure UpdateOutputEntryAndChain(var TempValueEntry: Record "Value Entry" temporary; ValuationDate: Date)
    var
        ValueEntry: Record "Value Entry";
        ItemLedgerEntryNo: Integer;
    begin
        TempValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        if TempValueEntry.Find('-') then
            repeat
                ValueEntry.Get(TempValueEntry."Entry No.");
                if ValueEntry."Valuation Date" < ValuationDate then begin
                    if ItemLedgerEntryNo <> TempValueEntry."Item Ledger Entry No." then begin
                        ItemLedgerEntryNo := TempValueEntry."Item Ledger Entry No.";
                        UpdateLinkedValuationDate(ValuationDate, ItemLedgerEntryNo, true);
                    end;

                    ValueEntry."Valuation Date" := ValuationDate;
                    ValueEntry.Modify();
                    if ValueEntry."Entry No." = DirCostValueEntry."Entry No." then
                        DirCostValueEntry := ValueEntry;
                end;
            until TempValueEntry.Next() = 0;
    end;

    local procedure GetSourceNo(ItemJnlLine: Record "Item Journal Line") Result: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSourceNo(ItemJnlLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if ItemJnlLine."Invoice-to Source No." <> '' then
            exit(ItemJnlLine."Invoice-to Source No.");
        exit(ItemJnlLine."Source No.");
    end;

    local procedure PostAssemblyResourceConsump()
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
        DirCostAmt: Decimal;
        IndirCostAmt: Decimal;
    begin
        with ItemJnlLine do begin
            InsertCapLedgEntry(CapLedgEntry, Quantity, Quantity);
            CalcDirAndIndirCostAmts(DirCostAmt, IndirCostAmt, Quantity, ItemJnlLine);

            InsertCapValueEntry(CapLedgEntry, "Value Entry Type"::"Direct Cost", Quantity, Quantity, DirCostAmt);
            InsertCapValueEntry(CapLedgEntry, "Value Entry Type"::"Indirect Cost", Quantity, 0, IndirCostAmt);
        end;
    end;

    local procedure InsertAsmItemEntryRelation(ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        GetItem(ItemLedgerEntry."Item No.", true);
        if Item."Item Tracking Code" <> '' then begin
            TempItemEntryRelation."Item Entry No." := ItemLedgerEntry."Entry No.";
            TempItemEntryRelation.CopyTrackingFromItemLedgEntry(ItemLedgerEntry);
            OnBeforeTempItemEntryRelationInsert(TempItemEntryRelation, ItemLedgerEntry);
            TempItemEntryRelation.Insert();
        end;
    end;

    local procedure VerifyInvoicedQty(ItemLedgerEntry: Record "Item Ledger Entry"; ValueEntry: Record "Value Entry")
    var
        ItemLedgEntry2: Record "Item Ledger Entry";
        ItemApplnEntry: Record "Item Application Entry";
        SalesShipmentHeader: Record "Sales Shipment Header";
        TotalInvoicedQty: Decimal;
        IsHandled: Boolean;
    begin
        if not (ItemLedgerEntry."Drop Shipment" and (ItemLedgerEntry."Entry Type" = ItemLedgerEntry."Entry Type"::Purchase)) then
            exit;

        IsHandled := false;
        OnBeforeVerifyInvoicedQty(ItemLedgerEntry, IsHandled, ValueEntry);
        if IsHandled then
            exit;

        ItemApplnEntry.SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.");
        ItemApplnEntry.SetRange("Inbound Item Entry No.", ItemLedgerEntry."Entry No.");
        ItemApplnEntry.SetFilter("Item Ledger Entry No.", '<>%1', ItemLedgerEntry."Entry No.");
        if ItemApplnEntry.FindSet() then begin
            repeat
                ItemLedgEntry2.Get(ItemApplnEntry."Item Ledger Entry No.");
                TotalInvoicedQty += ItemLedgEntry2."Invoiced Quantity";
            until ItemApplnEntry.Next() = 0;
            if ItemLedgerEntry."Invoiced Quantity" > Abs(TotalInvoicedQty) then begin
                SalesShipmentHeader.Get(ItemLedgEntry2."Document No.");
                IsHandled := false;
                OnVerifyInvoicedQtyOnAfterGetSalesShipmentHeader(ItemLedgEntry2, IsHandled);
                if IsHandled then
                    exit;
                if ItemLedgerEntry."Item Tracking" = ItemLedgerEntry."Item Tracking"::None then
                    Error(Text032, ItemLedgerEntry."Item No.", SalesShipmentHeader."Order No.");
                Error(
                  Text031, ItemLedgerEntry."Item No.", ItemLedgerEntry."Lot No.", ItemLedgerEntry."Serial No.", SalesShipmentHeader."Order No.")
            end;
        end;
    end;

    local procedure TransReserveFromJobPlanningLine(FromJobContractEntryNo: Integer; ToItemJnlLine: Record "Item Journal Line")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
        JobPlanningLine.SetRange("Job Contract Entry No.", FromJobContractEntryNo);
        JobPlanningLine.FindFirst();

        TempJobPlanningLine := JobPlanningLine;
        if not TempJobPlanningLine.Insert() then
            TempJobPlanningLine.Find();

        if TempJobPlanningLine."Remaining Qty. (Base)" >= ToItemJnlLine."Quantity (Base)" then
            TempJobPlanningLine."Remaining Qty. (Base)" := TempJobPlanningLine."Remaining Qty. (Base)" - ToItemJnlLine."Quantity (Base)"
        else
            TempJobPlanningLine."Remaining Qty. (Base)" := 0;
        TempJobPlanningLine.Modify();
        JobPlanningLineReserve.TransferJobLineToItemJnlLine(TempJobPlanningLine, ToItemJnlLine, ToItemJnlLine."Quantity (Base)");
    end;

    procedure SetupTempSplitItemJnlLine(ItemJnlLine2: Record "Item Journal Line"; SignFactor: Integer; var NonDistrQuantity: Decimal; var NonDistrAmount: Decimal; var NonDistrAmountACY: Decimal; var NonDistrDiscountAmount: Decimal; Invoice: Boolean): Boolean
    var
        FloatingFactor: Decimal;
        PostItemJnlLine: Boolean;
    begin
        with TempSplitItemJnlLine do begin
            "Quantity (Base)" := SignFactor * TempTrackingSpecification."Qty. to Handle (Base)";
            Quantity := SignFactor * TempTrackingSpecification."Qty. to Handle";
            if Invoice then begin
                "Invoiced Quantity" := SignFactor * TempTrackingSpecification."Qty. to Invoice";
                "Invoiced Qty. (Base)" := SignFactor * TempTrackingSpecification."Qty. to Invoice (Base)";
            end;

            if ItemJnlLine2."Output Quantity" <> 0 then begin
                "Output Quantity (Base)" := "Quantity (Base)";
                "Output Quantity" := Quantity;
            end;

            if ItemJnlLine2."Phys. Inventory" then
                "Qty. (Phys. Inventory)" := "Qty. (Calculated)" + SignFactor * "Quantity (Base)";

            OnAfterSetupTempSplitItemJnlLineSetQty(TempSplitItemJnlLine, ItemJnlLine2, SignFactor, TempTrackingSpecification);

            FloatingFactor := Quantity / NonDistrQuantity;
            if FloatingFactor < 1 then begin
                Amount := Round(NonDistrAmount * FloatingFactor, GLSetup."Amount Rounding Precision");
                "Amount (ACY)" := Round(NonDistrAmountACY * FloatingFactor, Currency."Amount Rounding Precision");
                "Discount Amount" := Round(NonDistrDiscountAmount * FloatingFactor, GLSetup."Amount Rounding Precision");
                NonDistrAmount := NonDistrAmount - Amount;
                NonDistrAmountACY := NonDistrAmountACY - "Amount (ACY)";
                NonDistrDiscountAmount := NonDistrDiscountAmount - "Discount Amount";
                NonDistrQuantity := NonDistrQuantity - Quantity;
                "Setup Time" := 0;
                "Run Time" := 0;
                "Stop Time" := 0;
                "Setup Time (Base)" := 0;
                "Run Time (Base)" := 0;
                "Stop Time (Base)" := 0;
                "Starting Time" := 0T;
                "Ending Time" := 0T;
                "Scrap Quantity" := 0;
                "Scrap Quantity (Base)" := 0;
                "Concurrent Capacity" := 0;
            end else begin // the last record
                Amount := NonDistrAmount;
                "Amount (ACY)" := NonDistrAmountACY;
                "Discount Amount" := NonDistrDiscountAmount;
            end;

            if Round("Unit Amount" * Quantity, GLSetup."Amount Rounding Precision") <> Amount then
                if ("Unit Amount" = "Unit Cost") and ("Unit Cost" <> 0) then begin
                    "Unit Amount" := Round(Amount / Quantity, 0.00001);
                    "Unit Cost" := Round(Amount / Quantity, 0.00001);
                    "Unit Cost (ACY)" := Round("Amount (ACY)" / Quantity, 0.00001);
                end else
                    "Unit Amount" := Round(Amount / Quantity, 0.00001);

            CopyTrackingFromSpec(TempTrackingSpecification);
            "Item Expiration Date" := TempTrackingSpecification."Expiration Date";
            CopyNewTrackingFromNewSpec(TempTrackingSpecification);
            "New Item Expiration Date" := TempTrackingSpecification."New Expiration Date";

            OnSetupTempSplitItemJnlLineOnBeforeCalcPostItemJnlLine(TempSplitItemJnlLine, TempTrackingSpecification);
            PostItemJnlLine := not HasSameNewTracking() or ("Item Expiration Date" <> "New Item Expiration Date");
            OnSetupTempSplitItemJnlLineOnAfterCalcPostItemJnlLine(TempSplitItemJnlLine, TempTrackingSpecification, PostItemJnlLine);

            "Warranty Date" := TempTrackingSpecification."Warranty Date";

            "Line No." := TempTrackingSpecification."Entry No.";

            if TempTrackingSpecification.Correction or "Drop Shipment" or IsServUndoConsumption then
                "Applies-to Entry" := TempTrackingSpecification."Item Ledger Entry No."
            else
                "Applies-to Entry" := TempTrackingSpecification."Appl.-to Item Entry";
            "Applies-from Entry" := TempTrackingSpecification."Appl.-from Item Entry";

            OnBeforeInsertSetupTempSplitItemJnlLine(TempTrackingSpecification, TempSplitItemJnlLine, PostItemJnlLine, ItemJnlLine2, SignFactor, FloatingFactor);

            Insert();
        end;

        exit(PostItemJnlLine);
    end;

    local procedure ReservationExists(ItemJnlLine: Record "Item Journal Line"): Boolean
    var
        ReservEntry: Record "Reservation Entry";
        ProductionOrder: Record "Production Order";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeReservationExists(ItemJnlLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        with ReservEntry do begin
            SetRange("Source ID", ItemJnlLine."Order No.");
            if ItemJnlLine."Prod. Order Comp. Line No." <> 0 then
                SetRange("Source Ref. No.", ItemJnlLine."Prod. Order Comp. Line No.");
            SetRange("Source Type", DATABASE::"Prod. Order Component");
            SetRange("Source Subtype", ProductionOrder.Status::Released);
            SetRange("Source Batch Name", '');
            SetRange("Source Prod. Order Line", ItemJnlLine."Order Line No.");
            SetFilter("Qty. to Handle (Base)", '<>0');
            exit(not IsEmpty);
        end;
    end;

    local procedure PostInvtBuffer(var ValueEntry: Record "Value Entry")
    begin
        if InventoryPostingToGL.BufferInvtPosting(ValueEntry) then begin
            OnPostInvtBufferOnAfterBufferInvtPosting(ValueEntry);
            GetInvtSetup();
            GetGLSetup();
            if GLSetup."Journal Templ. Name Mandatory" then
                InventoryPostingToGL.SetGenJnlBatch(
                    InvtSetup."Invt. Cost Jnl. Template Name", InvtSetup."Invt. Cost Jnl. Batch Name");
            InventoryPostingToGL.PostInvtPostBufPerEntry(ValueEntry);
        end;
    end;

    local procedure VerifyTouchedOnInventory()
    var
        ItemLedgEntryApplied: Record "Item Ledger Entry";
    begin
        with TempTouchedItemLedgerEntries do begin
            FindSet();
            repeat
                ItemLedgEntryApplied.Get("Entry No.");
                ItemLedgEntryApplied.VerifyOnInventory(
                    StrSubstNo(CannotUnapplyItemLedgEntryErr, ItemLedgEntryApplied."Item No.", ItemLedgEntryApplied."Entry No."));
            until Next() = 0;
        end;
    end;

    local procedure CheckIsCyclicalLoop(ItemLedgEntry: Record "Item Ledger Entry"; OldItemLedgEntry: Record "Item Ledger Entry"; var PrevAppliedItemLedgEntry: Record "Item Ledger Entry"; var AppliedQty: Decimal)
    var
        PrevProcessedProdOrder: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIsCyclicalLoop(ItemLedgEntry, OldItemLedgEntry, PrevAppliedItemLedgEntry, AppliedQty, IsHandled);
        if IsHandled then
            exit;

        PrevProcessedProdOrder :=
          (ItemLedgEntry."Entry Type" = ItemLedgEntry."Entry Type"::Consumption) and
          (OldItemLedgEntry."Entry Type" = OldItemLedgEntry."Entry Type"::Output) and
          (ItemLedgEntry."Order Type" = ItemLedgEntry."Order Type"::Production) and
          EntriesInTheSameOrder(OldItemLedgEntry, PrevAppliedItemLedgEntry);

        if not PrevProcessedProdOrder then
            if AppliedQty <> 0 then
                if ItemLedgEntry.Positive then begin
                    if ItemApplnEntry.CheckIsCyclicalLoop(ItemLedgEntry, OldItemLedgEntry) then
                        AppliedQty := 0;
                end else
                    if ItemApplnEntry.CheckIsCyclicalLoop(OldItemLedgEntry, ItemLedgEntry) then
                        AppliedQty := 0;

        if AppliedQty <> 0 then
            PrevAppliedItemLedgEntry := OldItemLedgEntry;
    end;

    local procedure EntriesInTheSameOrder(OldItemLedgEntry: Record "Item Ledger Entry"; PrevAppliedItemLedgEntry: Record "Item Ledger Entry"): Boolean
    begin
        exit(
          (PrevAppliedItemLedgEntry."Order Type" = PrevAppliedItemLedgEntry."Order Type"::Production) and
          (OldItemLedgEntry."Order Type" = OldItemLedgEntry."Order Type"::Production) and
          (OldItemLedgEntry."Order No." = PrevAppliedItemLedgEntry."Order No.") and
          (OldItemLedgEntry."Order Line No." = PrevAppliedItemLedgEntry."Order Line No."));
    end;

    local procedure MustConsiderUnitCostRoundingOnRevaluation(ItemJournalLine: Record "Item Journal Line"): Boolean
    begin
        exit(
          (ItemJournalLine."Value Entry Type" = ItemJournalLine."Value Entry Type"::Revaluation) and
          (GetItem(ItemJournalLine."Item No.", false) and (Item."Costing Method" = Item."Costing Method"::Average) or
           (ItemJournalLine."Applies-to Entry" <> 0)));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAllowProdApplication(OldItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry"; var AllowApplication: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyItemLedgEntry(var ItemLedgEntry: Record "Item Ledger Entry"; var OldItemLedgEntry: Record "Item Ledger Entry"; var ValueEntry: Record "Value Entry"; CausedByTransfer: Boolean; var Handled: Boolean; ItemJnlLine: Record "Item Journal Line"; var ItemApplnEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyItemLedgEntrySetFilters(var ToItemLedgEntry: Record "Item Ledger Entry"; FromItemLedgEntry: Record "Item Ledger Entry"; ItemTrackingCode: Record "Item Tracking Code"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckApplication(ItemLedgerEntry: Record "Item Ledger Entry"; OldItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckExpirationDate(var ItemJournalLine: Record "Item Journal Line"; var TrackingSpecification: Record "Tracking Specification"; SignFactor: Integer; CalcExpirationDate: Date; var ExpirationDateChecked: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLotNoInfoNotBlocked(var ItemJnlLine2: Record "Item Journal Line"; var IsHandled: Boolean; var ItemTrackingSetup: Record "Item Tracking Setup"; var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemCorrection(ItemLedgerEntry: Record "Item Ledger Entry"; var RaiseError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemTracking(var ItemJournalLine: Record "Item Journal Line"; ItemTrackingSetup: Record "Item Tracking Setup"; var IsHandled: Boolean; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemTrackingInformation(var ItemJnlLine2: Record "Item Journal Line"; var TrackingSpecification: Record "Tracking Specification"; var ItemTrackingSetup: Record "Item Tracking Setup"; var SignFactor: Decimal; var ItemTrackingCode: Record "Item Tracking Code"; var IsHandled: Boolean; var GlobalItemTrackingCode: Record "Item Tracking Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAppliedEntriesToReadjust(ItemLedgEntry: Record "Item Ledger Entry"; var Readjust: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcAdjustedCost(var ItemJournalLine: Record "Item Journal Line"; var AdjustedCostLCY: Decimal; var AdjustedCostACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckItemTracking(ItemJournalLine: Record "Item Journal Line"; ItemTrackingSetup: Record "Item Tracking Setup"; GlobalItemTrackingCode: Record "Item Tracking Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckItemTrackingInformation(var ItemJnlLine2: Record "Item Journal Line"; var TrackingSpecification: Record "Tracking Specification"; ItemTrackingSetup: Record "Item Tracking Setup"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitCorrItemLedgEntry(var NewItemLedgEntry: Record "Item Ledger Entry"; EntriesExist: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfItemIsBlocked(var ItemJournalLine: Record "Item Journal Line"; CalledFromAdjustment: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckRunItemValuePosting(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateItemJnlLineFromEntry(var ItemJournalLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertTempSplitItemJnlLine(var TempSplitItemJournalLine: Record "Item Journal Line" temporary; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertApplEntry(var ItemLedgEntryNo: Integer; var InboundItemEntry: Integer; var OutboundItemEntry: Integer; var TransferedFromEntryNo: Integer; var PostingDate: Date; var Quantity: Decimal; var CostToApply: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTransferEntry(var NewItemLedgerEntry: Record "Item Ledger Entry"; var OldItemLedgerEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFlushOperation(var ProdOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; var ItemJnlLine: Record "Item Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetItem(var Item: Record Item; ItemNo: Code[20]; Unconditionally: Boolean; var HasGotItem: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSourceNo(ItemJournalLine: Record "Item Journal Line"; var Result: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostFlushedConsump(var ProdOrderComp: Record "Prod. Order Component"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; OldItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostConsumption(var ProdOrderComp: Record "Prod. Order Component"; var ItemJnlLine: Record "Item Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPhysInvtLedgEntry(var PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry"; ItemJournalLine: Record "Item Journal Line"; LastSplitItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitItemLedgEntry(var NewItemLedgEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line"; var ItemLedgEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertItemLedgEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line"; var ItemLedgEntryNo: Integer; var ValueEntryNo: Integer; var ItemApplnEntryNo: Integer; GlobalValueEntry: Record "Value Entry"; TransferItem: Boolean; var InventoryPostingToGL: Codeunit "Inventory Posting To G/L"; var OldItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertItemLedgEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line"; TransferItem: Boolean; OldItemLedgEntry: Record "Item Ledger Entry"; ItemJournalLineOrigin: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertItemLedgEntryProcedure(var ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertValueEntry(var ValueEntry: Record "Value Entry"; ItemJournalLine: Record "Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertValueEntry(var ValueEntry: Record "Value Entry"; ItemJournalLine: Record "Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntryNo: Integer; var InventoryPostingToGL: Codeunit "Inventory Posting To G/L"; CalledFromAdjustment: Boolean; var OldItemLedgEntry: Record "Item Ledger Entry"; var Item: Record Item; TransferItem: Boolean; var GlobalValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertValueEntryProcedure(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitValueEntry(var ValueEntry: Record "Value Entry"; var ItemJournalLine: Record "Item Journal Line"; var ValueEntryNo: Integer; var ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertCapLedgEntry(var CapLedgEntry: Record "Capacity Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCapLedgEntry(var CapLedgEntry: Record "Capacity Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertCapValueEntry(var ValueEntry: Record "Value Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCapValueEntryProcedure(ItemJournalLine: Record "Item Journal Line"; ValueEntryType: Enum "Cost Entry Type"; var ValuedQty: Decimal; var InvdQty: Decimal; var AdjdCost: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCapValueEntry(var ValueEntry: Record "Value Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCorrItemLedgEntry(var NewItemLedgerEntry: Record "Item Ledger Entry"; var OldItemLedgerEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertCorrItemLedgEntry(var NewItemLedgerEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line"; var OldItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCorrValueEntry(var NewValueEntry: Record "Value Entry"; OldValueEntry: Record "Value Entry"; var ItemJournalLine: Record "Item Journal Line"; Sign: Integer; CalledFromAdjustment: Boolean; var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntryNo: Integer; var InventoryPostingToGL: Codeunit "Inventory Posting To G/L")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertCorrValueEntry(var NewValueEntry: Record "Value Entry"; var ItemJournalLine: Record "Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertConsumpEntry(var ProdOrderComponent: Record "Prod. Order Component"; QtyBase: Decimal; var ModifyProdOrderComp: Boolean; var ItemJnlLine: Record "Item Journal Line"; var TempSplitItemJnlLine: Record "Item Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemApplnEntryInsert(var ItemApplicationEntry: Record "Item Application Entry"; GlobalItemLedgerEntry: Record "Item Ledger Entry"; OldItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemQtyPosting(ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemApplnEntryInsert(var ItemApplicationEntry: Record "Item Application Entry"; GlobalItemLedgerEntry: Record "Item Ledger Entry"; OldItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNextOperationExist(var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItem(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean; CalledFromAdjustment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; CalledFromAdjustment: Boolean; CalledFromInvtPutawayPick: Boolean; var ItemRegister: Record "Item Register"; var ItemLedgEntryNo: Integer; var ValueEntryNo: Integer; var ItemApplnEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetValueEntrySourceFieldsFromItemJnlLine(var ValueEntry: Record "Value Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterPostItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntryNo: Integer; var InventoryPostingToGL: Codeunit "Inventory Posting To G/L"; CalledFromAdjustment: Boolean; CalledFromInvtPutawayPick: Boolean; var ItemRegister: Record "Item Register"; var ItemLedgEntryNo: Integer; var ItemApplnEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostOutput(var ItemLedgerEntry: Record "Item Ledger Entry"; var ProdOrderLine: Record "Prod. Order Line"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnBeforeProdOrderRtngLineModify(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ProdOrderLine: Record "Prod. Order Line"; var ItemJournalLine: Record "Item Journal Line"; var LastOperation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnAfterProdOrderRtngLineSetFilters(var ProdOrderRtngLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckPostingCostToGL(var PostCostToGL: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckExpirationDateOnBeforeTestFieldExpirationDate(var TempTrackingSpecification: Record "Tracking Specification" temporary; var EntriesExist: Boolean; var ExistingExpirationDate: Date);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSetupTempSplitItemJnlLine(var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempItemJournalLine: Record "Item Journal Line" temporary; var PostItemJnlLine: Boolean; var ItemJournalLine2: Record "Item Journal Line"; SignFactor: Integer; FloatingFactor: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeFlushOperation(var ProdOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; var ItemJnlLine: Record "Item Journal Line"; LastOperation: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostFlushedConsumpItemJnlLine(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateOldItemLedgerEntryRemainingQuantity(var OldItemLedgerEntry: Record "Item Ledger Entry"; AppliedQuantity: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateItemLedgerEntryRemainingQuantity(var ItemLedgerEntry: Record "Item Ledger Entry"; AppliedQuantity: Decimal)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterItemValuePosting(var ValueEntry: Record "Value Entry"; var ItemJournalLine: Record "Item Journal Line"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetupSplitJnlLineOnBeforeSplitTempLines(var TempSplitItemJournalLine: Record "Item Journal Line" temporary; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetupSplitJnlLineOnAfterCheckExpirationDate(var ItemJnlLine2: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetupSplitJnlLineOnBeforeCheckUseExpirationDates(var ItemJnlLine2: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; Item: Record Item; var CalcExpirationDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetupSplitJnlLineOnAfterGetItemTrackingSetup(ItemTrackingCode: Record "Item Tracking Code"; ItemJnlLine: Record "Item Journal Line"; var ItemTrackingSetup: Record "Item Tracking Setup"; GlobalItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetupSplitJnlLineOnBeforeGetItemTrackingSetup(var ItemJnlLine2: Record "Item Journal Line"; TrackingSpecExists: Boolean; CalledFromAdjustment: Boolean; var Item: Record Item; var ItemTrackingCode: Record "Item Tracking Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetupSplitJnlLineOnAfterSetupTempSplitItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; var TempSplitItemJournalLine: Record "Item Journal Line" temporary; TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcExpectedCost(var ValueEntry: Record "Value Entry"; ItemLedgerEntryNo: Integer; var ExpectedCost: Decimal; var ExpectedCostACY: Decimal; var ExpectedSalesAmt: Decimal; var ExpectedPurchAmt: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcPurchCorrShares(var ValueEntry: Record "Value Entry"; var ItemJournalLine: Record "Item Journal Line"; var OverheadAmount: Decimal; var OverheadAmountACY: Decimal; var VarianceAmount: Decimal; var VarianceAmountACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcPosShares(var ItemJournalLine: Record "Item Journal Line"; var DirCost: Decimal; var OvhdCost: Decimal; var PurchVar: Decimal; var DirCostACY: Decimal; var OvhdCostACY: Decimal; var PurchVarACY: Decimal; var CalcUnitCost: Boolean; CalcPurchVar: Boolean; Expected: Boolean; GlobalItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertOHValueEntry(var ValueEntry: Record "Value Entry"; var Item: Record Item; var OverheadAmount: Decimal; var OverheadAmountACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupTempSplitItemJnlLineSetQty(var TempSplitItemJnlLine: Record "Item Journal Line" temporary; ItemJournalLine: Record "Item Journal Line"; SignFactor: Integer; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAdjmtProp(var ValueEntry: Record "Value Entry"; OriginalPostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateUnitCost(ValueEntry: Record "Value Entry"; LastDirectCost: Decimal; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcDirAndIndirCostAmts(var ItemJournalLine: Record "Item Journal Line"; var DirCostAmt: Decimal; var IndirCostAmt: Decimal; CapQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcExpirationDate(var ItemJnlLine: Record "Item Journal Line"; var ExpirationDate: Date; var IsHandled: Boolean; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCallFlushOperation(var ItemJnlLine: Record "Item Journal Line"; var ShouldFlushOperation: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSerialNo(ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemTrackingIsEmpty(ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIsCyclicalLoop(ItemLedgEntry: Record "Item Ledger Entry"; OldItemLedgEntry: Record "Item Ledger Entry"; var PrevAppliedItemLedgEntry: Record "Item Ledger Entry"; var AppliedQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostFlushedConsump(ProdOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderComp: Record "Prod. Order Component"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; OldItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInitValueEntry(var ValueEntry: Record "Value Entry"; var ValueEntryNo: Integer; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertOHValueEntry(var ValueEntry: Record "Value Entry"; var Item: Record Item; var OverheadAmount: Decimal; var OverheadAmountACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertVarValueEntry(var ValueEntry: Record "Value Entry"; var Item: Record Item; var VarianceAmount: Decimal; var VarianceAmountACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTempSplitItemJnlLine(ItemJournalLine: Record "Item Journal Line"; IsServUndoConsumption: Boolean; PostponeReservationHandling: Boolean; var TempSplitItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean; var PostItemJnlLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveApplication(var ItemLedgEntry: Record "Item Ledger Entry"; var OldItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOldItemLedgEntryModify(var OldItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostLineByEntryType(var ItemJournalLine: Record "Item Journal Line"; CalledFromAdjustment: Boolean; CalledFromInvtPutawayPick: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProdOrderCompModify(var ProdOrderComponent: Record "Prod. Order Component"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProdOrderLineModify(var ProdOrderLine: Record "Prod. Order Line"; ItemJournalLine: Record "Item Journal Line"; ItemLedgEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRoundAmtValueEntry(var ValueEntry: Record "Value Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRetrieveCostPerUnit(ItemJournalLine: Record "Item Journal Line"; SKU: Record "Stockkeeping Unit"; SKUExists: Boolean; var UnitCost: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeRunWithCheck(var ItemJournalLine: Record "Item Journal Line"; CalledFromAdjustment: Boolean; CalledFromInvtPutawayPick: Boolean; CalledFromApplicationWorksheet: Boolean; PostponeReservationHandling: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempItemEntryRelationInsert(var TempItemEntryRelation: Record "Item Entry Relation" temporary; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestFirstApplyItemLedgEntry(var OldItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTrackingSpecificationMissingErr(ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetOrderAdjmtProperties(ItemLedgEntryType: Option; OrderType: Option; OrderNo: Code[20]; OrderLineNo: Integer; OriginalPostingDate: Date; ValuationDate: Date; var IsHandled: Boolean; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetupSplitJnlLine(var ItemJnlLine2: Record "Item Journal Line"; var TrackingSpecExists: Boolean; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyInvoicedQty(ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean; ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyItemJnlLineAsembleToOrder(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUndoQuantityPosting(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; var ItemJournalLine: Record "Item Journal Line"; ReTrack: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitCost(var ValueEntry: Record "Value Entry"; var IsHandled: Boolean; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateItemLedgerEntryRemainingQuantity(var ItemLedgerEntry: Record "Item Ledger Entry"; var OldItemLedgEntry: Record "Item Ledger Entry"; AppliedQty: Decimal; CausedByTransfer: Boolean; AverageTransfer: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnAfterCloseReservEntry(var OldItemLedgEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnBeforeCloseReservEntry(var OldItemLedgEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnBeforeStartApplication(var ItemLedgerEntry: Record "Item Ledger Entry"; var OldItemLedgerEntry: Record "Item Ledger Entry"; var StartApplication: Boolean; var AppliedQty: Decimal)
    begin
    end;

#if not CLEAN21
    [Obsolete('Event is never called', '21.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyItemLedgEntry(var GlobalItemLedgerEntry: Record "Item Ledger Entry"; var OldItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;
#endif
    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyItemLedgEntrySetFilters(var ItemLedgerEntry2: Record "Item Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyItemLedgEntryOnBeforeCalcAppliedQty(var OldItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetGLSetup(var GeneralLedgerSetup: Record "General Ledger Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveValEntryDimToValEntryDim(var ToValueEntry: Record "Value Entry"; FromValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertTransferEntry(var ItemJournalLine: Record "Item Journal Line"; NewItemLedgerEntry: Record "Item Ledger Entry"; OldItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItem(var ItemJournalLine: Record "Item Journal Line"; CalledFromAdjustment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostSplitJnlLine(var ItemJournalLine: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareItem(var ItemJnlLineToPost: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUndoQuantityPosting(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ReTrack: Boolean; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertConsumpEntry(var WarehouseJournalLine: Record "Warehouse Journal Line"; var ProdOrderComponent: Record "Prod. Order Component"; QtyBase: Decimal; PostWhseJnlLine: Boolean; var ItemJnlLine: Record "Item Journal Line"; ItemLedgEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCapNeedOnAfterSetFilters(var ProdOrderCapNeed: Record "Prod. Order Capacity Need"; ItemJnlLine: Record "Item Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnAfterCalcAppliedQty(OldItemLedgEntry: Record "Item Ledger Entry"; ItemLedgEntry: Record "Item Ledger Entry"; var AppliedQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnAfterSetAppliedQtyZero(OldItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry"; var AppliedQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnBeforeCheckApplyEntry(var OldItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnBeforeInsertApplEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line"; var OldItemLedgEntry: Record "Item Ledger Entry"; var GlobalItemLedgEntry: Record "Item Ledger Entry"; var AppliedQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnBeforeOldItemLedgEntryModify(var ItemLedgerEntry: Record "Item Ledger Entry"; var OldItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCollectTrackingSpecification(var TempTrackingSpecification: Record "Tracking Specification" temporary; var TargetTrackingSpecification: Record "Tracking Specification" temporary; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcExpectedCostOnBeforeFindValueEntry(var ValueEntry: Record "Value Entry"; ItemLedgEntryNo: Integer; InvoicedQty: Decimal; Quantity: Decimal; var ExpectedCost: Decimal; var ExpectedCostACY: Decimal; var ExpectedSalesAmt: Decimal; var ExpectedPurchAmt: Decimal; CalcReminder: Boolean; var InvdValueEntry: Record "Value Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcILEExpectedAmountOnBeforeCalcCostAmounts(var OldValueEntry2: Record "Value Entry"; var OldValueEntry: Record "Value Entry"; ItemLedgEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCorrectOutputValuationDateOnBeforeCheckProdOrder(ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFlushOperationOnAfterProdOrderCompSetFilters(var ProdOrderComponent: Record "Prod. Order Component"; OldItemJournalLine: Record "Item Journal Line"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFlushOperationOnBeforeCheckRoutingLinkCode(var ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ItemJournalLine: Record "Item Journal Line"; LastOperation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetValuationDateOnAfterOldValueEntrySetFilters(var OldValueEntry: Record "Value Entry"; ValueEntry: Record "Value Entry"; OldItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetValuationDateOnBeforeFindOldValueEntry(var OldValueEntry: Record "Value Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitTransValueEntryOnAfterInitValueEntry(var ValueEntry: Record "Value Entry"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitValueEntryOnAfterNotAdjustmentCheckClearCostAmount(var ValueEntry: Record "Value Entry"; var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitValueEntryOnAfterSetValueEntryInventoriable(var ValueEntry: Record "Value Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitValueEntryOnBeforeRoundAmtValueEntry(var ValueEntry: Record "Value Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitValueEntryOnAfterAssignFields(var ValueEntry: Record "Value Entry"; ItemLedgEntry: Record "Item Ledger Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitValueEntryOnAfterCalcInvoicedQuantityNotEmpty(var ItemJournalLine: Record "Item Journal Line"; var InvoicedQuantityNotEmpty: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitValueEntryOnAfterCalcDirestCost(var CostAmt: Decimal; var VarianceAmount: Decimal; Item: Record Item; ItemJournalLine: Record "Item Journal Line"; ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPostValueEntryToGLOnAfterTransferFields(var PostValueEntryToGL: Record "Post Value Entry to G/L"; ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTransferEntryOnTransferValues(var NewItemLedgerEntry: Record "Item Ledger Entry"; OldItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line"; var TempItemEntryRelation: Record "Item Entry Relation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertCapValueEntryOnAfterUpdateCostAmounts(var ValueEntry: Record "Value Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertConsumpEntryOnBeforePostItem(var ItemJournalLine: Record "Item Journal Line"; ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInsertOHValueEntryOnBeforeInsertValueEntry(var ValueEntry: Record "Value Entry"; ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean; var GlobalItemLedgEntry: Record "Item Ledger Entry"; var ValueEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemQtyPostingOnAfterCalcInsertItemLedgEntryNeeded(var ItemJournalLine: Record "Item Journal Line"; var InsertItemLedgEntryNeeded: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemQtyPostingOnBeforeApplyItemLedgEntry(var ItemJournalLine: Record "Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemValuePostingOnAfterInsertValueEntry(var ValueEntry: Record "Value Entry"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemValuePostingOnAfterCalcIsCostNotTracedDirectly(var ItemJnlLine: Record "Item Journal Line"; var IsCostNotTracedDirectly: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertItemLedgEntryOnBeforeReservationError(var ItemJournalLine: Record "Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean; Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertItemLedgEntryOnBeforeSNQtyCheck(ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertItemRegOnBeforeItemRegInsert(var ItemRegister: Record "Item Register"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValuateAppliedAvgEntryOnAfterSetCostPerUnit(var ValueEntry: Record "Value Entry"; ItemJournalLine: Record "Item Journal Line"; InventorySetup: Record "Inventory Setup"; SKU: Record "Stockkeeping Unit"; SKUExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValuateAppliedAvgEntryOnAfterUpdateCostAmounts(var ValueEntry: Record "Value Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostFlushedConsumpOnAfterCalcQtyToPost(ProductionOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderComponent: Record "Prod. Order Component"; ActOutputQtyBase: Decimal; var QtyToPost: Decimal; var OldItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostFlushedConsumpOnAfterCopyProdOrderFieldsToItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; var OldItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderComponent: Record "Prod. Order Component"; CompItem: record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostFlushedConsumptionOnBeforeCalcQtyToPost(ProdOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderComp: Record "Prod. Order Component"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; OldItemJnlLine: Record "Item Journal Line"; var OutputQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostFlushedConsumpOnBeforeProdOrderCompReserveTransferPOCompToItemJnlLine(ItemJournalLine: Record "Item Journal Line"; ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostFlushedConsumpOnBeforeSetupSplitJnlLine(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostFlushedConsumptionOnAfterSetDimensionSetID(ItemJournalLine: Record "Item Journal Line"; var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionOnAfterInsertEntry(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionOnAfterFindProdOrderComp(var ProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionOnAfterCalcNewRemainingQty(ProdOrderComponent: Record "Prod. Order Component"; VAR NewRemainingQuantity: Decimal; QtyToPost: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionOnBeforeCheckOrderType(var ProdOrderComponent: Record "Prod. Order Component"; var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionOnBeforeFindSetProdOrderComp(var ProdOrderComponent: Record "Prod. Order Component"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemOnAfterGetSKU(var ItemJnlLine: Record "Item Journal Line"; var SKUExists: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemOnBeforeCheckInventoryPostingGroup(var ItemJnlLine: Record "Item Journal Line"; var CalledFromAdjustment: Boolean; var Item: Record Item; var ItemTrackingCode: Record "Item Tracking Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemOnBeforeUpdateUnitCost(var ItemJnlLine: Record "Item Journal Line"; GlobalItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnAfterInsertCapLedgEntry(ItemJournalLine: Record "Item Journal Line"; var SkipPost: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnAfterInsertCostValueEntries(ItemJournalLine: Record "Item Journal Line"; var CapLedgEntry: Record "Capacity Ledger Entry"; CalledFromAdjustment: Boolean; PostToGL: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnAfterSetMfgUnitCost(var ItemJournalLine: Record "Item Journal Line"; var MfgUnitCost: Decimal; var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnAfterUpdateAmounts(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnAfterUpdateProdOrderLine(var ItemJournalLine: Record "Item Journal Line"; var WhseJnlLine: Record "Warehouse Journal Line"; var GlobalItemLedgEntry: Record "Item Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnBeforeUpdateProdOrderLine(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnAfterCreateWhseJnlLine(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnBeforeCreateWhseJnlLine(var ItemJournalLine: Record "Item Journal Line"; var PostWhseJnlLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnBeforePostItem(var ItemJournalLine: Record "Item Journal Line"; var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSplitJnlLineOnBeforeSplitJnlLine(var ItemJournalLine: Record "Item Journal Line"; var ItemJournalLineToPost: Record "Item Journal Line"; var PostItemJournalLine: Boolean; DisableItemTracking: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReApplyOnBeforeStartApply(var ItemLedgerEntry: Record "Item Ledger Entry"; var ItemLedgerEntry2: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReApplyOnBeforeGetItemTrackingSetup(var Item: Record Item; var ItemTrackingCode: Record "Item Tracking Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetOrderAdjmtPropertiesOnBeforeSetCostIsAdjusted(var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var ModifyOrderAdjmt: Boolean; var IsHandled: Boolean; OriginalPostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetOrderAdjmtPropertiesOnBeforeSetAllowOnlineAdjustment(var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var ModifyOrderAdjmt: Boolean; var IsHandled: Boolean; OriginalPostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetupSplitJnlLineOnBeforeReallocateTrkgSpecification(var ItemTrackingCode: Record "Item Tracking Code"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var ItemJnlLine: Record "Item Journal Line"; var SignFactor: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetupSplitJnlLineOnBeforeCalcNonDistrQuantity(var TempTrackingSpecification: Record "Tracking Specification" temporary; var ItemJournalLine: Record "Item Journal Line"; Invoice: Boolean; SignFactor: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitItemJnlLineOnBeforeTracking(
        var ItemJnlLine2: Record "Item Journal Line"; var PostItemJnlLine: Boolean; var TempTrackingSpecification: Record "Tracking Specification" temporary;
        var GlobalItemLedgEntry: Record "Item Ledger Entry"; var TempItemEntryRelation: Record "Item Entry Relation" temporary;
        var PostponeReservationHandling: Boolean; var SignFactor: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestFirstApplyItemLedgEntryOnAfterTestFields(ItemLedgerEntry: Record "Item Ledger Entry"; OldItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestFirstApplyItemLedgerEntryTracking(ItemLedgEntry: Record "Item Ledger Entry"; OldItemLedgEntry: Record "Item Ledger Entry"; ItemTrackingCode: Record "Item Tracking Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTouchItemEntryCostOnAfterAfterSetAdjmtProp(var ItemLedgerEntry: Record "Item Ledger Entry"; IsAdjustment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnApplyOnBeforeUpdateItemLedgerEntries(var ItemLedgerEntry1: Record "Item Ledger Entry"; var ItemLedgerEntry2: Record "Item Ledger Entry"; ItemApplnEntry: Record "Item Application Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnApplyOnBeforeItemApplnEntryDelete(var ItemApplicationEntry: Record "Item Application Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostOnBeforeCalculateLastDirectCost(var TotalAmount: Decimal; ItemJournalLine: Record "Item Journal Line"; ValueEntry: Record "Value Entry"; Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostOnBeforeUpdateUnitCost(ItemJournalLine: Record "Item Journal Line"; ValueEntry: Record "Value Entry"; Item: Record Item; var UpdateSKU: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostInventoryToGL(var ValueEntry: Record "Value Entry"; var IsHandled: Boolean; var ItemJnlLine: Record "Item Journal Line"; PostToGL: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostInventoryToGL(var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSplitJnlLineOnAfterCode(var ItemJournalLine: Record "Item Journal Line"; var ItemJournalLineToPost: Record "Item Journal Line"; var PostItemJournalLine: Boolean; var TempTrackingSpecification: Record "Tracking Specification" temporary; DisableItemTracking: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcCapQty(var ItemJnlLine: Record "Item Journal Line"; var CapQty: Decimal)
    begin
    end;

    procedure PrepareItem(var ItemJnlLineToPost: Record "Item Journal Line")
    begin
        ItemJnlLine.Copy(ItemJnlLineToPost);

        GetGLSetup();
        GetInvtSetup();
        CheckItem(ItemJnlLineToPost."Item No.");

        OnAfterPrepareItem(ItemJnlLineToPost);
    end;

    procedure SetSkipApplicationCheck(NewValue: Boolean)
    begin
        SkipApplicationCheck := NewValue;
    end;

    procedure LogApply(ApplyItemLedgEntry: Record "Item Ledger Entry"; AppliedItemLedgEntry: Record "Item Ledger Entry")
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        ItemApplnEntry.Init();
        if AppliedItemLedgEntry.Quantity > 0 then begin
            ItemApplnEntry."Item Ledger Entry No." := ApplyItemLedgEntry."Entry No.";
            ItemApplnEntry."Inbound Item Entry No." := AppliedItemLedgEntry."Entry No.";
            ItemApplnEntry."Outbound Item Entry No." := ApplyItemLedgEntry."Entry No.";
        end else begin
            ItemApplnEntry."Item Ledger Entry No." := AppliedItemLedgEntry."Entry No.";
            ItemApplnEntry."Inbound Item Entry No." := ApplyItemLedgEntry."Entry No.";
            ItemApplnEntry."Outbound Item Entry No." := AppliedItemLedgEntry."Entry No.";
        end;
        AddToApplicationLog(ItemApplnEntry, true);
    end;

    procedure LogUnapply(ItemApplnEntry: Record "Item Application Entry")
    begin
        AddToApplicationLog(ItemApplnEntry, false);
    end;

    local procedure AddToApplicationLog(ItemApplnEntry: Record "Item Application Entry"; IsApplication: Boolean)
    begin
        with TempItemApplnEntryHistory do begin
            if FindLast() then;
            "Primary Entry No." += 1;

            "Item Ledger Entry No." := ItemApplnEntry."Item Ledger Entry No.";
            "Inbound Item Entry No." := ItemApplnEntry."Inbound Item Entry No.";
            "Outbound Item Entry No." := ItemApplnEntry."Outbound Item Entry No.";

            "Cost Application" := IsApplication;
            Insert();
        end;
    end;

    procedure ClearApplicationLog()
    begin
        TempItemApplnEntryHistory.DeleteAll();
    end;

    procedure UndoApplications()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemApplnEntry: Record "Item Application Entry";
    begin
        with TempItemApplnEntryHistory do begin
            Ascending(false);
            if FindSet() then
                repeat
                    if "Cost Application" then begin
                        ItemApplnEntry.SetRange("Inbound Item Entry No.", "Inbound Item Entry No.");
                        ItemApplnEntry.SetRange("Outbound Item Entry No.", "Outbound Item Entry No.");
                        ItemApplnEntry.FindFirst();
                        UnApply(ItemApplnEntry);
                    end else begin
                        ItemLedgEntry.Get("Item Ledger Entry No.");
                        SetSkipApplicationCheck(true);
                        ReApply(ItemLedgEntry, "Inbound Item Entry No.");
                    end;
                until Next() = 0;
            ClearApplicationLog();
            Ascending(true);
        end;
    end;

    procedure ApplicationLogIsEmpty(): Boolean
    begin
        exit(TempItemApplnEntryHistory.IsEmpty);
    end;

    local procedure AppliedEntriesToReadjust(ItemLedgEntry: Record "Item Ledger Entry") Readjust: Boolean
    begin
        with ItemLedgEntry do
            Readjust := "Entry Type" in ["Entry Type"::Output, "Entry Type"::"Assembly Output"];

        OnAfterAppliedEntriesToReadjust(ItemLedgEntry, Readjust);
    end;

    local procedure GetTextStringWithLineNo(BasicTextString: Text; ItemNo: Code[20]; LineNo: Integer): Text
    begin
        if LineNo = 0 then
            exit(StrSubstNo(BasicTextString, ItemNo));
        exit(StrSubstNo(BasicTextString, ItemNo) + StrSubstNo(LineNoTxt, LineNo));
    end;

    procedure GetCalledFromAdjustment(): Boolean
    begin
        exit(CalledFromAdjustment);
    end;

    procedure SetCalledFromApplicationWorksheet(IsCalledFromApplicationWorksheet: Boolean)
    begin
        CalledFromApplicationWorksheet := IsCalledFromApplicationWorksheet;
    end;

    local procedure SaveTouchedEntry(ItemLedgerEntryNo: Integer; IsInbound: Boolean)
    var
        ItemApplicationEntryHistory: Record "Item Application Entry History";
        NextEntryNo: Integer;
    begin
        if not CalledFromApplicationWorksheet then
            exit;

        with ItemApplicationEntryHistory do begin
            NextEntryNo := GetLastEntryNo() + 1;

            Init();
            "Primary Entry No." := NextEntryNo;
            "Entry No." := 0;
            "Item Ledger Entry No." := ItemLedgerEntryNo;
            if IsInbound then
                "Inbound Item Entry No." := ItemLedgerEntryNo
            else
                "Outbound Item Entry No." := ItemLedgerEntryNo;
            "Creation Date" := CurrentDateTime;
            "Created By User" := UserId;
            Insert();
        end;
    end;

    procedure RestoreTouchedEntries(var TempItem: Record Item temporary)
    var
        ItemApplicationEntryHistory: Record "Item Application Entry History";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        with ItemApplicationEntryHistory do begin
            SetRange("Entry No.", 0);
            SetRange("Created By User", UpperCase(UserId));
            if FindSet() then
                repeat
                    TouchEntry("Item Ledger Entry No.");

                    ItemLedgerEntry.Get("Item Ledger Entry No.");
                    TempItem."No." := ItemLedgerEntry."Item No.";
                    if TempItem.Insert() then;
                until Next() = 0;
        end;
    end;

    local procedure DeleteTouchedEntries()
    var
        ItemApplicationEntryHistory: Record "Item Application Entry History";
    begin
        if not CalledFromApplicationWorksheet then
            exit;

        with ItemApplicationEntryHistory do begin
            SetRange("Entry No.", 0);
            SetRange("Created By User", UpperCase(UserId));
            DeleteAll();
        end;
    end;

    local procedure VerifyItemJnlLineAsembleToOrder(var ItemJournalLine: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyItemJnlLineAsembleToOrder(ItemJournalLine, IsHandled);
        if IsHandled then
            exit;

        ItemJournalLine.TestField("Applies-to Entry");

        ItemJournalLine.CalcFields("Reserved Qty. (Base)");
        ItemJournalLine.TestField("Reserved Qty. (Base)");
    end;

    local procedure VerifyItemJnlLineApplication(var ItemJournalLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        if ItemJournalLine."Applies-to Entry" = 0 then
            exit;

        ItemJournalLine.CalcFields("Reserved Qty. (Base)");
        if ItemJournalLine."Reserved Qty. (Base)" <> 0 then
            ItemLedgerEntry.FieldError("Applies-to Entry", Text99000000);
    end;

    local procedure GetCombinedDimSetID(DimSetID1: Integer; DimSetID2: Integer): Integer
    var
        DimMgt: Codeunit DimensionManagement;
        DummyGlobalDimCode: array[2] of Code[20];
        DimID: array[10] of Integer;
    begin
        DimID[1] := DimSetID1;
        DimID[2] := DimSetID2;
        exit(DimMgt.GetCombinedDimensionSetID(DimID, DummyGlobalDimCode[1], DummyGlobalDimCode[2]));
    end;

    local procedure CalcILEExpectedAmount(var OldValueEntry: Record "Value Entry"; ItemLedgerEntryNo: Integer)
    var
        OldValueEntry2: Record "Value Entry";
    begin
        OldValueEntry.FindFirstValueEntryByItemLedgerEntryNo(ItemLedgerEntryNo);
        OldValueEntry2.Copy(OldValueEntry);
        OldValueEntry2.SetFilter("Entry No.", '<>%1', OldValueEntry."Entry No.");
        OnCalcILEExpectedAmountOnBeforeCalcCostAmounts(OldValueEntry2, OldValueEntry, ItemLedgEntryNo);
        OldValueEntry2.CalcSums("Cost Amount (Expected)", "Cost Amount (Expected) (ACY)");
        OldValueEntry."Cost Amount (Expected)" += OldValueEntry2."Cost Amount (Expected)";
        OldValueEntry."Cost Amount (Expected) (ACY)" += OldValueEntry2."Cost Amount (Expected) (ACY)";
    end;

    local procedure FindOpenOutputEntryNoToApply(ItemJournalLine: Record "Item Journal Line"): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if not ItemJournalLine.TrackingExists() then
            exit(0);

        with ItemLedgerEntry do begin
            SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type", "Prod. Order Comp. Line No.");
            SetRange("Order Type", "Order Type"::Production);
            SetRange("Order No.", ItemJournalLine."Order No.");
            SetRange("Order Line No.", ItemJournalLine."Order Line No.");
            SetRange("Entry Type", "Entry Type"::Output);
            SetRange("Prod. Order Comp. Line No.", 0);
            SetRange("Item No.", ItemJournalLine."Item No.");
            SetRange("Location Code", ItemJournalLine."Location Code");
            SetTrackingFilterFromItemJournalLine(ItemJournalLine);
            SetRange(Positive, true);
            SetRange(Open, true);
            SetFilter("Remaining Quantity", '>=%1', -ItemJournalLine."Output Quantity (Base)");
            if not IsEmpty() then
                if Count = 1 then begin
                    FindFirst();
                    exit("Entry No.");
                end;
        end;

        exit(0);
    end;

    local procedure ExpectedCostPosted(ValueEntry: Record "Value Entry"): Boolean
    var
        PostedExpCostValueEntry: Record "Value Entry";
    begin
        with ValueEntry do begin
            if not Adjustment or ("Applies-to Entry" = 0) then
                exit(false);
            PostedExpCostValueEntry.SetRange("Item Ledger Entry No.", "Item Ledger Entry No.");
            PostedExpCostValueEntry.SetRange("Applies-to Entry", "Applies-to Entry");
            PostedExpCostValueEntry.SetRange("Expected Cost", true);
            exit(not PostedExpCostValueEntry.IsEmpty);
        end;
    end;

    procedure SetSkipSerialNoQtyValidation(NewSkipSerialNoQtyValidation: Boolean)
    begin
        SkipSerialNoQtyValidation := NewSkipSerialNoQtyValidation;
    end;

    local procedure CheckInvoicedQuantity(ItemLedgEntry: Record "Item Ledger Entry"; ValueEntry: Record "Value Entry"; var ModifyEntry: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckInvoicedQuantity(ItemLedgEntry, ValueEntry, ModifyEntry, IsHandled);
        if IsHandled then
            exit;

        if Abs(ItemLedgEntry."Invoiced Quantity") > Abs(ItemLedgEntry.Quantity) then
            Error(Text030, ItemLedgEntry."Entry No.");
        VerifyInvoicedQty(ItemLedgEntry, ValueEntry);
        ModifyEntry := true;
    end;

    local procedure ShowFixedApplicationError()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowFixedApplicationError(IsHandled);
        if IsHandled then
            exit;

        Error(Text027);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyInvoicedQtyOnAfterGetSalesShipmentHeader(ItemLedgEntry2: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAppliedFromValues(var ValueEntry: Record "Value Entry"; NegValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertPhysInventoryEntry(var PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertPostValueEntryToGL(ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsPostToGL(ValueEntry: Record "Value Entry"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckItemTrackingOfComp(TempHandlingSpecification: Record "Tracking Specification"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetOutputProdOrder(var ProdOrder: Record "Production Order"; ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetOutputProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; OrderNo: Code[20]; OrderLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; OldItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsNotInternalWhseMovement(ItemJnlLine: Record "Item Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsInterimRevaluation(ItemJnlLine: Record "Item Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPostingDateWithExpirationDate(var ItemLedgEntry: Record "Item Ledger Entry"; ItemTrackingCode: Record "Item Tracking Code"; OldItemLedgEntry: Record "Item Ledger Entry"; var IsHandled: Boolean; var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemValuePosting(ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostOutput(var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostOutputUpdateProdOrderRtngLine(var ProdOrderRtngLine: Record "Prod. Order Routing Line"; ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCapLedgerEntriesSetupRunTimeOnAfterCapLedgerEntrySetFilters(var CapLedgerEntry: Record "Capacity Ledger Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckExpirationDateOnAfterCalcSumLot(var SumLot: Decimal; SignFactor: Integer; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckExpirationDateOnBeforeAssignExpirationDate(var TempTrackingSpecification: Record "Tracking Specification" temporary; ExistingExpirationDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitItemJnlLineOnBeforeInsertTempTrkgSpecification(var TempTrackingSpecification: Record "Tracking Specification" temporary; ItemJnlLine2: Record "Item Journal Line"; SignFactor: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitTransValueEntryOnBeforeCalcCostAmounts(GlobalValueEntry: Record "Value Entry"; var ValueEntry: Record "Value Entry"; ItemTrackingSetup: Record "Item Tracking Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertValueEntryOnBeforeCalcExpectedCost(var ItemJnlLine: Record "Item Journal Line"; var ItemLedgEntry: Record "Item Ledger Entry"; var ValueEntry: Record "Value Entry"; TransferItemPBln: Boolean; var InventoryPostingToGL: Codeunit "Inventory Posting To G/L"; var ShouldCalcExpectedCost: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertValueEntryOnBeforeRoundAmtValueEntry(var ValueEntry: Record "Value Entry"; var ItemLedgEntry: Record "Item Ledger Entry"; ItemJnlLine: Record "Item Journal Line"; TransferItem: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertVarValueEntryOnAfterInitValueEntryFields(var ValueEntry: record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertItemLedgEntryOnBeforeVerifyOnInventory(ItemJnlLine: Record "Item Journal Line"; ItemLedgEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertItemLedgEntryOnCheckItemTracking(ItemJnlLine: Record "Item Journal Line"; ItemLedgEntry: Record "Item Ledger Entry"; ItemTrackingCode: Record "Item Tracking Code"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertCapValueEntryOnAfterUpdateCapLedgEntry(var ValueEntry: Record "Value Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertCapValueEntryOnAfterInsertValueEntryRelation(var ValueEntry: Record "Value Entry"; ItemJnlLine: Record "Item Journal Line"; var TempValueEntryRelation: Record "Value Entry Relation" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemOnBeforeGetGlobalLedgerEntry(ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecalculateCostPerUnit(var ValueEntry: Record "Value Entry"; ItemJnlLine: Record "Item Journal Line"; var ItemLedgEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetCalledFromAdjustment(CalledFromAdjustment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTransferEntryOnBeforeInitTransValueEntry(var TempItemEntryRelation: Record "Item Entry Relation"; var NewItemLedgEntry: Record "Item Ledger Entry"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitCorrItemLedgEntryOnAfterRetrieveAppliedExpirationDate(var NewItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitItemJnlLineOnBeforePostItemJnlLine(var TempTrackingSpecification: Record "Tracking Specification"; var GlobalItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertValueEntryOnAfterTempValueEntryRelationInsert(var ValueEntry: Record "Value Entry"; ItemJnlLine: Record "Item Journal Line"; var TempValueEntryRelation: Record "Value Entry Relation");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostOnAfterAssignLastDirectCost(var ValueEntry: Record "Value Entry"; var Item: Record Item; LastDirectCost: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemQtyPostingOnAfterInsertApplEntry(var ItemJnlLine: Record "Item Journal Line"; var TempSplitItemJnlLine: Record "Item Journal Line" temporary; var GlobalItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemQtyPostingOnBeforeInsertApplEntry(var GlobalItemLedgEntry: Record "Item Ledger Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnApplyOnBeforeInsertApplEntry(var ItemApplnEntry: Record "Item Application Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCostApplyOnBeforeInsertApplEntry(var GlobalItemLedgEntry: Record "Item Ledger Entry"; var ApplyWithItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnItemLedgEntryPositiveOnBeforeInsertApplEntry(var OldItemLedgEntry: Record "Item Ledger Entry"; var ItemLedgEntry: Record "Item Ledger Entry"; var GlobalItemLedgEntry: Record "Item Ledger Entry"; var AppliedQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTransferEntryOnBeforeInsertApplEntry(var NewItemLedgEntry: Record "Item Ledger Entry"; var ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertApplEntryOnBeforeModify(var ItemApplicationEntry: Record "Item Application Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoQuantityPostingOnBeforeInitCorrItemLedgEntry(var ItemJnlLine: Record "Item Journal Line"; var OldItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoQuantityPostingOnAfterInitCorrItemLedgEntry(var OldItemLedgEntry: Record "Item Ledger Entry"; var NewItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoQuantityPostingOnAfterUpdateItemApplnEntry(var ItemJnlLine: Record "Item Journal Line"; OldItemLedgEntry: Record "Item Ledger Entry"; NewItemLedgEntry: Record "Item Ledger Entry"; NewValueEntry: Record "Value Entry"; InventoryPostingToGL: Codeunit "Inventory Posting To G/L")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoQuantityPostingOnBeforeUpdateOldItemLedgEntry(var OldValueEntry2: Record "Value Entry"; var NewItemLedgEntry: Record "Item Ledger Entry"; var NewValueEntry: Record "Value Entry"; var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoQuantityPostingOnBeforeInsertApplEntry(var NewItemLedgEntry: Record "Item Ledger Entry"; var OldItemLedgEntry: Record "Item Ledger Entry"; var GlobalItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupSplitJnlLine(var ItemJnlLine2: Record "Item Journal Line"; var TempSplitItemJnlLine: Record "Item Journal Line"; var ItemJnlLineOrigin: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification"; TrackingSpecExists: Boolean; CalledFromAdjustment: Boolean; PostponeReservationHandling: Boolean; var PostItemJnlLine: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnBeforeFirstReservationSetFilters(var ItemJnlLine: Record "Item Journal Line"; var StartApplication: Boolean; FirstReservation: Boolean; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnBeforeCloseSurplusTrackingEntry(ItemJnlLine: Record "Item Journal Line"; var StartApplication: Boolean; var UseReservationApplication: Boolean; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPhysInventoryEntry(var ItemJnlLineOrigin: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnItemValuePostingOnBeforeInsertOHValueEntry(var ItemJnlLine: Record "Item Journal Line"; var GlobalValueEntry: Record "Value Entry"; var GlobalItemLedgEntry: Record "Item Ledger Entry"; var ValueEntryNo: Integer; var IsHandled: Boolean; var VarianceAmount: Decimal; var VarianceAmountACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionOnBeforeCalcRemQtyToPostThisLine(var ProdOrderComp: Record "Prod. Order Component"; var ItemJnlLine: Record "Item Journal Line"; var TempHandlingSpecification: Record "Tracking Specification"; RemQtyToPost: Decimal; UseItemTrackingApplication: Boolean; LastLoop: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionOnBeforeCalcRemainingQuantity(var ProdOrderComp: Record "Prod. Order Component"; var ItemJnlLine: Record "Item Journal Line"; var NewRemainingQty: Decimal; var QtyToPost: Decimal; var IsHandled: Boolean; var RemQtyToPost: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionOnRemQtyToPostOnBeforeInsertConsumpEntry(var ItemJnlLine: Record "Item Journal Line"; var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetItemAdjmtPropertiesOnBeforeCheckModifyItem(var Item2: Record Item; var ModifyItem: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetupTempSplitItemJnlLineOnAfterCalcPostItemJnlLine(var TempSplitItemJnlLine: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var PostItemJnlLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeCheckItemTracking(var ItemJnlLine: Record "Item Journal Line"; DisableItemTracking: Boolean; var IsHandled: Boolean; var TempTrackingSpecification: Record "Tracking Specification"; var ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckInvoicedQuantity(ItemLedgEntry: Record "Item Ledger Entry"; ValueEntry: Record "Value Entry"; var ModifyEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateOrigAppliedFromEntryOnItemApplEntryLoop(var ItemLedgEntry: Record "Item Ledger Entry"; ItemApplEntry: Record "Item Application Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemLedgEntryOnBeforeUpdateOutboundItemLedgEntry(ValueEntry: Record "Value Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnApplicationLoop(var ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemOnBeforeSetAverageTransfer(var ItemJnlLine: Record "Item Journal Line"; CalledFromAdjustment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTouchItemEntryCost(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJnlLine: Record "Item Journal Line"; IsAdjustment: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUnApply(var ItemApplnEntry: Record "Item Application Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetupSplitJnlLineProcedure(var ItemJnlLine2: Record "Item Journal Line"; TrackingSpecExists: Boolean; CalledFromAdjustment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowFixedApplicationError(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemOnBeforeTransferReservFromJobPlanningLine(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean; var AverageTransfer: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunWithCheckOnAfterRetrieveItemTracking(var ItemJournalLine: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification"; var TrackingSpecExists: Boolean; PostponeReservationHandling: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemTrackingOnAfterCheckRequiredTrackingNos(ItemJournalLine: Record "Item Journal Line"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertCapValueEntryOnBeforeInventoryPostingToGL(ValueEntry: Record "Value Entry"; var IsHandled: Boolean; PostToGL: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostOutputForProdOrder(var ItemJnlLine: Record "Item Journal Line"; var LastOperation: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemOnAfterCheckCostingMethodStandard(var Item: Record Item; var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateLinkedValuationDate(GlobalItemLedgEntry: Record "Item Ledger Entry"; FromItemledgEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostInventoryToGLOnAfterPostInvtBuffer(var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeTestOrder(ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostInvtBufferOnAfterBufferInvtPosting(var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCalcQtyPerUnitOfMeasure(ItemJnlLine: Record "Item Journal Line"; Subcontracting: Boolean; var QtyPerUnitOfMeasure: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertValueEntryOnBeforeInsertPostValueEntryToGL(var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemQtyPostingOnAfterInsertTransferEntry(var ItemJnlLine: Record "Item Journal Line"; AverageTransfer: Boolean; GlobalItemLedgEntry: Record "Item Ledger Entry"; OldItemLedgEntry: Record "Item Ledger Entry"; TotalAppliedQty: Decimal; var TempItemEntryRelation: Record "Item Entry Relation"; var GlobalValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertValueEntryOnAfterInsertPostValueEntryToGL(var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateValuationDate(GlobalItemLedgEntry: Record "Item Ledger Entry"; FromItemLedgEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeSetQuantity(var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemTrackingInformationOnBeforeTestFields(ItemTrackingSetup: Record "Item Tracking Setup"; TrackingSpecification: Record "Tracking Specification"; ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostInventoryToGLOnBeforePostInvtBuffer(var InventoryPostingToGL: Codeunit "Inventory Posting To G/L"; PostToGL: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTransferEntryOnBeforeCalcIsReserved(ItemJnlLine: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification"; NewItemLedgEntry: Record "Item Ledger Entry"; ItemLedgEntry: Record "Item Ledger Entry"; var IsReserved: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetupTempSplitItemJnlLineOnBeforeCalcPostItemJnlLine(var TempSplitItemJnlLine: Record "Item Journal Line"; TempTrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeRunCheck(var ItemJnlCheckLine: Codeunit "Item Jnl.-Check Line"; var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoQuantityPostingOnBeforeInsertCorrOldItemLedgEntry(OldItemLedgEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReservationExists(ItemJnlLine: Record "Item Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoQuantityPostingOnAfterCalcShouldInsertCorrValueEntry(OldItemLedgEntry: Record "Item Ledger Entry"; var ShouldInsertCorrValueEntries: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnBeforeGetMfgAmounts(var ItemJnlLine: Record "Item Journal Line"; ProdOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAvgCostAdjmtBufferOnAfterSetValueEntry(var ValueEntry: Record "Value Entry"; OldItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetGeneralPostingSetup(ItemJournalLine: Record "Item Journal Line"; var GeneralPostingSetup: Record "General Posting Setup"; PostToGl: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemOnAfterGetItem(Item: Record Item; ItemJnlLine: Record "Item Journal Line"; CalledFromAdjustment: Boolean)
    begin
    end;
}

