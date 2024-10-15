﻿namespace Microsoft.Inventory.Costing;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Period;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Setup;
using Microsoft.Purchases.History;
using System.Telemetry;
using System.Utilities;

codeunit 5895 "Inventory Adjustment" implements "Inventory Adjustment"
{
    Permissions = TableData Item = rm,
                  TableData "Item Ledger Entry" = rm,
                  TableData "Item Application Entry" = rimd,
                  TableData "Value Entry" = rim,
                  TableData "Avg. Cost Adjmt. Entry Point" = rimd,
                  TableData "Inventory Adjmt. Entry (Order)" = rm;

    trigger OnRun()
    begin
    end;

    var
        Item: Record Item;
        FilterItem: Record Item;
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        InvtSetup: Record "Inventory Setup";
        SourceCodeSetup: Record "Source Code Setup";
        TempInvtAdjmtBuf: Record "Inventory Adjustment Buffer" temporary;
        TempRndgResidualBuf: Record "Rounding Residual Buffer" temporary;
        TempItemLedgerEntryBuf: Record "Item Ledger Entry" temporary;
        TempAvgCostExceptionBuf: Record "Integer" temporary;
        AvgCostBuf: Record "Cost Element Buffer";
        TempAvgCostRndgBuf: Record "Rounding Residual Buffer" temporary;
        TempRevaluationPoint: Record "Integer" temporary;
        TempFixApplBuffer: Record "Integer" temporary;
        TempOpenItemLedgEntry: Record "Integer" temporary;
        TempJobToAdjustBuf: Record Job temporary;
        TempValueEntryCalcdOutbndCostBuf: Record "Value Entry" temporary;
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        CostCalcMgt: Codeunit "Cost Calculation Management";
        ItemCostMgt: Codeunit ItemCostManagement;
        FeatureTelemetry: Codeunit "Feature Telemetry";
        Window: Dialog;
        ItemApplicationChain: Dictionary of [Integer, List of [Integer]];
        ItemLedgerEntryTypesUsed: Dictionary of [Enum "Item Ledger Entry Type", Boolean];
        WindowUpdateDateTime: DateTime;
        PostingDateForClosedPeriod: Date;
        LevelNo: array[3] of Integer;
        MaxLevels: Integer;
        MaxRoundings: Integer;
        LevelExceeded: Boolean;
        IsDeletedItem: Boolean;
        IsOnlineAdjmt: Boolean;
        PostToGL: Boolean;
        SkipUpdateJobItemCost: Boolean;
        WindowIsOpen: Boolean;
        WindowAdjmtLevel: Integer;
        WindowItem: Code[20];
        WindowAdjust: Text[20];
        WindowFWLevel: Integer;
        WindowEntry: Integer;
        IsAvgCostCalcTypeItem: Boolean;
        WindowOutbndEntry: Integer;
        ConsumpAdjmtInPeriodWithOutput: Date;
        AutomaticCostAdjustmentTok: Label 'Automatic cost adjustment', Locked = true;
        AutomaticCostAdjustmentEnabledTok: Label 'Automatic cost adjustment was used.', Locked = true;
        Text009: Label 'WIP';
        Text010: Label 'Assembly';
        Text000: Label 'Adjusting value entries...\\';
        Text001: Label 'Adjmt. Level      #2######\';
        Text002: Label '%1 %2';
        Text003: Label 'Adjust            #3######\';
        Text004: Label 'Cost FW. Level    #4######\';
        Text005: Label 'Entry No.         #5######\';
        Text006: Label 'Remaining Entries #6######';
        Text007: Label 'Applied cost';
        Text008: Label 'Average cost';

    procedure SetProperties(NewIsOnlineAdjmt: Boolean; NewPostToGL: Boolean)
    begin
        IsOnlineAdjmt := NewIsOnlineAdjmt;
        PostToGL := NewPostToGL;
    end;

    procedure SetFilterItem(var NewItem: Record Item)
    begin
        FilterItem.CopyFilters(NewItem);
    end;

    procedure MakeMultiLevelAdjmt()
    var
        TempItem: Record Item temporary;
        TempInventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)" temporary;
        TempAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point" temporary;
        IsFirstTime: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMakeMultiLevelAdjmt(FilterItem, IsOnlineAdjmt, PostToGL, IsHandled);
        if IsHandled then
            exit;

        InitializeAdjmt();

        IsFirstTime := true;
        while (InvtToAdjustExist(TempItem) or IsFirstTime) and not LevelExceeded do begin
            // items adjustment
            MakeSingleLevelAdjmt(TempItem, TempAvgCostAdjmtEntryPoint);

            // assembly orders adjustment
            if AssemblyToAdjustExists(TempInventoryAdjmtEntryOrder) then
                MakeAssemblyAdjmt(TempInventoryAdjmtEntryOrder, TempAvgCostAdjmtEntryPoint);

            // production orders adjustment
            if WIPToAdjustExist(TempInventoryAdjmtEntryOrder) then
                MakeWIPAdjmt(TempInventoryAdjmtEntryOrder, TempAvgCostAdjmtEntryPoint);

            OnMakeMultiLevelAdjmtOnAfterMakeAdjmt(
              TempAvgCostAdjmtEntryPoint, FilterItem, TempRndgResidualBuf, IsOnlineAdjmt, PostToGL, ItemJnlPostLine);
            IsFirstTime := false;
        end;

        // if any item entries remain not adjusted, mark them for the next run
        SetAppliedEntryToAdjustFromBuf('');

        FinalizeAdjmt();
        UpdateJobItemCost();

        OnAfterMakeMultiLevelAdjmt(TempItem, IsOnlineAdjmt, PostToGL, FilterItem);
    end;

    local procedure InitializeAdjmt()
    begin
        Clear(LevelNo);
        MaxLevels := 100;
        MaxRoundings := 20;
        WindowUpdateDateTime := CurrentDateTime;
        if not IsOnlineAdjmt then
            OpenWindow();

        Clear(ItemJnlPostLine);
        ItemJnlPostLine.SetCalledFromAdjustment(true, PostToGL);

        InvtSetup.Get();
        if InvtSetup.AutomaticCostAdjmtRequired() then
            FeatureTelemetry.LogUsage('0000MEM', AutomaticCostAdjustmentTok, AutomaticCostAdjustmentEnabledTok);
        GLSetup.Get();
        PostingDateForClosedPeriod := GLSetup.FirstAllowedPostingDate();
        OnInitializeAdjmtOnAfterGetPostingDate(PostingDateForClosedPeriod);

        GetAddReportingCurrency();

        SourceCodeSetup.Get();

        ItemCostMgt.SetProperties(true, 0);
        TempJobToAdjustBuf.DeleteAll();
    end;

    local procedure FinalizeAdjmt()
    begin
        Clear(ItemJnlPostLine);
        Clear(CostCalcMgt);
        Clear(ItemCostMgt);
        TempAvgCostRndgBuf.DeleteAll();
        if WindowIsOpen then
            Window.Close();
        WindowIsOpen := false;
    end;

    local procedure GetAddReportingCurrency()
    begin
        if GLSetup."Additional Reporting Currency" <> '' then begin
            Currency.Get(GLSetup."Additional Reporting Currency");
            Currency.CheckAmountRoundingPrecision();
        end;
    end;

    local procedure InvtToAdjustExist(var ToItem: Record Item): Boolean
    var
        Item: Record Item;
    begin
        Item.Reset();
        Item.CopyFilters(FilterItem);
        if Item.GetFilter("No.") = '' then
            Item.SetCurrentKey("Cost is Adjusted", "Allow Online Adjustment");
        Item.SetRange("Cost is Adjusted", false);
        if IsOnlineAdjmt then
            Item.SetRange("Allow Online Adjustment", true);
        Item.SetRange("Excluded from Cost Adjustment", false);

        OnInvtToAdjustExistOnBeforeCopyItemToItem(Item);
        CopyItemToItem(Item, ToItem);

        if EntriesForDeletedItemsExist() then
            InsertDeletedItem(ToItem);

        exit(not ToItem.IsEmpty());
    end;

    local procedure MakeSingleLevelAdjmt(var TheItem: Record Item; var TempAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point" temporary)
    var
        IsFirstTime: Boolean;
        IsHandled: Boolean;
        xUnitCost: Decimal;
    begin
        IsHandled := false;
        OnBeforeMakeSingleLevelAdjmt(TheItem, TempAvgCostAdjmtEntryPoint, IsHandled);
        if IsHandled then
            exit;

        LevelNo[1] := LevelNo[1] + 1;

        UpDateWindow(LevelNo[1], WindowItem, WindowAdjust, WindowFWLevel, WindowEntry, 0);

        ConsumpAdjmtInPeriodWithOutput := 0D;

        TheItem.SetCurrentKey("Low-Level Code");
        if TheItem.FindLast() then
            TheItem.SetRange("Low-Level Code", TheItem."Low-Level Code");

        if TheItem.FindSet() then
            repeat
                OnBeforeAdjustItem(TheItem);

                Item := TheItem;
                GetItem(Item."No.");
                xUnitCost := Item."Unit Cost";
                UpDateWindow(WindowAdjmtLevel, Item."No.", WindowAdjust, WindowFWLevel, WindowEntry, 0);

                CollectItemLedgerEntryTypesUsed(Item."No.");

                OnMakeSingleLevelAdjmtOnBeforeCollectAvgCostAdjmtEntryPointToUpdate(TheItem);
                CollectAvgCostAdjmtEntryPointToUpdate(TempAvgCostAdjmtEntryPoint, TheItem."No.");
                IsFirstTime := not AppliedEntryToAdjustBufExists(TheItem."No.");

                // adjustment of applied entries
                repeat
                    LevelExceeded := false;
                    OnMakeSingleLevelAdjmtOnAfterLevelExceeded(Item);
                    AdjustItemAppliedCost();
                until not LevelExceeded;

                // adjustment of average cost items
                AdjustItemAvgCost();

                // post new value entries
                IsHandled := false;
                OnMakeSingleLevelAdjmtOnBeforePostAdjmtBuf(Item, TempAvgCostAdjmtEntryPoint, TempInvtAdjmtBuf, TempAvgCostRndgBuf, PostingDateForClosedPeriod, Currency, SkipUpdateJobItemCost, TempJobToAdjustBuf, ItemJnlPostLine, IsHandled);
                if not IsHandled then
                    PostAdjmtBuf(TempAvgCostAdjmtEntryPoint);

                // update unit cost on item card
                UpdateItemUnitCost(TempAvgCostAdjmtEntryPoint, IsFirstTime);
                if xUnitCost <> Item."Unit Cost" then
                    ItemCostMgt.UpdateCostPlusPrices(Item."No.");
                OnMakeSingleLevelAdjmtOnAfterUpdateItemUnitCost(TheItem, TempAvgCostAdjmtEntryPoint, LevelExceeded, IsOnlineAdjmt, ItemJnlPostLine);

                OnAfterAdjustItem(TheItem);
            until (TheItem.Next() = 0) or LevelExceeded;
    end;

    local procedure AdjustItemAppliedCost()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        AppliedQty: Decimal;
    begin
        UpDateWindow(WindowAdjmtLevel, WindowItem, Text007, WindowFWLevel, WindowEntry, 0);

        TempValueEntryCalcdOutbndCostBuf.Reset();
        TempValueEntryCalcdOutbndCostBuf.DeleteAll();

        ItemLedgEntry.SetCurrentKey("Item No.", "Applied Entry to Adjust");
        ItemLedgEntry.SetRange("Item No.", Item."No.");
        ItemLedgEntry.SetRange("Applied Entry to Adjust", true);
        if not ItemLedgEntry.FindSet() then
            exit;

        OnBeforeCopyILEToILE(Item, ItemLedgEntry);
        repeat
            UpDateWindow(WindowAdjmtLevel, WindowItem, WindowAdjust, WindowFWLevel, ItemLedgEntry."Entry No.", 0);

            TempRndgResidualBuf.AddAdjustedCost(ItemLedgEntry."Entry No.", 0, 0, ItemLedgEntry."Completely Invoiced");

            AppliedQty := ForwardAppliedCost(ItemLedgEntry, false);

            // post value entry of "Rounding" type when the inbound entry is fully applied and its cost is not sharply equal to the cost of outbounds entries
            EliminateRndgResidual(ItemLedgEntry, AppliedQty);
        until (ItemLedgEntry.Next() = 0) or LevelExceeded;
    end;

    local procedure ForwardAppliedCost(ItemLedgEntry: Record "Item Ledger Entry"; Recursion: Boolean) AppliedQty: Decimal
    var
        AppliedEntryToAdjust: Boolean;
    begin
        // Avoid stack overflow, if too many recursions
        if Recursion then
            LevelNo[3] := LevelNo[3] + 1
        else
            LevelNo[3] := 0;

        if LevelNo[3] = MaxLevels then begin
            ItemLedgEntry.SetAppliedEntryToAdjust(true);
            LevelExceeded := true;
            LevelNo[3] := 0;
            exit;
        end;

        OnForwardAppliedCostOnBeforeUpdateWindow(ItemLedgEntry, Item);
        UpDateWindow(WindowAdjmtLevel, WindowItem, WindowAdjust, LevelNo[3], WindowEntry, 0);

        AppliedQty := ForwardCostToOutbndEntries(ItemLedgEntry, Recursion, AppliedEntryToAdjust);
        OnForwardAppliedCostOnAfterSetAppliedQty(ItemLedgEntry, AppliedQty);

        ForwardCostToInbndTransEntries(ItemLedgEntry."Entry No.", Recursion);

        ForwardCostToInbndEntries(ItemLedgEntry."Entry No.");

        if OutboundSalesEntryToAdjust(ItemLedgEntry) or
           InboundTransferEntryToAdjust(ItemLedgEntry)
        then
            AppliedEntryToAdjust := true;

        if not ItemLedgEntry.IsOutbndConsump() and AppliedEntryToAdjust then
            UpdateAppliedEntryToAdjustBuf(ItemLedgEntry, AppliedEntryToAdjust);

        ItemLedgEntry.SetAppliedEntryToAdjust(false);
    end;

    local procedure ForwardAppliedCostRecursion(ItemLedgEntry: Record "Item Ledger Entry")
    var
        ValueEntry: Record "Value Entry";
        ItemApplicationEntry: Record "Item Application Entry";
        CostAmt: Decimal;
        CostAmtACY: Decimal;
        AppliedQty: Decimal;
        AppliedCostAmt: Decimal;
        AppliedCostAmtACY: Decimal;
    begin
        if not ItemLedgEntry."Applied Entry to Adjust" then begin
            AppliedQty := ForwardAppliedCost(ItemLedgEntry, true);

            if IsRndgAllowed(ItemLedgEntry, AppliedQty) then begin
                TempInvtAdjmtBuf.CalcItemLedgEntryCost(ItemLedgEntry."Entry No.", false);
                ValueEntry.CalcItemLedgEntryCost(ItemLedgEntry."Entry No.", false);
                ValueEntry.AddCost(TempInvtAdjmtBuf);
                CostAmt := ValueEntry."Cost Amount (Actual)";
                CostAmtACY := ValueEntry."Cost Amount (Actual) (ACY)";

                if ItemApplicationEntry.AppliedOutbndEntryExists(ItemLedgEntry."Entry No.", true, false) then begin
                    repeat
                        TempInvtAdjmtBuf.CalcItemLedgEntryCost(ItemApplicationEntry."Item Ledger Entry No.", false);
                        ValueEntry.CalcItemLedgEntryCost(ItemApplicationEntry."Item Ledger Entry No.", false);
                        ValueEntry.AddCost(TempInvtAdjmtBuf);
                        AppliedCostAmt -= ValueEntry."Cost Amount (Actual)";
                        AppliedCostAmtACY -= ValueEntry."Cost Amount (Actual)";
                    until ItemApplicationEntry.Next() = 0;

                    if (Abs(CostAmt - AppliedCostAmt) = GLSetup."Amount Rounding Precision") or
                       (Abs(CostAmtACY - AppliedCostAmtACY) = Currency."Amount Rounding Precision")
                    then
                        UpdateAppliedEntryToAdjustBuf(ItemLedgEntry, true);
                end;
            end;

            if LevelNo[3] > 0 then
                LevelNo[3] := LevelNo[3] - 1;
        end;
    end;

    local procedure ForwardCostToOutbndEntries(ItemLedgEntry: Record "Item Ledger Entry"; Recursion: Boolean; var AppliedEntryToAdjust: Boolean) AppliedQty: Decimal
    var
        ItemApplnEntry: Record "Item Application Entry";
        InboundCompletelyInvoiced: Boolean;
    begin
        AppliedQty := 0;
        if ItemApplnEntry.AppliedOutbndEntryExists(ItemLedgEntry."Entry No.", true, ItemLedgEntry.Open) then
            repeat
                if not AdjustAppliedOutbndEntries(ItemApplnEntry."Outbound Item Entry No.", Recursion, InboundCompletelyInvoiced) then
                    AppliedEntryToAdjust :=
                      AppliedEntryToAdjust or
                      InboundCompletelyInvoiced or ItemLedgEntry.Open or not ItemLedgEntry."Completely Invoiced";
                AppliedQty += ItemApplnEntry.Quantity;
            until ItemApplnEntry.Next() = 0;
    end;

    local procedure AdjustAppliedOutbndEntries(OutbndItemLedgEntryNo: Integer; Recursion: Boolean; var InboundCompletelyInvoiced: Boolean): Boolean
    var
        OutbndItemLedgEntry: Record "Item Ledger Entry";
        OutbndValueEntry: Record "Value Entry";
        TempOutbndCostElementBuf: Record "Cost Element Buffer" temporary;
        TempOldCostElementBuf: Record "Cost Element Buffer" temporary;
        TempAdjustedCostElementBuf: Record "Cost Element Buffer" temporary;
        ItemApplnEntry: Record "Item Application Entry";
        StandardCostMirroring: Boolean;
        ExpectedCost: Boolean;
    begin
        OutbndItemLedgEntry.Get(OutbndItemLedgEntryNo);
        if Item."Costing Method" = Item."Costing Method"::Standard then
            StandardCostMirroring := UseStandardCostMirroring(OutbndItemLedgEntry);

        CalcOutbndCost(TempOutbndCostElementBuf, TempAdjustedCostElementBuf, OutbndItemLedgEntry, Recursion);

        OutbndValueEntry.Reset();
        OutbndValueEntry.SetCurrentKey("Item Ledger Entry No.", "Document No.", "Document Line No.");
        OutbndValueEntry.SetRange("Item Ledger Entry No.", OutbndItemLedgEntryNo);
        for ExpectedCost := true downto false do begin
            OutbndValueEntry.SetRange("Expected Cost", ExpectedCost);
            if OutbndValueEntry.FindSet() then
                repeat
                    if not (OutbndValueEntry.Adjustment or ExpCostIsCompletelyInvoiced(OutbndItemLedgEntry, OutbndValueEntry)) and
                       OutbndValueEntry.Inventoriable
                    then begin
                        OutbndValueEntry.SetRange("Document No.", OutbndValueEntry."Document No.");
                        OutbndValueEntry.SetRange("Document Line No.", OutbndValueEntry."Document Line No.");
                        CalcOutbndDocOldCost(
                          TempOldCostElementBuf, OutbndValueEntry,
                          OutbndItemLedgEntry.IsExactCostReversingPurchase() or OutbndItemLedgEntry.IsExactCostReversingOutput());

                        CalcCostPerUnit(OutbndValueEntry, TempOutbndCostElementBuf, OutbndItemLedgEntry.Quantity);

                        if not OutbndValueEntry."Expected Cost" then begin
                            TempOldCostElementBuf.GetElement("Cost Entry Type"::"Direct Cost");
                            OutbndValueEntry."Invoiced Quantity" := TempOldCostElementBuf."Invoiced Quantity";
                            OutbndValueEntry."Valued Quantity" := TempOldCostElementBuf."Invoiced Quantity";
                        end;

                        CalcOutbndDocNewCost(
                          TempAdjustedCostElementBuf, TempOutbndCostElementBuf,
                          OutbndValueEntry, OutbndItemLedgEntry.Quantity);

                        if OutbndValueEntry."Expected Cost" then begin
                            TempOldCostElementBuf.GetElement(TempOldCostElementBuf.Type::Total);
                            TempAdjustedCostElementBuf."Actual Cost" := TempAdjustedCostElementBuf."Actual Cost" - TempOldCostElementBuf."Expected Cost";
                            TempAdjustedCostElementBuf."Actual Cost (ACY)" :=
                              TempAdjustedCostElementBuf."Actual Cost (ACY)" - TempOldCostElementBuf."Expected Cost (ACY)";
                        end else begin
                            TempOldCostElementBuf.GetElement(OutbndValueEntry."Entry Type"::"Direct Cost");
                            TempAdjustedCostElementBuf."Actual Cost" := TempAdjustedCostElementBuf."Actual Cost" - TempOldCostElementBuf."Actual Cost";
                            TempAdjustedCostElementBuf."Actual Cost (ACY)" :=
                              TempAdjustedCostElementBuf."Actual Cost (ACY)" - TempOldCostElementBuf."Actual Cost (ACY)";
                        end;

                        if StandardCostMirroring and not OutbndValueEntry."Expected Cost" then
                            CreateCostAdjmtBuf(
                              OutbndValueEntry, TempAdjustedCostElementBuf, OutbndItemLedgEntry."Posting Date", OutbndValueEntry."Entry Type"::Variance)
                        else
                            CreateCostAdjmtBuf(
                              OutbndValueEntry, TempAdjustedCostElementBuf, OutbndItemLedgEntry."Posting Date", OutbndValueEntry."Entry Type");

                        OnAdjustAppliedOutbndEntriesOnBeforeCheckExpectedCost(Item, OutbndValueEntry);
                        if not OutbndValueEntry."Expected Cost" then begin
                            CreateIndirectCostAdjmt(TempOldCostElementBuf, TempAdjustedCostElementBuf, OutbndValueEntry, OutbndValueEntry."Entry Type"::"Indirect Cost");
                            CreateIndirectCostAdjmt(TempOldCostElementBuf, TempAdjustedCostElementBuf, OutbndValueEntry, OutbndValueEntry."Entry Type"::Variance);
                        end;
                        OutbndValueEntry.FindLast();
                        OutbndValueEntry.SetRange("Document No.");
                        OutbndValueEntry.SetRange("Document Line No.");
                    end;
                until OutbndValueEntry.Next() = 0;
        end;

        // Update transfers, consumptions
        if IsUpdateCompletelyInvoiced(
             OutbndItemLedgEntry, TempOutbndCostElementBuf."Inbound Completely Invoiced")
        then
            OutbndItemLedgEntry.SetCompletelyInvoiced();

        ForwardAppliedCostRecursion(OutbndItemLedgEntry);

        ItemApplnEntry.SetInboundToUpdated(OutbndItemLedgEntry);

        InboundCompletelyInvoiced := TempOutbndCostElementBuf."Inbound Completely Invoiced";
        exit(OutbndItemLedgEntry."Completely Invoiced");
    end;

    local procedure CalcCostPerUnit(var OutbndValueEntry: Record "Value Entry"; OutbndCostElementBuf: Record "Cost Element Buffer"; ItemLedgEntryQty: Decimal)
    begin
        if (OutbndValueEntry."Cost per Unit" = 0) and (OutbndCostElementBuf."Remaining Quantity" <> 0) then
            OutbndValueEntry."Cost per Unit" := OutbndCostElementBuf."Actual Cost" / (ItemLedgEntryQty - OutbndCostElementBuf."Remaining Quantity");
        if (OutbndValueEntry."Cost per Unit (ACY)" = 0) and (OutbndCostElementBuf."Remaining Quantity" <> 0) then
            OutbndValueEntry."Cost per Unit (ACY)" := OutbndCostElementBuf."Actual Cost (ACY)" / (ItemLedgEntryQty - OutbndCostElementBuf."Remaining Quantity");
    end;

    local procedure CalcOutbndCost(var OutbndCostElementBuf: Record "Cost Element Buffer"; var AdjustedCostElementBuf: Record "Cost Element Buffer"; OutbndItemLedgEntry: Record "Item Ledger Entry"; Recursion: Boolean)
    var
        OutbndItemApplnEntry: Record "Item Application Entry";
        TempCostElementBuf: Record "Cost Element Buffer" temporary;
    begin
        AdjustedCostElementBuf.DeleteAll();
        OutbndCostElementBuf.DeleteAll();

        if RestoreValuesFromBuffers(OutbndCostElementBuf, AdjustedCostElementBuf, OutbndItemLedgEntry."Entry No.") then begin
            if not Recursion then begin
                OutbndItemApplnEntry.SetCurrentKey("Inbound Item Entry No.", "Transferred-from Entry No.", "Item Ledger Entry No.");
                OutbndItemApplnEntry.SetRange("Inbound Item Entry No.", TempRndgResidualBuf."Item Ledger Entry No.");
                OutbndItemApplnEntry.SetRange("Item Ledger Entry No.", OutbndItemLedgEntry."Entry No.");
                OutbndItemApplnEntry.SetFilter("Transferred-from Entry No.", '<>%1', TempRndgResidualBuf."Item Ledger Entry No.");
                if OutbndItemApplnEntry.FindSet() then
                    repeat
                        CalcInbndEntryAdjustedCost(
                          TempCostElementBuf, OutbndItemApplnEntry, OutbndItemLedgEntry."Entry No.", OutbndItemApplnEntry."Inbound Item Entry No.",
                          OutbndItemLedgEntry.IsExactCostReversingPurchase() or OutbndItemLedgEntry.IsExactCostReversingOutput(), false);
                    until OutbndItemApplnEntry.Next() = 0;
            end;
            exit;
        end;

        OutbndCostElementBuf."Remaining Quantity" := OutbndItemLedgEntry.Quantity;
        OutbndCostElementBuf."Inbound Completely Invoiced" := true;

        OutbndItemApplnEntry.SetCurrentKey("Item Ledger Entry No.");
        OutbndItemApplnEntry.SetRange("Item Ledger Entry No.", OutbndItemLedgEntry."Entry No.");
        OutbndItemApplnEntry.FindSet();
        repeat
            if not
               CalcInbndEntryAdjustedCost(
                 AdjustedCostElementBuf,
                 OutbndItemApplnEntry, OutbndItemLedgEntry."Entry No.",
                 OutbndItemApplnEntry."Inbound Item Entry No.",
                 OutbndItemLedgEntry.IsExactCostReversingPurchase() or OutbndItemLedgEntry.IsExactCostReversingOutput(),
                 Recursion)
            then
                OutbndCostElementBuf."Inbound Completely Invoiced" := false;

            AdjustedCostElementBuf.GetElement(OutbndCostElementBuf.Type::"Direct Cost");
            OutbndCostElementBuf."Actual Cost" := OutbndCostElementBuf."Actual Cost" + AdjustedCostElementBuf."Actual Cost";
            OutbndCostElementBuf."Actual Cost (ACY)" := OutbndCostElementBuf."Actual Cost (ACY)" + AdjustedCostElementBuf."Actual Cost (ACY)";
            OutbndCostElementBuf."Remaining Quantity" := OutbndCostElementBuf."Remaining Quantity" - OutbndItemApplnEntry.Quantity;
        until OutbndItemApplnEntry.Next() = 0;

        if OutbndCostElementBuf."Inbound Completely Invoiced" then
            OutbndCostElementBuf."Inbound Completely Invoiced" := OutbndCostElementBuf."Remaining Quantity" = 0;

        SaveValuesToBuffers(OutbndCostElementBuf, AdjustedCostElementBuf, OutbndItemLedgEntry."Entry No.");
    end;

    local procedure CalcOutbndDocNewCost(var NewCostElementBuf: Record "Cost Element Buffer"; OutbndCostElementBuf: Record "Cost Element Buffer"; OutbndValueEntry: Record "Value Entry"; ItemLedgEntryQty: Decimal)
    var
        ShareOfTotalCost: Decimal;
    begin
        ShareOfTotalCost := OutbndValueEntry."Valued Quantity" / ItemLedgEntryQty;
        NewCostElementBuf.GetElement(OutbndCostElementBuf.Type::"Direct Cost");
        OutbndCostElementBuf."Actual Cost" := OutbndCostElementBuf."Actual Cost" + OutbndValueEntry."Cost per Unit" * OutbndCostElementBuf."Remaining Quantity";
        OutbndCostElementBuf."Actual Cost (ACY)" := OutbndCostElementBuf."Actual Cost (ACY)" + OutbndValueEntry."Cost per Unit (ACY)" * OutbndCostElementBuf."Remaining Quantity";

        RoundCost(
          NewCostElementBuf."Actual Cost", NewCostElementBuf."Rounding Residual",
          OutbndCostElementBuf."Actual Cost", ShareOfTotalCost, GLSetup."Amount Rounding Precision");
        RoundCost(
          NewCostElementBuf."Actual Cost (ACY)", NewCostElementBuf."Rounding Residual (ACY)",
          OutbndCostElementBuf."Actual Cost (ACY)", ShareOfTotalCost, Currency."Amount Rounding Precision");

        if not NewCostElementBuf.Insert() then
            NewCostElementBuf.Modify();
    end;

    local procedure CollectAvgCostAdjmtEntryPointToUpdate(var TempAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point" temporary; ItemNo: Code[20])
    var
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
    begin
        AvgCostAdjmtEntryPoint.SetRange("Item No.", ItemNo);
        AvgCostAdjmtEntryPoint.SetRange("Cost Is Adjusted", false);
        if AvgCostAdjmtEntryPoint.FindSet() then
            repeat
                InsertEntryPointToUpdate(
                  TempAvgCostAdjmtEntryPoint, AvgCostAdjmtEntryPoint."Item No.", AvgCostAdjmtEntryPoint."Variant Code", AvgCostAdjmtEntryPoint."Location Code");
            until AvgCostAdjmtEntryPoint.Next() = 0;
    end;

    local procedure CreateCostAdjmtBuf(OutbndValueEntry: Record "Value Entry"; CostElementBuf: Record "Cost Element Buffer"; ItemLedgEntryPostingDate: Date; EntryType: Enum "Cost Entry Type"): Boolean
    begin
        if UpdateAdjmtBuf(OutbndValueEntry, CostElementBuf."Actual Cost", CostElementBuf."Actual Cost (ACY)", ItemLedgEntryPostingDate, EntryType) then begin
            UpdateAvgCostAdjmtEntryPoint(OutbndValueEntry);
            exit(true);
        end;
        exit(false);
    end;

    local procedure CreateIndirectCostAdjmt(var CostElementBuf: Record "Cost Element Buffer"; var AdjustedCostElementBuf: Record "Cost Element Buffer"; OutbndValueEntry: Record "Value Entry"; EntryType: Enum "Cost Entry Type")
    var
        ItemJnlLine: Record "Item Journal Line";
        OrigValueEntry: Record "Value Entry";
        NewAdjustedCost: Decimal;
        NewAdjustedCostACY: Decimal;
    begin
        CostElementBuf.GetElement(EntryType);
        AdjustedCostElementBuf.GetElement(EntryType);
        NewAdjustedCost := AdjustedCostElementBuf."Actual Cost" - CostElementBuf."Actual Cost";
        NewAdjustedCostACY := AdjustedCostElementBuf."Actual Cost (ACY)" - CostElementBuf."Actual Cost (ACY)";

        if HasNewCost(NewAdjustedCost, NewAdjustedCostACY) then begin
            GetOrigValueEntry(OrigValueEntry, OutbndValueEntry, EntryType);
            InitAdjmtJnlLine(
              ItemJnlLine, OrigValueEntry, OrigValueEntry."Entry Type", OrigValueEntry."Variance Type", OrigValueEntry."Invoiced Quantity");
            PostItemJnlLine(ItemJnlLine, OrigValueEntry, NewAdjustedCost, NewAdjustedCostACY);

            OnCreateIndirectCostAdjmtOnAfterPostItemJnlLine(OrigValueEntry, NewAdjustedCost, NewAdjustedCostACY);
            UpdateAvgCostAdjmtEntryPoint(OrigValueEntry);
        end;
    end;

    local procedure ForwardCostToInbndTransEntries(ItemLedgEntryNo: Integer; Recursion: Boolean)
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        if not ItemLedgerEntryTypeIsUsed("Item Ledger Entry Type"::Transfer) then
            exit;

        if ItemApplnEntry.AppliedInbndTransEntryExists(ItemLedgEntryNo, true) then
            repeat
                AdjustAppliedInbndTransEntries(ItemApplnEntry, Recursion);
            until ItemApplnEntry.Next() = 0;
    end;

    local procedure AdjustAppliedInbndTransEntries(TransItemApplnEntry: Record "Item Application Entry"; Recursion: Boolean)
    var
        TransValueEntry: Record "Value Entry";
        TransItemLedgEntry: Record "Item Ledger Entry";
        TempCostElementBuf: Record "Cost Element Buffer" temporary;
        TempAdjustedCostElementBuf: Record "Cost Element Buffer" temporary;
        EntryAdjusted: Boolean;
    begin
        TransItemLedgEntry.Get(TransItemApplnEntry."Item Ledger Entry No.");
        if not TransItemLedgEntry."Completely Invoiced" then
            AdjustNotInvdRevaluation(TransItemLedgEntry, TransItemApplnEntry);

        CalcTransEntryOldCost(TempCostElementBuf, TransValueEntry, TransItemApplnEntry."Item Ledger Entry No.");

        if CalcInbndEntryAdjustedCost(
             TempAdjustedCostElementBuf,
             TransItemApplnEntry, TransItemLedgEntry."Entry No.",
             TransItemApplnEntry."Transferred-from Entry No.",
             false, Recursion)
        then
            if not TransItemLedgEntry."Completely Invoiced" then begin
                TransItemLedgEntry.SetCompletelyInvoiced();
                EntryAdjusted := true;
            end;

        if UpdateAdjmtBuf(
             TransValueEntry,
             TempAdjustedCostElementBuf."Actual Cost" - TempCostElementBuf."Actual Cost",
             TempAdjustedCostElementBuf."Actual Cost (ACY)" - TempCostElementBuf."Actual Cost (ACY)",
             TransItemLedgEntry."Posting Date",
             TransValueEntry."Entry Type")
        then
            EntryAdjusted := true;

        if EntryAdjusted then begin
            ClearOutboundEntryCostBuffer(TransItemLedgEntry."Entry No.");
            UpdateAvgCostAdjmtEntryPoint(TransValueEntry);
            ForwardAppliedCostRecursion(TransItemLedgEntry);
        end;
    end;

    local procedure CalcTransEntryOldCost(var CostElementBuf: Record "Cost Element Buffer"; var TransValueEntry: Record "Value Entry"; ItemLedgEntryNo: Integer)
    var
        TransValueEntry2: Record "Value Entry";
    begin
        Clear(CostElementBuf);
        TransValueEntry2 := TransValueEntry;
        TransValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        TransValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
        TransValueEntry.SetRange("Entry Type", TransValueEntry."Entry Type"::"Direct Cost");
        TransValueEntry.Ascending(false);
        TransValueEntry.FindSet();
        repeat
            if TransValueEntry."Item Charge No." = '' then begin
                if TempInvtAdjmtBuf.Get(TransValueEntry."Entry No.") then
                    TransValueEntry.AddCost(TempInvtAdjmtBuf);
                CostElementBuf."Actual Cost" := CostElementBuf."Actual Cost" + TransValueEntry."Cost Amount (Actual)";
                CostElementBuf."Actual Cost (ACY)" := CostElementBuf."Actual Cost (ACY)" + TransValueEntry."Cost Amount (Actual) (ACY)";
                TransValueEntry2 := TransValueEntry;
            end;
        until TransValueEntry.Next() = 0;
        TransValueEntry := TransValueEntry2;
    end;

    local procedure ForwardCostToInbndEntries(ItemLedgEntryNo: Integer)
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        if ItemApplnEntry.AppliedInbndEntryExists(ItemLedgEntryNo, true) then
            repeat
                AdjustAppliedInbndEntries(ItemApplnEntry);
            until ItemApplnEntry.Next() = 0;
    end;

    local procedure AdjustAppliedInbndEntries(var InbndItemApplnEntry: Record "Item Application Entry")
    var
        OutbndItemLedgEntry: Record "Item Ledger Entry";
        InbndValueEntry: Record "Value Entry";
        InbndItemLedgEntry: Record "Item Ledger Entry";
        TempDocCostElementBuffer: Record "Cost Element Buffer" temporary;
        TempOldCostElementBuf: Record "Cost Element Buffer" temporary;
        EntryAdjusted: Boolean;
    begin
        OutbndItemLedgEntry.SetLoadFields(Quantity, "Invoiced Quantity", "Completely Invoiced");
        OutbndItemLedgEntry.Get(InbndItemApplnEntry."Outbound Item Entry No.");
        CalcItemApplnEntryOldCost(TempOldCostElementBuf, OutbndItemLedgEntry, InbndItemApplnEntry.Quantity);

        InbndItemLedgEntry.Get(InbndItemApplnEntry."Item Ledger Entry No.");
        InbndValueEntry.SetCurrentKey("Item Ledger Entry No.", "Document No.");
        InbndValueEntry.SetRange("Item Ledger Entry No.", InbndItemApplnEntry."Item Ledger Entry No.");
        OnAdjustAppliedInbndEntriesOnAfterSetFilter(InbndValueEntry);
        InbndValueEntry.FindSet();
        repeat
            if (InbndValueEntry."Entry Type" = InbndValueEntry."Entry Type"::"Direct Cost") and
               (InbndValueEntry."Item Charge No." = '') and
               not ExpCostIsCompletelyInvoiced(InbndItemLedgEntry, InbndValueEntry)
            then begin
                InbndValueEntry.SetRange("Document No.", InbndValueEntry."Document No.");
                InbndValueEntry.SetRange("Document Line No.", InbndValueEntry."Document Line No.");
                CalcInbndDocOldCost(InbndValueEntry, TempDocCostElementBuffer);

                if not InbndValueEntry."Expected Cost" then begin
                    TempDocCostElementBuffer.GetElement("Cost Entry Type"::"Direct Cost");
                    InbndValueEntry."Valued Quantity" := TempDocCostElementBuffer."Invoiced Quantity";
                    InbndValueEntry."Invoiced Quantity" := TempDocCostElementBuffer."Invoiced Quantity";
                end;

                CalcInbndDocNewCost(
                  TempDocCostElementBuffer, TempOldCostElementBuf, InbndValueEntry."Expected Cost",
                  InbndValueEntry."Valued Quantity" / InbndItemLedgEntry.Quantity);

                if CreateCostAdjmtBuf(
                     InbndValueEntry, TempDocCostElementBuffer, InbndItemLedgEntry."Posting Date", InbndValueEntry."Entry Type")
                then begin
                    EntryAdjusted := true;
                    TempValueEntryCalcdOutbndCostBuf.DeleteAll();
                end;

                InbndValueEntry.FindLast();
                InbndValueEntry.SetRange("Document No.");
                InbndValueEntry.SetRange("Document Line No.");
            end;
        until InbndValueEntry.Next() = 0;

        // Update transfers, consumptions
        if IsUpdateCompletelyInvoiced(
             InbndItemLedgEntry, OutbndItemLedgEntry."Completely Invoiced")
        then begin
            InbndItemLedgEntry.SetCompletelyInvoiced();
            EntryAdjusted := true;
        end;

        if EntryAdjusted then begin
            UpdateAvgCostAdjmtEntryPoint(InbndValueEntry);
            ForwardAppliedCostRecursion(InbndItemLedgEntry);
        end;
    end;

    local procedure CalcItemApplnEntryOldCost(var OldCostElementBuf: Record "Cost Element Buffer"; OutbndItemLedgEntry: Record "Item Ledger Entry"; ItemApplnEntryQty: Decimal)
    var
        OutbndValueEntry: Record "Value Entry";
        ShareOfExpectedCost: Decimal;
    begin
        ShareOfExpectedCost :=
          (OutbndItemLedgEntry.Quantity - OutbndItemLedgEntry."Invoiced Quantity") / OutbndItemLedgEntry.Quantity;

        Clear(OldCostElementBuf);
        OutbndValueEntry.SetCurrentKey("Item Ledger Entry No.");
        OutbndValueEntry.SetRange("Item Ledger Entry No.", OutbndItemLedgEntry."Entry No.");
        OutbndValueEntry.SetLoadFields("Expected Cost", "Cost Amount (Actual)", "Cost Amount (Actual) (ACY)", "Cost Amount (Expected)", "Cost Amount (Expected) (ACY)");
        OutbndValueEntry.FindSet();
        repeat
            if TempInvtAdjmtBuf.Get(OutbndValueEntry."Entry No.") then
                OutbndValueEntry.AddCost(TempInvtAdjmtBuf);
            if OutbndValueEntry."Expected Cost" then begin
                OldCostElementBuf."Actual Cost" := OldCostElementBuf."Actual Cost" + OutbndValueEntry."Cost Amount (Expected)" * ShareOfExpectedCost;
                OldCostElementBuf."Actual Cost (ACY)" := OldCostElementBuf."Actual Cost (ACY)" + OutbndValueEntry."Cost Amount (Expected) (ACY)" * ShareOfExpectedCost;
            end else begin
                OldCostElementBuf."Actual Cost" := OldCostElementBuf."Actual Cost" + OutbndValueEntry."Cost Amount (Actual)";
                OldCostElementBuf."Actual Cost (ACY)" := OldCostElementBuf."Actual Cost (ACY)" + OutbndValueEntry."Cost Amount (Actual) (ACY)";
            end;
        until OutbndValueEntry.Next() = 0;

        OldCostElementBuf.RoundActualCost(
          ItemApplnEntryQty / OutbndItemLedgEntry.Quantity,
          GLSetup."Amount Rounding Precision", Currency."Amount Rounding Precision");
    end;

    local procedure CalcInbndDocOldCost(InbndValueEntry: Record "Value Entry"; var CostElementBuf: Record "Cost Element Buffer")
    begin
        CostElementBuf.DeleteAll();

        InbndValueEntry.SetCurrentKey("Item Ledger Entry No.", "Document No.");
        InbndValueEntry.SetRange("Item Ledger Entry No.", InbndValueEntry."Item Ledger Entry No.");
        InbndValueEntry.SetRange("Document No.", InbndValueEntry."Document No.");
        InbndValueEntry.SetRange("Document Line No.", InbndValueEntry."Document Line No.");
        if InbndValueEntry.FindSet() then
            repeat
                if (InbndValueEntry."Entry Type" = InbndValueEntry."Entry Type"::"Direct Cost") and
                    (InbndValueEntry."Item Charge No." = '')
                then begin
                    if TempInvtAdjmtBuf.Get(InbndValueEntry."Entry No.") then
                        InbndValueEntry.AddCost(TempInvtAdjmtBuf);
                    if InbndValueEntry."Expected Cost" then
                        CostElementBuf.AddExpectedCostElement("Cost Entry Type"::"Direct Cost", InbndValueEntry)
                    else begin
                        CostElementBuf.AddActualCostElement("Cost Entry Type"::"Direct Cost", InbndValueEntry);
                        if InbndValueEntry."Invoiced Quantity" <> 0 then begin
                            CostElementBuf."Invoiced Quantity" := CostElementBuf."Invoiced Quantity" + InbndValueEntry."Invoiced Quantity";
                            if not CostElementBuf.Modify() then
                                CostElementBuf.Insert();
                        end;
                    end;
                end;
            until InbndValueEntry.Next() = 0;
    end;

    local procedure CalcInbndDocNewCost(var NewCostElementBuf: Record "Cost Element Buffer"; OldCostElementBuf: Record "Cost Element Buffer"; Expected: Boolean; ShareOfTotalCost: Decimal)
    begin
        OldCostElementBuf.RoundActualCost(
          ShareOfTotalCost, GLSetup."Amount Rounding Precision", Currency."Amount Rounding Precision");

        if Expected then begin
            NewCostElementBuf."Actual Cost" := OldCostElementBuf."Actual Cost" - NewCostElementBuf."Expected Cost";
            NewCostElementBuf."Actual Cost (ACY)" := OldCostElementBuf."Actual Cost (ACY)" - NewCostElementBuf."Expected Cost (ACY)";
        end else begin
            NewCostElementBuf."Actual Cost" := OldCostElementBuf."Actual Cost" - NewCostElementBuf."Actual Cost";
            NewCostElementBuf."Actual Cost (ACY)" := OldCostElementBuf."Actual Cost (ACY)" - NewCostElementBuf."Actual Cost (ACY)";
        end;
    end;

    local procedure IsUpdateCompletelyInvoiced(ItemLedgEntry: Record "Item Ledger Entry"; CompletelyInvoiced: Boolean) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsUpdateCompletelyInvoiced(ItemLedgEntry, CompletelyInvoiced, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(
              (ItemLedgEntry."Entry Type" in [ItemLedgEntry."Entry Type"::Transfer, ItemLedgEntry."Entry Type"::Consumption]) and
              not ItemLedgEntry."Completely Invoiced" and
              CompletelyInvoiced);
    end;

    local procedure CalcInbndEntryAdjustedCost(var AdjustedCostElementBuf: Record "Cost Element Buffer"; ItemApplnEntry: Record "Item Application Entry"; OutbndItemLedgEntryNo: Integer; InbndItemLedgEntryNo: Integer; ExactCostReversing: Boolean; Recursion: Boolean) CompletelyInvoiced: Boolean
    var
        InbndValueEntry: Record "Value Entry";
        InbndItemLedgEntry: Record "Item Ledger Entry";
        QtyNotInvoiced: Decimal;
        ShareOfTotalCost: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcInbndEntryAdjustedCost(AdjustedCostElementBuf, ItemApplnEntry, OutbndItemLedgEntryNo, InbndItemLedgEntryNo, ExactCostReversing, Recursion, CompletelyInvoiced, IsHandled);
        if not IsHandled then begin
            AdjustedCostElementBuf.DeleteAll();
            InbndItemLedgEntry.Get(InbndItemLedgEntryNo);
            InbndValueEntry.SetCurrentKey("Item Ledger Entry No.");
            InbndValueEntry.SetRange("Item Ledger Entry No.", InbndItemLedgEntryNo);
            QtyNotInvoiced := InbndItemLedgEntry.Quantity - InbndItemLedgEntry."Invoiced Quantity";

            InbndValueEntry.FindSet();
            repeat
                if IncludedInCostCalculation(InbndValueEntry, OutbndItemLedgEntryNo) and
                   not ExpCostIsCompletelyInvoiced(InbndItemLedgEntry, InbndValueEntry)
                then begin
                    OnCalcInbndEntryAdjustedCostOnBeforeAddCost(Item, InbndValueEntry);
                    if TempInvtAdjmtBuf.Get(InbndValueEntry."Entry No.") then
                        InbndValueEntry.AddCost(TempInvtAdjmtBuf);
                    case true of
                        IsInterimRevaluation(InbndValueEntry):
                            begin
                                ShareOfTotalCost := InbndItemLedgEntry.Quantity / InbndValueEntry."Valued Quantity";
                                AdjustedCostElementBuf.AddActualCostElement(
                                  AdjustedCostElementBuf.Type::"Direct Cost",
                                  (InbndValueEntry."Cost Amount (Expected)" + InbndValueEntry."Cost Amount (Actual)") * ShareOfTotalCost,
                                  (InbndValueEntry."Cost Amount (Expected) (ACY)" + InbndValueEntry."Cost Amount (Actual) (ACY)") * ShareOfTotalCost);
                            end;
                        InbndValueEntry."Expected Cost":
                            begin
                                ShareOfTotalCost := QtyNotInvoiced / InbndValueEntry."Valued Quantity";
                                AdjustedCostElementBuf.AddActualCostElement(
                                  AdjustedCostElementBuf.Type::"Direct Cost",
                                  InbndValueEntry."Cost Amount (Expected)" * ShareOfTotalCost,
                                  InbndValueEntry."Cost Amount (Expected) (ACY)" * ShareOfTotalCost);
                            end;
                        InbndValueEntry."Partial Revaluation":
                            begin
                                ShareOfTotalCost := InbndItemLedgEntry.Quantity / InbndValueEntry."Valued Quantity";
                                AdjustedCostElementBuf.AddActualCostElement(
                                  AdjustedCostElementBuf.Type::"Direct Cost",
                                  InbndValueEntry."Cost Amount (Actual)" * ShareOfTotalCost,
                                  InbndValueEntry."Cost Amount (Actual) (ACY)" * ShareOfTotalCost);
                            end;
                        (InbndValueEntry."Entry Type" in [InbndValueEntry."Entry Type"::"Direct Cost", InbndValueEntry."Entry Type"::Revaluation]) or not ExactCostReversing:
                            AdjustedCostElementBuf.AddActualCostElement(AdjustedCostElementBuf.Type::"Direct Cost", InbndValueEntry);
                        InbndValueEntry."Entry Type" = InbndValueEntry."Entry Type"::"Indirect Cost":
                            AdjustedCostElementBuf.AddActualCostElement(AdjustedCostElementBuf.Type::"Indirect Cost", InbndValueEntry);
                        else
                            AdjustedCostElementBuf.AddActualCostElement(AdjustedCostElementBuf.Type::Variance, InbndValueEntry);
                    end;
                end;
            until InbndValueEntry.Next() = 0;

            CalcNewAdjustedCost(AdjustedCostElementBuf, ItemApplnEntry.Quantity / InbndItemLedgEntry.Quantity);

            if AdjustAppliedCostEntry(ItemApplnEntry, InbndItemLedgEntryNo, Recursion) then
                TempRndgResidualBuf.AddAdjustedCost(
                  ItemApplnEntry."Inbound Item Entry No.",
                  AdjustedCostElementBuf."Actual Cost", AdjustedCostElementBuf."Actual Cost (ACY)",
                  ItemApplnEntry."Output Completely Invd. Date" <> 0D);
            CompletelyInvoiced := InbndItemLedgEntry."Completely Invoiced";
        end;

        OnAfterCalcInbndEntryAdjustedCost(AdjustedCostElementBuf, InbndValueEntry, InbndItemLedgEntry, ItemApplnEntry, OutbndItemLedgEntryNo, CompletelyInvoiced);
    end;

    local procedure CalcNewAdjustedCost(var AdjustedCostElementBuf: Record "Cost Element Buffer"; ShareOfTotalCost: Decimal)
    begin
        if AdjustedCostElementBuf.FindSet() then
            repeat
                AdjustedCostElementBuf.RoundActualCost(ShareOfTotalCost, GLSetup."Amount Rounding Precision", Currency."Amount Rounding Precision");
                AdjustedCostElementBuf.Modify();
            until AdjustedCostElementBuf.Next() = 0;

        AdjustedCostElementBuf.CalcSums("Actual Cost", "Actual Cost (ACY)");
        AdjustedCostElementBuf.AddActualCostElement(AdjustedCostElementBuf.Type::Total, AdjustedCostElementBuf."Actual Cost", AdjustedCostElementBuf."Actual Cost (ACY)");
    end;

    local procedure AdjustAppliedCostEntry(ItemApplnEntry: Record "Item Application Entry"; ItemLedgEntryNo: Integer; Recursion: Boolean): Boolean
    begin
        exit(
              (ItemApplnEntry."Transferred-from Entry No." <> ItemLedgEntryNo) and
              (ItemApplnEntry."Inbound Item Entry No." = TempRndgResidualBuf."Item Ledger Entry No.") and
              not Recursion);
    end;

    procedure IncludedInCostCalculation(InbndValueEntry: Record "Value Entry"; OutbndItemLedgEntryNo: Integer): Boolean
    var
        OutbndValueEntry: Record "Value Entry";
    begin
        if InbndValueEntry."Entry Type" = InbndValueEntry."Entry Type"::Revaluation then begin
            if InbndValueEntry."Applies-to Entry" <> 0 then begin
                InbndValueEntry.Get(InbndValueEntry."Applies-to Entry");
                exit(IncludedInCostCalculation(InbndValueEntry, OutbndItemLedgEntryNo));
            end;
            if InbndValueEntry."Partial Revaluation" then begin
                OutbndValueEntry.SetCurrentKey("Item Ledger Entry No.");
                OutbndValueEntry.SetRange("Item Ledger Entry No.", OutbndItemLedgEntryNo);
                OutbndValueEntry.SetFilter("Item Ledger Entry Quantity", '<>0');
                OutbndValueEntry.FindFirst();
                exit(
                  (OutbndValueEntry."Entry No." > InbndValueEntry."Entry No.") or
                  (OutbndValueEntry.GetValuationDate() > InbndValueEntry."Valuation Date") or
                  (OutbndValueEntry."Entry No." = 0));
            end;
        end;
        exit(InbndValueEntry."Entry Type" <> InbndValueEntry."Entry Type"::Rounding);
    end;

    local procedure CalcOutbndDocOldCost(var CostElementBuf: Record "Cost Element Buffer"; OutbndValueEntry: Record "Value Entry"; ExactCostReversing: Boolean)
    var
        ValueEntry: Record "Value Entry";
    begin
        CostElementBuf.DeleteAll();
        ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Document No.", "Document Line No.");
        ValueEntry.SetRange("Item Ledger Entry No.", OutbndValueEntry."Item Ledger Entry No.");
        ValueEntry.SetRange("Document No.", OutbndValueEntry."Document No.");
        ValueEntry.SetRange("Document Line No.", OutbndValueEntry."Document Line No.");
        ValueEntry.FindSet();
        repeat
            if TempInvtAdjmtBuf.Get(ValueEntry."Entry No.") then
                ValueEntry.AddCost(TempInvtAdjmtBuf);
            CostElementBuf.AddExpectedCostElement(
              CostElementBuf.Type::Total, ValueEntry."Cost Amount (Expected)", ValueEntry."Cost Amount (Expected) (ACY)");
            if not ValueEntry."Expected Cost" then
                case true of
                    (ValueEntry."Entry Type" in [ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Entry Type"::Revaluation]) or not ExactCostReversing:
                        begin
                            CostElementBuf.AddActualCostElement(CostElementBuf.Type::"Direct Cost", ValueEntry);
                            if ValueEntry."Invoiced Quantity" <> 0 then begin
                                CostElementBuf."Invoiced Quantity" += ValueEntry."Invoiced Quantity";
                                if not CostElementBuf.Modify() then
                                    CostElementBuf.Insert();
                            end;
                        end;
                    ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Indirect Cost":
                        CostElementBuf.AddActualCostElement(CostElementBuf.Type::"Indirect Cost", ValueEntry);
                    else
                        CostElementBuf.AddActualCostElement(CostElementBuf.Type::Variance, ValueEntry);
                end;
        until ValueEntry.Next() = 0;

        CostElementBuf.CalcSums("Actual Cost", "Actual Cost (ACY)");
        CostElementBuf.AddActualCostElement(CostElementBuf.Type::Total, CostElementBuf."Actual Cost", CostElementBuf."Actual Cost (ACY)");
    end;

    local procedure EliminateRndgResidual(InbndItemLedgEntry: Record "Item Ledger Entry"; AppliedQty: Decimal)
    var
        ItemJnlLine: Record "Item Journal Line";
        ValueEntry: Record "Value Entry";
        RndgCost: Decimal;
        RndgCostACY: Decimal;
        IsHandled: Boolean;
    begin
        if IsRndgAllowed(InbndItemLedgEntry, AppliedQty) then begin
            TempInvtAdjmtBuf.CalcItemLedgEntryCost(InbndItemLedgEntry."Entry No.", false);
            ValueEntry.CalcItemLedgEntryCost(InbndItemLedgEntry."Entry No.", false);
            ValueEntry.AddCost(TempInvtAdjmtBuf);

            TempRndgResidualBuf.SetRange("Item Ledger Entry No.", InbndItemLedgEntry."Entry No.");
            TempRndgResidualBuf.SetRange("Completely Invoiced", false);
            if TempRndgResidualBuf.IsEmpty() then begin
                TempRndgResidualBuf.SetRange("Completely Invoiced");
                TempRndgResidualBuf.CalcSums("Adjusted Cost", "Adjusted Cost (ACY)");
                RndgCost := -(ValueEntry."Cost Amount (Actual)" + TempRndgResidualBuf."Adjusted Cost");
                RndgCostACY := -(ValueEntry."Cost Amount (Actual) (ACY)" + TempRndgResidualBuf."Adjusted Cost (ACY)");

                IsHandled := false;
                OnEliminateRndgResidualOnBeforeCheckHasNewCost(InbndItemLedgEntry, ValueEntry, RndgCost, RndgCostACY, IsHandled);
                if not IsHandled then
                    if HasNewCost(RndgCost, RndgCostACY) then begin
                        ValueEntry.Reset();
                        ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
                        ValueEntry.SetRange("Item Ledger Entry No.", InbndItemLedgEntry."Entry No.");
                        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
                        ValueEntry.SetRange("Item Charge No.", '');
                        ValueEntry.SetRange(Adjustment, false);
                        ValueEntry.FindLast();
                        InitRndgResidualItemJnlLine(ItemJnlLine, ValueEntry);
                        PostItemJnlLine(ItemJnlLine, ValueEntry, RndgCost, RndgCostACY);
                    end;
            end;
        end;

        TempRndgResidualBuf.Reset();
        TempRndgResidualBuf.DeleteAll();
    end;

    local procedure IsRndgAllowed(ItemLedgEntry: Record "Item Ledger Entry"; AppliedQty: Decimal): Boolean
    begin
        exit(
          not ItemLedgEntry.Open and
          ItemLedgEntry."Completely Invoiced" and
          ItemLedgEntry.Positive and
          (AppliedQty = -ItemLedgEntry.Quantity) and
          not LevelExceeded);
    end;

    local procedure InitRndgResidualItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; OrigValueEntry: Record "Value Entry")
    begin
        ItemJnlLine.Init();
        ItemJnlLine."Value Entry Type" := ItemJnlLine."Value Entry Type"::Rounding;
        ItemJnlLine."Quantity (Base)" := 1;
        ItemJnlLine."Invoiced Qty. (Base)" := 1;
        ItemJnlLine."Source No." := OrigValueEntry."Source No.";
    end;

    local procedure AdjustItemAvgCost()
    var
        TempOutbndValueEntry: Record "Value Entry" temporary;
        TempExcludedValueEntry: Record "Value Entry" temporary;
        TempAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point" temporary;
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
        PeriodPageMgt: Codeunit PeriodPageManagement;
        RemainingOutbnd: Integer;
        Restart: Boolean;
        EndOfValuationDateReached: Boolean;
        IsHandled: Boolean;
    begin
        if not IsAvgCostItem() then
            exit;

        UpDateWindow(WindowAdjmtLevel, WindowItem, Text008, WindowFWLevel, WindowEntry, 0);

        TempFixApplBuffer.Reset();
        TempFixApplBuffer.DeleteAll();
        DeleteAvgBuffers(TempOutbndValueEntry, TempExcludedValueEntry);
        Clear(ItemApplicationChain);

        while AvgCostAdjmtEntryPointExist(TempAvgCostAdjmtEntryPoint) do begin
            repeat
                Restart := false;
                AvgCostAdjmtEntryPoint := TempAvgCostAdjmtEntryPoint;

                if (ConsumpAdjmtInPeriodWithOutput <> 0D) and
                   (ConsumpAdjmtInPeriodWithOutput <= AvgCostAdjmtEntryPoint."Valuation Date")
                then
                    exit;

                AvgCostAdjmtEntryPoint.SetAvgCostAjmtFilter(TempAvgCostAdjmtEntryPoint);
                TempAvgCostAdjmtEntryPoint.DeleteAll();
                TempAvgCostAdjmtEntryPoint.Reset();

                AvgCostAdjmtEntryPoint.SetAvgCostAjmtFilter(AvgCostAdjmtEntryPoint);
                AvgCostAdjmtEntryPoint.ModifyAll(AvgCostAdjmtEntryPoint."Cost Is Adjusted", true);
                AvgCostAdjmtEntryPoint.Reset();

                OnAdjustItemAvgCostOnBeforeAdjustValueEntries();

                while not Restart and AvgValueEntriesToAdjustExist(
                        TempOutbndValueEntry, TempExcludedValueEntry, AvgCostAdjmtEntryPoint) and not EndOfValuationDateReached
                do begin
                    RemainingOutbnd := TempOutbndValueEntry.Count();
                    TempOutbndValueEntry.SetCurrentKey("Item Ledger Entry No.");
                    TempOutbndValueEntry.Find('-');

                    repeat
                        OnAdjustItemAvgCostOnBeforeUpdateWindow(Item);
                        UpDateWindow(WindowAdjmtLevel, WindowItem, WindowAdjust, WindowFWLevel, WindowEntry, RemainingOutbnd);
                        RemainingOutbnd -= 1;
                        AdjustOutbndAvgEntry(TempOutbndValueEntry, TempExcludedValueEntry);
                        UpdateConsumpAvgEntry(TempOutbndValueEntry);
                    until TempOutbndValueEntry.Next() = 0;

                    AvgCostAdjmtEntryPoint.SetAvgCostAjmtFilter(AvgCostAdjmtEntryPoint);
                    Restart := AvgCostAdjmtEntryPoint.FindFirst() and not AvgCostAdjmtEntryPoint."Cost Is Adjusted";
                    OnAdjustItemAvgCostOnAfterCalcRestart(TempExcludedValueEntry, Restart);
                    if AvgCostAdjmtEntryPoint."Valuation Date" >= PeriodPageMgt.EndOfPeriod() then
                        EndOfValuationDateReached := true
                    else
                        AvgCostAdjmtEntryPoint."Valuation Date" := GetNextDate(AvgCostAdjmtEntryPoint."Valuation Date");
                end;
            until (TempAvgCostAdjmtEntryPoint.Next() = 0) or Restart;

            IsHandled := false;
            OnAdjustItemAvgCostOnAfterLastTempAvgCostAdjmtEntryPoint(TempAvgCostAdjmtEntryPoint, Restart, IsHandled);
            if IsHandled then
                break;
        end;
    end;

    local procedure AvgCostAdjmtEntryPointExist(var ToAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point"): Boolean
    var
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
    begin
        AvgCostAdjmtEntryPoint.SetCurrentKey("Item No.", "Cost Is Adjusted", "Valuation Date");
        AvgCostAdjmtEntryPoint.SetRange("Item No.", Item."No.");
        AvgCostAdjmtEntryPoint.SetRange("Cost Is Adjusted", false);

        CopyAvgCostAdjmtToAvgCostAdjmt(AvgCostAdjmtEntryPoint, ToAvgCostAdjmtEntryPoint);
        ToAvgCostAdjmtEntryPoint.SetCurrentKey("Item No.", "Cost Is Adjusted", "Valuation Date");
        exit(ToAvgCostAdjmtEntryPoint.FindFirst())
    end;

    local procedure AvgValueEntriesToAdjustExist(var OutbndValueEntry: Record "Value Entry"; var ExcludedValueEntry: Record "Value Entry"; var AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point"): Boolean
    var
        ValueEntry: Record "Value Entry";
        CalendarPeriod: Record Date;
        FiscalYearAccPeriod: Record "Accounting Period";
        ItemApplicationEntry: Record "Item Application Entry";
        PeriodPageMgt: Codeunit PeriodPageManagement;
        FindNextRange: Boolean;
    begin
        FindNextRange := false;
        ResetAvgBuffers(OutbndValueEntry, ExcludedValueEntry);

        CalendarPeriod."Period Start" := AvgCostAdjmtEntryPoint."Valuation Date";
        AvgCostAdjmtEntryPoint.GetValuationPeriod(CalendarPeriod);
        OnAfterGetValuationPeriod(CalendarPeriod, Item);

        ValueEntry.SetCurrentKey("Item No.", "Valuation Date", "Location Code", "Variant Code");
        ValueEntry.SetRange("Item No.", AvgCostAdjmtEntryPoint."Item No.");
        if AvgCostAdjmtEntryPoint.AvgCostCalcTypeIsChanged(CalendarPeriod."Period Start") then begin
            AvgCostAdjmtEntryPoint.GetAvgCostCalcTypeIsChgPeriod(FiscalYearAccPeriod, CalendarPeriod."Period Start");
            ValueEntry.SetRange("Valuation Date", CalendarPeriod."Period Start", CalcDate('<-1D>', FiscalYearAccPeriod."Starting Date"));
        end else
            ValueEntry.SetRange("Valuation Date", CalendarPeriod."Period Start", DMY2Date(31, 12, 9999));

        IsAvgCostCalcTypeItem := AvgCostAdjmtEntryPoint.IsAvgCostCalcTypeItem(CalendarPeriod."Period End");
        if not IsAvgCostCalcTypeItem then begin
            ValueEntry.SetRange("Location Code", AvgCostAdjmtEntryPoint."Location Code");
            ValueEntry.SetRange("Variant Code", AvgCostAdjmtEntryPoint."Variant Code");
        end;
        OnAvgValueEntriesToAdjustExistOnAfterSetAvgValueEntryFilters(ValueEntry);

        if ValueEntry.FindFirst() then begin
            FindNextRange := true;

            if ValueEntry."Valuation Date" > CalendarPeriod."Period End" then begin
                AvgCostAdjmtEntryPoint."Valuation Date" := ValueEntry."Valuation Date";
                CalendarPeriod."Period Start" := ValueEntry."Valuation Date";
                AvgCostAdjmtEntryPoint.GetValuationPeriod(CalendarPeriod);
            end;

            if not (AvgCostAdjmtEntryPoint.ValuationExists(ValueEntry) and
                    AvgCostAdjmtEntryPoint.PrevValuationAdjusted(ValueEntry)) or
               ((ConsumpAdjmtInPeriodWithOutput <> 0D) and
                (ConsumpAdjmtInPeriodWithOutput <= AvgCostAdjmtEntryPoint."Valuation Date"))
            then begin
                AvgCostAdjmtEntryPoint.UpdateValuationDate(ValueEntry);
                exit(false);
            end;

            ValueEntry.SetRange("Valuation Date", CalendarPeriod."Period Start", CalendarPeriod."Period End");
            IsAvgCostCalcTypeItem := AvgCostAdjmtEntryPoint.IsAvgCostCalcTypeItem(CalendarPeriod."Period End");
            if not IsAvgCostCalcTypeItem then begin
                ValueEntry.SetRange("Location Code", AvgCostAdjmtEntryPoint."Location Code");
                ValueEntry.SetRange("Variant Code", AvgCostAdjmtEntryPoint."Variant Code");
            end;
            OnAvgValueEntriesToAdjustExistOnAfterSetChildValueEntryFilters(ValueEntry);

            OutbndValueEntry.Copy(ValueEntry);
            if not OutbndValueEntry.IsEmpty() then begin
                OutbndValueEntry.SetCurrentKey("Item Ledger Entry No.");
                exit(true);
            end;

            DeleteAvgBuffers(OutbndValueEntry, ExcludedValueEntry);
            ValueEntry.FindSet();
            repeat
                if ValueEntry."Entry Type" = ValueEntry."Entry Type"::Revaluation then
                    if ValueEntry."Partial Revaluation" or ItemApplicationEntry.AppliedFromEntryExists(ValueEntry."Item Ledger Entry No.") then begin
                        TempRevaluationPoint.Number := ValueEntry."Entry No.";
                        if TempRevaluationPoint.Insert() then;
                        FillFixApplBuffer(ValueEntry."Item Ledger Entry No.");
                    end;

                if ValueEntry."Valued By Average Cost" and not ValueEntry.Adjustment and (ValueEntry."Valued Quantity" < 0) then begin
                    OutbndValueEntry := ValueEntry;
                    OutbndValueEntry.Insert();
                    FindNextRange := false;
                end;

                OnAvgValueEntriesToAdjustExistOnBeforeIsNotAdjustment(ValueEntry, OutbndValueEntry);
                if not ValueEntry.Adjustment then
                    if IsAvgCostException(ValueEntry, IsAvgCostCalcTypeItem) then begin
                        TempAvgCostExceptionBuf.Number := ValueEntry."Entry No.";
                        if TempAvgCostExceptionBuf.Insert() then;
                        TempAvgCostExceptionBuf.Number += 1;
                        if TempAvgCostExceptionBuf.Insert() then;
                    end;

                ExcludedValueEntry := ValueEntry;
                ExcludedValueEntry.Insert();
            until ValueEntry.Next() = 0;
            FetchOpenItemEntriesToExclude(AvgCostAdjmtEntryPoint, ExcludedValueEntry, TempOpenItemLedgEntry, CalendarPeriod);
        end;

        if FindNextRange then
            if AvgCostAdjmtEntryPoint."Valuation Date" < PeriodPageMgt.EndOfPeriod() then begin
                AvgCostAdjmtEntryPoint."Valuation Date" := GetNextDate(AvgCostAdjmtEntryPoint."Valuation Date");
                OnAvgValueEntriesToAdjustExistOnFindNextRangeOnBeforeAvgValueEntriesToAdjustExist(OutbndValueEntry, ExcludedValueEntry, AvgCostAdjmtEntryPoint);
                AvgValueEntriesToAdjustExist(OutbndValueEntry, ExcludedValueEntry, AvgCostAdjmtEntryPoint);
            end;
        exit(not OutbndValueEntry.IsEmpty() and not ValueEntry.IsEmpty);
    end;

    local procedure GetNextDate(CurrentDate: Date): Date
    begin
        if CurrentDate = 0D then
            exit(00020101D);
        exit(CalcDate('<+1D>', CurrentDate));
    end;

    local procedure AdjustOutbndAvgEntry(var OutbndValueEntry: Record "Value Entry"; var ExcludedValueEntry: Record "Value Entry")
    var
        OutbndItemLedgEntry: Record "Item Ledger Entry";
        TempOldCostElementBuf: Record "Cost Element Buffer" temporary;
        TempNewCostElementBuf: Record "Cost Element Buffer" temporary;
        EntryAdjusted: Boolean;
    begin
        OutbndItemLedgEntry.Get(OutbndValueEntry."Item Ledger Entry No.");
        if OutbndItemLedgEntry."Applies-to Entry" <> 0 then
            exit;
        if ExpCostIsCompletelyInvoiced(OutbndItemLedgEntry, OutbndValueEntry) then
            exit;

        UpDateWindow(
          WindowAdjmtLevel, WindowItem, WindowAdjust, WindowFWLevel, OutbndValueEntry."Item Ledger Entry No.", WindowOutbndEntry);

        EntryAdjusted := OutbndItemLedgEntry.SetAvgTransCompletelyInvoiced();

        if CalcAvgCost(OutbndValueEntry, TempNewCostElementBuf, ExcludedValueEntry) then begin
            CalcOutbndDocOldCost(TempOldCostElementBuf, OutbndValueEntry, false);
            if OutbndValueEntry."Expected Cost" then begin
                TempNewCostElementBuf."Actual Cost" -= TempOldCostElementBuf."Expected Cost";
                TempNewCostElementBuf."Actual Cost (ACY)" -= TempOldCostElementBuf."Expected Cost (ACY)";
            end else begin
                TempNewCostElementBuf."Actual Cost" -= TempOldCostElementBuf."Actual Cost";
                TempNewCostElementBuf."Actual Cost (ACY)" -= TempOldCostElementBuf."Actual Cost (ACY)";
                OnAdjustOutbndAvgEntryOnNewCostElementBuf(OutbndValueEntry);
            end;
            if UpdateAdjmtBuf(
                 OutbndValueEntry,
                 TempNewCostElementBuf."Actual Cost", TempNewCostElementBuf."Actual Cost (ACY)",
                 OutbndItemLedgEntry."Posting Date", OutbndValueEntry."Entry Type")
            then
                EntryAdjusted := true;
        end;

        if EntryAdjusted then begin
            if OutbndItemLedgEntry."Entry Type" = OutbndItemLedgEntry."Entry Type"::Consumption then
                OutbndItemLedgEntry.SetAppliedEntryToAdjust(false);

            OnAdjustOutbndAvgEntryOnBeforeForwardAvgCostToInbndEntries(OutbndItemLedgEntry);
            ForwardAvgCostToInbndEntries(OutbndItemLedgEntry."Entry No.");
        end;
    end;

    procedure ExpCostIsCompletelyInvoiced(ItemLedgEntry: Record "Item Ledger Entry"; ValueEntry: Record "Value Entry"): Boolean
    begin
        exit(ValueEntry."Expected Cost" and (ItemLedgEntry.Quantity = ItemLedgEntry."Invoiced Quantity"));
    end;

    local procedure CalcAvgCost(OutbndValueEntry: Record "Value Entry"; var CostElementBuf: Record "Cost Element Buffer"; var ExcludedValueEntry: Record "Value Entry"): Boolean
    var
        ValueEntry: Record "Value Entry";
        RoundingError: Decimal;
        RoundingErrorACY: Decimal;
    begin
        if OutbndValueEntry."Entry No." >= AvgCostBuf."Last Valid Value Entry No" then begin
            ValueEntry.SumCostsTillValuationDate(OutbndValueEntry);
            TempInvtAdjmtBuf.SumCostsTillValuationDate(OutbndValueEntry);
            CostElementBuf."Remaining Quantity" := ValueEntry."Item Ledger Entry Quantity";
            CostElementBuf."Actual Cost" :=
              ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)" +
              TempInvtAdjmtBuf."Cost Amount (Actual)" + TempInvtAdjmtBuf."Cost Amount (Expected)";
            CostElementBuf."Actual Cost (ACY)" :=
              ValueEntry."Cost Amount (Actual) (ACY)" + ValueEntry."Cost Amount (Expected) (ACY)" +
              TempInvtAdjmtBuf."Cost Amount (Actual) (ACY)" + TempInvtAdjmtBuf."Cost Amount (Expected) (ACY)";

            RoundingError := 0;
            RoundingErrorACY := 0;
            OnCalcAvgCostOnAfterAssignRoundingError(RoundingError, RoundingErrorACY, CostElementBuf);

            ExcludeAvgCostOnValuationDate(CostElementBuf, OutbndValueEntry, ExcludedValueEntry);
            AvgCostBuf.UpdateAvgCostBuffer(
              CostElementBuf, GetLastValidValueEntry(OutbndValueEntry."Entry No."));
        end else
            CostElementBuf.UpdateCostElementBuffer(AvgCostBuf);

        if CostElementBuf."Remaining Quantity" > 0 then begin
            AvgCostBuf."Rounding Residual" := RoundingError;
            AvgCostBuf."Rounding Residual (ACY)" := RoundingErrorACY;
            RoundCost(
              CostElementBuf."Actual Cost", AvgCostBuf."Rounding Residual", CostElementBuf."Actual Cost",
              OutbndValueEntry."Valued Quantity" / CostElementBuf."Remaining Quantity",
              GLSetup."Amount Rounding Precision");
            RoundCost(
              CostElementBuf."Actual Cost (ACY)", AvgCostBuf."Rounding Residual (ACY)", CostElementBuf."Actual Cost (ACY)",
              OutbndValueEntry."Valued Quantity" / CostElementBuf."Remaining Quantity",
              Currency."Amount Rounding Precision");

            AvgCostBuf.DeductOutbndValueEntryFromBuf(OutbndValueEntry, CostElementBuf, IsAvgCostCalcTypeItem);
        end;

        exit(CostElementBuf."Remaining Quantity" > 0);
    end;

    local procedure ExcludeAvgCostOnValuationDate(var CostElementBuf: Record "Cost Element Buffer"; OutbndValueEntry: Record "Value Entry"; var ExcludedValueEntry: Record "Value Entry")
    var
        OutbndItemLedgEntry: Record "Item Ledger Entry";
        TempItemLedgEntryInChain: Record "Item Ledger Entry" temporary;
        FirstValueEntry: Record "Value Entry";
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
        ExcludeILE: Boolean;
        ExcludeEntry: Boolean;
        FixedApplication: Boolean;
        PreviousILENo: Integer;
        RevalFixedApplnQty: Decimal;
        ExclusionFactor: Decimal;
    begin
        ExcludedValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        OutbndItemLedgEntry.Get(OutbndValueEntry."Item Ledger Entry No.");
        GetChainOfAppliedEntries(OutbndItemLedgEntry, TempItemLedgEntryInChain, true);
        OnAfterGetVisitedEntries(ExcludedValueEntry, OutbndValueEntry, TempItemLedgEntryInChain);

        TempItemLedgEntryInChain.Reset();
        TempItemLedgEntryInChain.SetCurrentKey("Item No.", Positive, "Location Code", "Variant Code");
        TempItemLedgEntryInChain.SetRange("Item No.", ExcludedValueEntry."Item No.");
        TempItemLedgEntryInChain.SetRange(Positive, true);
        if not AvgCostAdjmtEntryPoint.IsAvgCostCalcTypeItem(ExcludedValueEntry."Valuation Date") then begin
            TempItemLedgEntryInChain.SetRange("Location Code", ExcludedValueEntry."Location Code");
            TempItemLedgEntryInChain.SetRange("Variant Code", ExcludedValueEntry."Variant Code");
        end;
        OnExcludeAvgCostOnValuationDateOnAfterSetItemLedgEntryInChainFilters(TempItemLedgEntryInChain);

        PreviousILENo := 0;
        if ExcludedValueEntry.FindSet() then
            repeat
                // Execute this block for the first Value Entry for each ILE
                if PreviousILENo <> ExcludedValueEntry."Item Ledger Entry No." then begin
                    // Calculate whether a Value Entry should be excluded from average cost calculation based on ILE information
                    // All fixed application entries (except revaluation) are included in the buffer because the inbound and outbound entries cancel each other
                    FixedApplication := false;
                    ExcludeILE := IsExcludeILEFromAvgCostCalc(ExcludedValueEntry, OutbndValueEntry, TempItemLedgEntryInChain, FixedApplication);
                    PreviousILENo := ExcludedValueEntry."Item Ledger Entry No.";
                    if (ExcludedValueEntry."Entry Type" = ExcludedValueEntry."Entry Type"::"Direct Cost") and (ExcludedValueEntry."Item Charge No." = '') then
                        FirstValueEntry := ExcludedValueEntry
                    else begin
                        FirstValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
                        FirstValueEntry.SetRange("Item Ledger Entry No.", ExcludedValueEntry."Item Ledger Entry No.");
                        FirstValueEntry.SetRange("Entry Type", ExcludedValueEntry."Entry Type"::"Direct Cost");
                        FirstValueEntry.SetRange("Item Charge No.", '');
                        FirstValueEntry.FindFirst();
                    end;
                end;

                ExcludeEntry := ExcludeILE;

                if FixedApplication then begin
                    // If a revaluation entry should normally be excluded, but has a partial fixed application to an outbound, then the fixed applied portion should still be included in the buffer
                    if ExcludedValueEntry."Entry Type" = ExcludedValueEntry."Entry Type"::Revaluation then
                        if IsExcludeFromAvgCostForRevalPoint(ExcludedValueEntry, OutbndValueEntry) then begin
                            RevalFixedApplnQty := CalcRevalFixedApplnQty(ExcludedValueEntry);
                            if RevalFixedApplnQty <> ExcludedValueEntry."Valued Quantity" then begin
                                ExcludeEntry := true;
                                ExclusionFactor := (ExcludedValueEntry."Valued Quantity" - RevalFixedApplnQty) / ExcludedValueEntry."Valued Quantity";
                                ExcludedValueEntry."Cost Amount (Actual)" := RoundAmt(ExclusionFactor * ExcludedValueEntry."Cost Amount (Actual)", GLSetup."Amount Rounding Precision");
                                ExcludedValueEntry."Cost Amount (Expected)" :=
                                  RoundAmt(ExclusionFactor * ExcludedValueEntry."Cost Amount (Expected)", GLSetup."Amount Rounding Precision");
                                ExcludedValueEntry."Cost Amount (Actual) (ACY)" :=
                                  RoundAmt(ExclusionFactor * ExcludedValueEntry."Cost Amount (Actual) (ACY)", Currency."Amount Rounding Precision");
                                ExcludedValueEntry."Cost Amount (Expected) (ACY)" :=
                                  RoundAmt(ExclusionFactor * ExcludedValueEntry."Cost Amount (Expected) (ACY)", Currency."Amount Rounding Precision");
                            end;
                        end;
                end else
                    // For non-fixed applied entries
                    // For each value entry, perform additional check if there has been a revaluation in the period
                    if not ExcludeEntry then
                        // For non-revaluation entries, exclusion decision is based on the date of the first posted Direct Cost entry for the ILE to ensure all cost modifiers except revaluation
                        // are included or excluded based on the original item posting date
                        if ExcludedValueEntry."Entry Type" = ExcludedValueEntry."Entry Type"::Revaluation then
                            ExcludeEntry := IsExcludeFromAvgCostForRevalPoint(ExcludedValueEntry, OutbndValueEntry)
                        else
                            ExcludeEntry := IsExcludeFromAvgCostForRevalPoint(FirstValueEntry, OutbndValueEntry);

                if ExcludeEntry then begin
                    CostElementBuf.ExcludeEntryFromAvgCostCalc(ExcludedValueEntry);
                    if TempInvtAdjmtBuf.Get(ExcludedValueEntry."Entry No.") then
                        CostElementBuf.ExcludeBufFromAvgCostCalc(TempInvtAdjmtBuf);
                end;
            until ExcludedValueEntry.Next() = 0;
    end;

    local procedure IsExcludeILEFromAvgCostCalc(ValueEntry: Record "Value Entry"; OutbndValueEntry: Record "Value Entry"; var ItemLedgEntryInChain: Record "Item Ledger Entry"; var FixedApplication: Boolean): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        if TempOpenItemLedgEntry.Get(ValueEntry."Item Ledger Entry No.") then
            exit(true);
        // fixed application is taken out
        if TempFixApplBuffer.Get(ValueEntry."Item Ledger Entry No.") then begin
            FixedApplication := true;
            exit(false);
        end;

        if ValueEntry."Item Ledger Entry No." = OutbndValueEntry."Item Ledger Entry No." then
            exit(true);

        ItemLedgEntry.Get(ValueEntry."Item Ledger Entry No.");

        if IsOutputWithSelfConsumption(ValueEntry, OutbndValueEntry, ItemLedgEntryInChain) then
            exit(true);

        if ItemLedgEntryInChain.Get(ValueEntry."Item Ledger Entry No.") then
            exit(true);

        if not ValueEntry."Valued By Average Cost" then
            exit(false);

        if not ItemLedgEntryInChain.IsEmpty() then
            exit(true);

        if not ItemLedgEntry.Positive then
            exit(ValueEntry."Item Ledger Entry No." > OutbndValueEntry."Item Ledger Entry No.");

        exit(false);
    end;

    local procedure IsExcludeFromAvgCostForRevalPoint(var RevaluationCheckValueEntry: Record "Value Entry"; var OutbndValueEntry: Record "Value Entry"): Boolean
    begin
        TempRevaluationPoint.SetRange(Number, RevaluationCheckValueEntry."Entry No.", OutbndValueEntry."Entry No.");
        if not TempRevaluationPoint.IsEmpty() then
            exit(not IncludedInCostCalculation(RevaluationCheckValueEntry, OutbndValueEntry."Item Ledger Entry No."));

        TempRevaluationPoint.SetRange(Number, OutbndValueEntry."Entry No.", RevaluationCheckValueEntry."Entry No.");
        if not TempRevaluationPoint.IsEmpty() then
            exit(true);
    end;

    local procedure CalcRevalFixedApplnQty(RevaluationValueEntry: Record "Value Entry"): Decimal
    var
        ItemApplicationEntry: Record "Item Application Entry";
        FixedApplQty: Decimal;
    begin
        ItemApplicationEntry.SetCurrentKey("Inbound Item Entry No.", "Outbound Item Entry No.");
        ItemApplicationEntry.SetRange("Inbound Item Entry No.", RevaluationValueEntry."Item Ledger Entry No.");
        ItemApplicationEntry.SetFilter("Outbound Item Entry No.", '<>%1', 0);
        if ItemApplicationEntry.FindSet() then
            repeat
                if IncludedInCostCalculation(RevaluationValueEntry, ItemApplicationEntry."Outbound Item Entry No.") and
                   TempFixApplBuffer.Get(ItemApplicationEntry."Outbound Item Entry No.")
                then
                    FixedApplQty -= ItemApplicationEntry.Quantity;
            until ItemApplicationEntry.Next() = 0;

        exit(FixedApplQty);
    end;

    local procedure UpdateAvgCostAdjmtEntryPoint(ValueEntry: Record "Value Entry")
    var
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
    begin
        AvgCostAdjmtEntryPoint.UpdateValuationDate(ValueEntry);
    end;

    local procedure UpdateConsumpAvgEntry(ValueEntry: Record "Value Entry")
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ConsumpItemLedgEntry: Record "Item Ledger Entry";
        AvgCostAdjmtPoint: Record "Avg. Cost Adjmt. Entry Point";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateConsumpAvgEntry(ValueEntry, IsHandled);
        if IsHandled then
            exit;

        // Determine if average costed consumption is completely invoiced
        if ValueEntry."Item Ledger Entry Type" <> ValueEntry."Item Ledger Entry Type"::Consumption then
            exit;

        ConsumpItemLedgEntry.SetLoadFields("Completely Invoiced", "Applied Entry to Adjust");
        ConsumpItemLedgEntry.Get(ValueEntry."Item Ledger Entry No.");
        if not ConsumpItemLedgEntry."Completely Invoiced" then
            if not IsDeletedItem then begin
                ItemLedgEntry.SetCurrentKey("Item No.", "Entry Type", "Variant Code", "Drop Shipment", "Location Code", "Posting Date");
                ItemLedgEntry.SetRange("Item No.", ValueEntry."Item No.");
                if not AvgCostAdjmtPoint.IsAvgCostCalcTypeItem(ValueEntry."Valuation Date") then begin
                    ItemLedgEntry.SetRange("Variant Code", ValueEntry."Variant Code");
                    ItemLedgEntry.SetRange("Location Code", ValueEntry."Location Code");
                end;
                ItemLedgEntry.SetRange("Posting Date", 0D, ValueEntry."Valuation Date");
                OnUpdateConsumpAvgEntryOnAfterSetItemLedgEntryFilters(ItemLedgEntry);
                ItemLedgEntry.CalcSums("Invoiced Quantity");
                if ItemLedgEntry."Invoiced Quantity" >= 0 then begin
                    ConsumpItemLedgEntry.SetCompletelyInvoiced();
                    ConsumpItemLedgEntry.SetAppliedEntryToAdjust(false);
                end;
            end else begin
                ConsumpItemLedgEntry.SetCompletelyInvoiced();
                ConsumpItemLedgEntry.SetAppliedEntryToAdjust(false);
            end;
    end;

    local procedure ForwardAvgCostToInbndEntries(ItemLedgEntryNo: Integer)
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        if ItemApplnEntry.AppliedInbndEntryExists(ItemLedgEntryNo, true) then
            repeat
                LevelNo[3] := 0;
                AdjustAppliedInbndEntries(ItemApplnEntry);
                if LevelExceeded then begin
                    LevelExceeded := false;

                    UpDateWindow(WindowAdjmtLevel, WindowItem, WindowAdjust, LevelNo[3], WindowEntry, WindowOutbndEntry);
                    AdjustItemAppliedCost();
                    UpDateWindow(WindowAdjmtLevel, WindowItem, Text008, WindowFWLevel, WindowEntry, WindowOutbndEntry);
                end;
            until ItemApplnEntry.Next() = 0;
    end;

    local procedure WIPToAdjustExist(var ToInventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"): Boolean
    var
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
    begin
        InventoryAdjmtEntryOrder.Reset();
        InventoryAdjmtEntryOrder.SetCurrentKey("Cost is Adjusted", "Allow Online Adjustment");
        InventoryAdjmtEntryOrder.SetRange("Cost is Adjusted", false);
        InventoryAdjmtEntryOrder.SetRange("Order Type", InventoryAdjmtEntryOrder."Order Type"::Production);
        InventoryAdjmtEntryOrder.SetRange("Is Finished", true);
        if IsOnlineAdjmt then
            InventoryAdjmtEntryOrder.SetRange("Allow Online Adjustment", true);

        OnWIPToAdjustExistOnAfterInventoryAdjmtEntryOrderSetFilters(InventoryAdjmtEntryOrder);
        CopyOrderAdmtEntryToOrderAdjmt(InventoryAdjmtEntryOrder, ToInventoryAdjmtEntryOrder);
        exit(ToInventoryAdjmtEntryOrder.FindFirst())
    end;

    local procedure MakeWIPAdjmt(var SourceInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var TempAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point" temporary)
    var
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        CalcInventoryAdjmtOrder: Codeunit "Calc. Inventory Adjmt. - Order";
        DoNotSkipItems: Boolean;
    begin
        DoNotSkipItems := FilterItem.GetFilters = '';
        if SourceInvtAdjmtEntryOrder.FindSet() then
            repeat
                if true in [DoNotSkipItems, ItemInFilteredSetExists(SourceInvtAdjmtEntryOrder."Item No.", FilterItem)] then begin
                    GetItem(SourceInvtAdjmtEntryOrder."Item No.");
                    UpDateWindow(WindowAdjmtLevel, SourceInvtAdjmtEntryOrder."Item No.", Text009, 0, 0, 0);

                    InvtAdjmtEntryOrder := SourceInvtAdjmtEntryOrder;
                    CalcInventoryAdjmtOrder.Calculate(SourceInvtAdjmtEntryOrder, TempInvtAdjmtBuf);
                    PostOutputAdjmtBuf(TempAvgCostAdjmtEntryPoint);

                    if not SourceInvtAdjmtEntryOrder."Completely Invoiced" then begin
                        InvtAdjmtEntryOrder.GetUnitCostsFromItem();
                        InvtAdjmtEntryOrder."Completely Invoiced" := true;
                    end;
                    InvtAdjmtEntryOrder."Cost is Adjusted" := true;
                    InvtAdjmtEntryOrder."Allow Online Adjustment" := true;
                    InvtAdjmtEntryOrder.Modify();
                end;
            until SourceInvtAdjmtEntryOrder.Next() = 0;
    end;

    local procedure ItemInFilteredSetExists(ItemNo: Code[20]; var FilteredItem: Record Item): Boolean
    var
        TempItem: Record Item temporary;
        Item: Record Item;
    begin
        if not Item.Get(ItemNo) then
            exit(false);
        TempItem.CopyFilters(FilteredItem);
        TempItem := Item;
        TempItem.Insert();
        exit(not TempItem.IsEmpty());
    end;

    local procedure PostOutputAdjmtBuf(var TempAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point" temporary)
    begin
        TempInvtAdjmtBuf.Reset();
        if TempInvtAdjmtBuf.FindSet() then
            repeat
                PostOutput(TempInvtAdjmtBuf, TempAvgCostAdjmtEntryPoint);
            until TempInvtAdjmtBuf.Next() = 0;
        TempInvtAdjmtBuf.DeleteAll();
    end;

    local procedure PostOutput(InvtAdjmtBuf: Record "Inventory Adjustment Buffer"; var TempAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point" temporary)
    var
        ItemJnlLine: Record "Item Journal Line";
        OrigItemLedgEntry: Record "Item Ledger Entry";
        OrigValueEntry: Record "Value Entry";
        IsHandled: Boolean;
    begin
        OrigValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        OrigValueEntry.SetRange("Item Ledger Entry No.", TempInvtAdjmtBuf."Item Ledger Entry No.");
        OrigValueEntry.FindFirst();

        ItemJnlLine.Init();
        ItemJnlLine."Value Entry Type" := InvtAdjmtBuf."Entry Type";
        ItemJnlLine."Variance Type" := InvtAdjmtBuf."Variance Type";
        ItemJnlLine."Invoiced Quantity" := OrigValueEntry."Item Ledger Entry Quantity";
        ItemJnlLine."Invoiced Qty. (Base)" := OrigValueEntry."Item Ledger Entry Quantity";
        ItemJnlLine."Qty. per Unit of Measure" := 1;
        ItemJnlLine."Source Type" := OrigValueEntry."Source Type";
        ItemJnlLine."Source No." := OrigValueEntry."Source No.";
        ItemJnlLine.Description := OrigValueEntry.Description;
        ItemJnlLine.Adjustment := OrigValueEntry."Order Type" = OrigValueEntry."Order Type"::Assembly;
        OrigItemLedgEntry.Get(OrigValueEntry."Item Ledger Entry No.");
        ItemJnlLine.Adjustment := (OrigValueEntry."Order Type" = OrigValueEntry."Order Type"::Assembly) and (OrigItemLedgEntry."Invoiced Quantity" <> 0);

        IsHandled := false;
        OnPostOutputOnBeforePostItemJnlLine(ItemJnlLine, OrigValueEntry, InvtAdjmtBuf, GLSetup, IsHandled);
        if not IsHandled then
            PostItemJnlLine(ItemJnlLine, OrigValueEntry, InvtAdjmtBuf."Cost Amount (Actual)", InvtAdjmtBuf."Cost Amount (Actual) (ACY)");

        OrigItemLedgEntry.Get(OrigValueEntry."Item Ledger Entry No.");
        if not OrigItemLedgEntry."Completely Invoiced" then
            OrigItemLedgEntry.SetCompletelyInvoiced();

        InsertEntryPointToUpdate(TempAvgCostAdjmtEntryPoint, OrigValueEntry."Item No.", OrigValueEntry."Variant Code", OrigValueEntry."Location Code");
    end;

    local procedure AssemblyToAdjustExists(var ToInventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"): Boolean
    var
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
    begin
        InventoryAdjmtEntryOrder.Reset();
        InventoryAdjmtEntryOrder.SetCurrentKey("Cost is Adjusted", "Allow Online Adjustment");
        InventoryAdjmtEntryOrder.SetRange("Cost is Adjusted", false);
        InventoryAdjmtEntryOrder.SetRange("Order Type", InventoryAdjmtEntryOrder."Order Type"::Assembly);
        if IsOnlineAdjmt then
            InventoryAdjmtEntryOrder.SetRange("Allow Online Adjustment", true);

        CopyOrderAdmtEntryToOrderAdjmt(InventoryAdjmtEntryOrder, ToInventoryAdjmtEntryOrder);
        exit(ToInventoryAdjmtEntryOrder.FindFirst())
    end;

    local procedure MakeAssemblyAdjmt(var SourceInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var TempAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point" temporary)
    var
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        CalcInventoryAdjmtOrder: Codeunit "Calc. Inventory Adjmt. - Order";
        DoNotSkipItems: Boolean;
    begin
        DoNotSkipItems := FilterItem.GetFilters = '';
        if SourceInvtAdjmtEntryOrder.FindSet() then
            repeat
                if true in [DoNotSkipItems, ItemInFilteredSetExists(SourceInvtAdjmtEntryOrder."Item No.", FilterItem)] then begin
                    GetItem(SourceInvtAdjmtEntryOrder."Item No.");
                    UpDateWindow(WindowAdjmtLevel, SourceInvtAdjmtEntryOrder."Item No.", Text010, 0, 0, 0);

                    InvtAdjmtEntryOrder := SourceInvtAdjmtEntryOrder;
                    if not Item."Inventory Value Zero" then begin
                        CalcInventoryAdjmtOrder.Calculate(SourceInvtAdjmtEntryOrder, TempInvtAdjmtBuf);
                        PostOutputAdjmtBuf(TempAvgCostAdjmtEntryPoint);
                    end;

                    if not SourceInvtAdjmtEntryOrder."Completely Invoiced" then begin
                        InvtAdjmtEntryOrder.GetCostsFromItem(1);
                        InvtAdjmtEntryOrder."Completely Invoiced" := true;
                    end;
                    InvtAdjmtEntryOrder."Allow Online Adjustment" := true;
                    InvtAdjmtEntryOrder."Cost is Adjusted" := true;
                    InvtAdjmtEntryOrder.Modify();
                end;
            until SourceInvtAdjmtEntryOrder.Next() = 0;
    end;

    local procedure UpdateAdjmtBuf(OrigValueEntry: Record "Value Entry"; NewAdjustedCost: Decimal; NewAdjustedCostACY: Decimal; ItemLedgEntryPostingDate: Date; EntryType: Enum "Cost Entry Type") Result: Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemApplnEntry: Record "Item Application Entry";
        SourceOrigValueEntry: Record "Value Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAdjmtBuf(OrigValueEntry, NewAdjustedCost, NewAdjustedCostACY, ItemLedgEntryPostingDate, EntryType, Result, IsHandled, Item);
        if IsHandled then
            exit(Result);

        if not HasNewCost(NewAdjustedCost, NewAdjustedCostACY) then
            exit(false);

        if OrigValueEntry."Valued By Average Cost" then begin
            TempAvgCostRndgBuf.UpdRoundingCheck(
              OrigValueEntry."Item Ledger Entry No.", NewAdjustedCost, NewAdjustedCostACY,
              GLSetup."Amount Rounding Precision", Currency."Amount Rounding Precision");
            if TempAvgCostRndgBuf."No. of Hits" > MaxRoundings then
                exit(false);
        end;

        UpdateValuationPeriodHasOutput(OrigValueEntry);

        TempInvtAdjmtBuf.AddActualCostBuf(OrigValueEntry, NewAdjustedCost, NewAdjustedCostACY, ItemLedgEntryPostingDate);
        OnUpdateAdjmtBufOnAfterAddActualCostBuf(OrigValueEntry, NewAdjustedCost, NewAdjustedCostACY, ItemLedgEntryPostingDate, TempInvtAdjmtBuf);

        if EntryType = OrigValueEntry."Entry Type"::Variance then begin
            GetOrigValueEntry(SourceOrigValueEntry, OrigValueEntry, EntryType);
            TempInvtAdjmtBuf."Entry Type" := EntryType;
            TempInvtAdjmtBuf."Variance Type" := SourceOrigValueEntry."Variance Type";
            TempInvtAdjmtBuf.Modify();
        end;

        if not OrigValueEntry."Expected Cost" and
           (OrigValueEntry."Entry Type" = OrigValueEntry."Entry Type"::"Direct Cost")
        then begin
            CalcExpectedCostToBalance(OrigValueEntry, NewAdjustedCost, NewAdjustedCostACY);
            IsHandled := false;
            OnUpdateAdjmtBufOnBeforeHasNewCost(OrigValueEntry, NewAdjustedCost, NewAdjustedCostACY, ItemLedgEntryPostingDate, EntryType, IsHandled, TempInvtAdjmtBuf, Item);
            if not IsHandled then
                if HasNewCost(NewAdjustedCost, NewAdjustedCostACY) then
                    TempInvtAdjmtBuf.AddBalanceExpectedCostBuf(OrigValueEntry, NewAdjustedCost, NewAdjustedCostACY);
        end;

        if OrigValueEntry."Item Ledger Entry Quantity" >= 0 then begin
            ItemLedgEntry.Get(OrigValueEntry."Item Ledger Entry No.");
            ItemApplnEntry.SetOutboundsNotUpdated(ItemLedgEntry);
        end;
        exit(true);
    end;

    local procedure CalcExpectedCostToBalance(OrigValueEntry: Record "Value Entry"; var ExpectedCost: Decimal; var ExpectedCostACY: Decimal)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ShareOfTotalCost: Decimal;
    begin
        ExpectedCost := 0;
        ExpectedCostACY := 0;
        ItemLedgEntry.Get(OrigValueEntry."Item Ledger Entry No.");

        TempInvtAdjmtBuf.Reset();
        TempInvtAdjmtBuf.SetCurrentKey("Item Ledger Entry No.");
        TempInvtAdjmtBuf.SetRange("Item Ledger Entry No.", OrigValueEntry."Item Ledger Entry No.");
        if TempInvtAdjmtBuf.FindFirst() and TempInvtAdjmtBuf."Expected Cost" then begin
            TempInvtAdjmtBuf.CalcSums("Cost Amount (Expected)", TempInvtAdjmtBuf."Cost Amount (Expected) (ACY)");

            if ItemLedgEntry.Quantity = ItemLedgEntry."Invoiced Quantity" then begin
                ExpectedCost := -TempInvtAdjmtBuf."Cost Amount (Expected)";
                ExpectedCostACY := -TempInvtAdjmtBuf."Cost Amount (Expected) (ACY)";
            end else begin
                ShareOfTotalCost := OrigValueEntry."Invoiced Quantity" / ItemLedgEntry.Quantity;
                ExpectedCost :=
                  -RoundAmt(TempInvtAdjmtBuf."Cost Amount (Expected)" * ShareOfTotalCost, GLSetup."Amount Rounding Precision");
                ExpectedCostACY :=
                  -RoundAmt(TempInvtAdjmtBuf."Cost Amount (Expected) (ACY)" * ShareOfTotalCost, Currency."Amount Rounding Precision");
            end;
        end;
    end;

    local procedure PostAdjmtBuf(var TempAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point" temporary)
    var
        ItemJnlLine: Record "Item Journal Line";
        OrigValueEntry: Record "Value Entry";
    begin
        TempInvtAdjmtBuf.Reset();
        if TempInvtAdjmtBuf.FindSet() then begin
            repeat
                OrigValueEntry.Get(TempInvtAdjmtBuf."Entry No.");
                InsertEntryPointToUpdate(
                  TempAvgCostAdjmtEntryPoint, OrigValueEntry."Item No.", OrigValueEntry."Variant Code", OrigValueEntry."Location Code");
                if OrigValueEntry."Expected Cost" then begin
                    if HasNewCost(TempInvtAdjmtBuf."Cost Amount (Expected)", TempInvtAdjmtBuf."Cost Amount (Expected) (ACY)") then begin
                        InitAdjmtJnlLine(ItemJnlLine, OrigValueEntry, TempInvtAdjmtBuf."Entry Type", TempInvtAdjmtBuf."Variance Type", OrigValueEntry."Invoiced Quantity");
                        PostItemJnlLine(ItemJnlLine, OrigValueEntry, TempInvtAdjmtBuf."Cost Amount (Expected)", TempInvtAdjmtBuf."Cost Amount (Expected) (ACY)");

                        OnPostAdjmtBufOnAfterPostExpectedCost(OrigValueEntry, TempInvtAdjmtBuf);
                    end
                end else
                    if HasNewCost(TempInvtAdjmtBuf."Cost Amount (Actual)", TempInvtAdjmtBuf."Cost Amount (Actual) (ACY)") then begin
                        if HasNewCost(TempInvtAdjmtBuf."Cost Amount (Expected)", TempInvtAdjmtBuf."Cost Amount (Expected) (ACY)") then begin
                            InitAdjmtJnlLine(ItemJnlLine, OrigValueEntry, TempInvtAdjmtBuf."Entry Type", TempInvtAdjmtBuf."Variance Type", 0);
                            PostItemJnlLine(ItemJnlLine, OrigValueEntry, TempInvtAdjmtBuf."Cost Amount (Expected)", TempInvtAdjmtBuf."Cost Amount (Expected) (ACY)");
                        end;
                        InitAdjmtJnlLine(ItemJnlLine, OrigValueEntry, TempInvtAdjmtBuf."Entry Type", TempInvtAdjmtBuf."Variance Type", OrigValueEntry."Invoiced Quantity");
                        PostItemJnlLine(ItemJnlLine, OrigValueEntry, TempInvtAdjmtBuf."Cost Amount (Actual)", TempInvtAdjmtBuf."Cost Amount (Actual) (ACY)");

                        OnPostAdjmtBufOnAfterPostNewCost(OrigValueEntry, TempInvtAdjmtBuf);
                    end;
            until TempInvtAdjmtBuf.Next() = 0;
            TempInvtAdjmtBuf.DeleteAll();
        end;
    end;

    local procedure InitAdjmtJnlLine(var ItemJnlLine: Record "Item Journal Line"; OrigValueEntry: Record "Value Entry"; EntryType: Enum "Cost Entry Type"; VarianceType: Enum "Cost Variance Type"; InvoicedQty: Decimal)
    begin
        ItemJnlLine."Value Entry Type" := EntryType;
        ItemJnlLine."Partial Revaluation" := OrigValueEntry."Partial Revaluation";
        ItemJnlLine.Description := OrigValueEntry.Description;
        ItemJnlLine."Source Posting Group" := OrigValueEntry."Source Posting Group";
        ItemJnlLine."Source No." := OrigValueEntry."Source No.";
        ItemJnlLine."Salespers./Purch. Code" := OrigValueEntry."Salespers./Purch. Code";
        ItemJnlLine."Source Type" := OrigValueEntry."Source Type";
        ItemJnlLine."Reason Code" := OrigValueEntry."Reason Code";
        ItemJnlLine."Drop Shipment" := OrigValueEntry."Drop Shipment";
        ItemJnlLine."Document Date" := OrigValueEntry."Document Date";
        ItemJnlLine."External Document No." := OrigValueEntry."External Document No.";
        ItemJnlLine."Quantity (Base)" := OrigValueEntry."Valued Quantity";
        ItemJnlLine."Invoiced Qty. (Base)" := InvoicedQty;
        if OrigValueEntry."Item Ledger Entry Type" = OrigValueEntry."Item Ledger Entry Type"::Output then
            ItemJnlLine."Output Quantity (Base)" := ItemJnlLine."Quantity (Base)";
        ItemJnlLine."Item Charge No." := OrigValueEntry."Item Charge No.";
        ItemJnlLine."Variance Type" := VarianceType;
        ItemJnlLine.Adjustment := true;
        ItemJnlLine."Applies-to Value Entry" := OrigValueEntry."Entry No.";
        ItemJnlLine."Return Reason Code" := OrigValueEntry."Return Reason Code";

        OnAfterInitAdjmtJnlLine(ItemJnlLine, OrigValueEntry, EntryType, VarianceType, InvoicedQty);
    end;

    local procedure PostItemJnlLine(ItemJnlLine: Record "Item Journal Line"; OrigValueEntry: Record "Value Entry"; NewAdjustedCost: Decimal; NewAdjustedCostACY: Decimal)
    var
        InvtPeriod: Record "Inventory Period";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemJnlLine(ItemJnlLine, OrigValueEntry, NewAdjustedCost, NewAdjustedCostACY, SkipUpdateJobItemCost, IsHandled);
        if IsHandled then
            exit;

        ItemJnlLine."Item No." := OrigValueEntry."Item No.";
        ItemJnlLine."Location Code" := OrigValueEntry."Location Code";
        ItemJnlLine."Variant Code" := OrigValueEntry."Variant Code";

        if GLSetup.IsPostingAllowed(OrigValueEntry."Posting Date") and InvtPeriod.IsValidDate(OrigValueEntry."Posting Date") then
            ItemJnlLine."Posting Date" := OrigValueEntry."Posting Date"
        else
            ItemJnlLine."Posting Date" := PostingDateForClosedPeriod;
        OnPostItemJnlLineOnAfterSetPostingDate(ItemJnlLine, OrigValueEntry, PostingDateForClosedPeriod, Item);

        ItemJnlLine."Entry Type" := OrigValueEntry."Item Ledger Entry Type";
        ItemJnlLine."Document No." := OrigValueEntry."Document No.";
        ItemJnlLine."Document Type" := OrigValueEntry."Document Type";
        ItemJnlLine."Document Line No." := OrigValueEntry."Document Line No.";
        ItemJnlLine."Source Currency Code" := GLSetup."Additional Reporting Currency";
        ItemJnlLine."Source Code" := SourceCodeSetup."Adjust Cost";
        ItemJnlLine."Inventory Posting Group" := OrigValueEntry."Inventory Posting Group";
        ItemJnlLine."Gen. Bus. Posting Group" := OrigValueEntry."Gen. Bus. Posting Group";
        ItemJnlLine."Gen. Prod. Posting Group" := OrigValueEntry."Gen. Prod. Posting Group";
        ItemJnlLine."Order Type" := OrigValueEntry."Order Type";
        ItemJnlLine."Order No." := OrigValueEntry."Order No.";
        ItemJnlLine."Order Line No." := OrigValueEntry."Order Line No.";
        ItemJnlLine."Job No." := OrigValueEntry."Job No.";
        ItemJnlLine."Job Task No." := OrigValueEntry."Job Task No.";
        ItemJnlLine.Type := OrigValueEntry.Type;
        if ItemJnlLine."Value Entry Type" = ItemJnlLine."Value Entry Type"::"Direct Cost" then
            ItemJnlLine."Item Shpt. Entry No." := OrigValueEntry."Item Ledger Entry No."
        else
            ItemJnlLine."Applies-to Entry" := OrigValueEntry."Item Ledger Entry No.";
        ItemJnlLine.Amount := NewAdjustedCost;
        ItemJnlLine."Amount (ACY)" := NewAdjustedCostACY;

        if ItemJnlLine."Quantity (Base)" <> 0 then begin
            ItemJnlLine."Unit Cost" :=
              RoundAmt(NewAdjustedCost / ItemJnlLine."Quantity (Base)", GLSetup."Unit-Amount Rounding Precision");
            ItemJnlLine."Unit Cost (ACY)" :=
              RoundAmt(NewAdjustedCostACY / ItemJnlLine."Quantity (Base)", Currency."Unit-Amount Rounding Precision");
        end;

        ItemJnlLine."Shortcut Dimension 1 Code" := OrigValueEntry."Global Dimension 1 Code";
        ItemJnlLine."Shortcut Dimension 2 Code" := OrigValueEntry."Global Dimension 2 Code";
        ItemJnlLine."Dimension Set ID" := OrigValueEntry."Dimension Set ID";

        if not SkipUpdateJobItemCost and (OrigValueEntry."Job No." <> '') then
            CopyJobToAdjustmentBuf(OrigValueEntry."Job No.");

        OnPostItemJnlLineCopyFromValueEntry(ItemJnlLine, OrigValueEntry);
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
        OnPostItemJnlLineOnAfterItemJnlPostLineRunWithCheck(ItemJnlLine, OrigValueEntry);
    end;

    local procedure RoundCost(var Cost: Decimal; var RndgResidual: Decimal; TotalCost: Decimal; ShareOfTotalCost: Decimal; AmtRndgPrec: Decimal)
    var
        UnroundedCost: Decimal;
    begin
        UnroundedCost := TotalCost * ShareOfTotalCost + RndgResidual;
        Cost := RoundAmt(UnroundedCost, AmtRndgPrec);
        RndgResidual := UnroundedCost - Cost;
    end;

    local procedure RoundAmt(Amt: Decimal; AmtRndgPrec: Decimal): Decimal
    begin
        if Amt = 0 then
            exit(0);
        exit(Round(Amt, AmtRndgPrec))
    end;

    local procedure GetOrigValueEntry(var OrigValueEntry: Record "Value Entry"; ValueEntry: Record "Value Entry"; ValueEntryType: Enum "Cost Entry Type")
    var
        Found: Boolean;
        IsLastEntry: Boolean;
    begin
        OrigValueEntry.SetCurrentKey("Item Ledger Entry No.", "Document No.");
        OrigValueEntry.SetRange("Item Ledger Entry No.", ValueEntry."Item Ledger Entry No.");
        OrigValueEntry.SetRange("Document No.", ValueEntry."Document No.");

        if OrigValueEntry.FindSet() then
            repeat
                if (OrigValueEntry."Expected Cost" = ValueEntry."Expected Cost") and
                   (OrigValueEntry."Entry Type" = ValueEntryType)
                then begin
                    Found := true;
                    OrigValueEntry."Valued Quantity" := ValueEntry."Valued Quantity";
                    OrigValueEntry."Invoiced Quantity" := ValueEntry."Invoiced Quantity";
                    OnGetOrigValueEntryOnAfterOrigValueEntryFound(OrigValueEntry, ValueEntry);
                end else
                    IsLastEntry := OrigValueEntry.Next() = 0;
            until Found or IsLastEntry;

        if not Found then begin
            OrigValueEntry := ValueEntry;
            OrigValueEntry."Entry Type" := ValueEntryType;
            if ValueEntryType = OrigValueEntry."Entry Type"::Variance then
                OrigValueEntry."Variance Type" := GetOrigVarianceType(ValueEntry);
        end;
    end;

    local procedure GetOrigVarianceType(ValueEntry: Record "Value Entry"): Enum "Cost Variance Type"
    begin
        if ValueEntry."Item Ledger Entry Type" in
           [ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Item Ledger Entry Type"::"Assembly Output"]
        then
            exit(ValueEntry."Variance Type"::Material);

        exit(ValueEntry."Variance Type"::Purchase);
    end;

    local procedure UpdateAppliedEntryToAdjustBuf(ItemLedgerEntry: Record "Item Ledger Entry"; AppliedEntryToAdjust: Boolean)
    begin
        if AppliedEntryToAdjust then begin
            TempItemLedgerEntryBuf := ItemLedgerEntry;
            if TempItemLedgerEntryBuf.Insert() then;
        end;
    end;

    local procedure SetAppliedEntryToAdjustFromBuf(ItemNo: Code[20])
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        TempItemLedgerEntryBuf.Reset();
        if ItemNo <> '' then
            TempItemLedgerEntryBuf.SetRange("Item No.", ItemNo);
        if TempItemLedgerEntryBuf.FindSet() then
            repeat
                ItemLedgEntry.Get(TempItemLedgerEntryBuf."Entry No.");
                ItemLedgEntry.SetAppliedEntryToAdjust(true);
            until TempItemLedgerEntryBuf.Next() = 0;
    end;

    local procedure AppliedEntryToAdjustBufExists(ItemNo: Code[20]): Boolean
    begin
        TempItemLedgerEntryBuf.Reset();
        TempItemLedgerEntryBuf.SetRange("Item No.", ItemNo);
        exit(not TempItemLedgerEntryBuf.IsEmpty());
    end;

    local procedure UpdateItemUnitCost(var TempAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point" temporary; IsFirstTime: Boolean)
    var
        AvgCostAdjmtPoint: Record "Avg. Cost Adjmt. Entry Point";
        FilterSKU: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateItemUnitCost(TempAvgCostAdjmtEntryPoint, IsHandled, Item, TempItemLedgerEntryBuf);
        if IsHandled then
            exit;

        if IsDeletedItem then
            exit;

        Item.LockTable();
        Item.Get(Item."No.");
        OnUpdateItemUnitCostOnAfterItemGet(Item);
        if not LevelExceeded then begin
            Item."Allow Online Adjustment" := true;
            AvgCostAdjmtPoint.SetRange("Item No.", Item."No.");
            AvgCostAdjmtPoint.SetRange("Cost Is Adjusted", false);
            if Item."Costing Method" <> Item."Costing Method"::Average then
                if AvgCostAdjmtPoint.FindFirst() then
                    AvgCostAdjmtPoint.ModifyAll("Cost Is Adjusted", true);
            Item."Cost is Adjusted" := AvgCostAdjmtPoint.IsEmpty();
            if Item."Cost is Adjusted" and (Item."Costing Method" <> Item."Costing Method"::Average) and IsFirstTime then begin
                Item."Cost is Adjusted" := not AppliedEntryToAdjustBufExists(Item."No.");
                SetAppliedEntryToAdjustFromBuf(Item."No.");
            end;
        end;

        if Item."Costing Method" <> Item."Costing Method"::Standard then begin
            if TempAvgCostAdjmtEntryPoint.FindSet() then
                repeat
                    FilterSKU := (TempAvgCostAdjmtEntryPoint."Location Code" <> '') or (TempAvgCostAdjmtEntryPoint."Variant Code" <> '');
                    ItemCostMgt.UpdateUnitCost(
                      Item, TempAvgCostAdjmtEntryPoint."Location Code", TempAvgCostAdjmtEntryPoint."Variant Code", 0, 0, true, FilterSKU, false, 0);
                until TempAvgCostAdjmtEntryPoint.Next() = 0
            else
                Item.Modify();
        end else begin
            OnUpdateItemUnitCostOnBeforeModifyItemNotStandardCostingMethod(Item);
            Item.Modify();
            OnUpdateItemUnitCostOnAfterModifyItemNotStandardCostingMethod(Item);
        end;

        TempAvgCostAdjmtEntryPoint.Reset();
        TempAvgCostAdjmtEntryPoint.DeleteAll();
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        IsDeletedItem := ItemNo = '';
        if (Item."No." <> ItemNo) or IsDeletedItem then
            if not IsDeletedItem then
                Item.Get(ItemNo)
            else begin
                Clear(Item);
                Item.Init();
            end;
    end;

    local procedure InsertDeletedItem(var Item: Record Item)
    begin
        Clear(Item);
        Item.Init();
        Item."Cost is Adjusted" := false;
        Item."Costing Method" := Item."Costing Method"::FIFO;
        Item.Insert();
    end;

    local procedure IsAvgCostItem() AvgCostItem: Boolean
    begin
        AvgCostItem := Item."Costing Method" = Item."Costing Method"::Average;

        OnAfterIsAvgCostItem(Item, AvgCostItem);
    end;

    local procedure HasNewCost(NewCost: Decimal; NewCostACY: Decimal): Boolean
    begin
        exit((NewCost <> 0) or (NewCostACY <> 0));
    end;

    local procedure OpenWindow()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenWindow(IsHandled, Window, WindowIsOpen);
        if IsHandled then
            exit;

        Window.Open(
          Text000 +
          '#1########################\\' +
          Text001 +
          Text003 +
          Text004 +
          Text005 +
          Text006);
        WindowIsOpen := true;
    end;

    local procedure UpDateWindow(NewWindowAdjmtLevel: Integer; NewWindowItem: Code[20]; NewWindowAdjust: Text[20]; NewWindowFWLevel: Integer; NewWindowEntry: Integer; NewWindowOutbndEntry: Integer)
    var
        IsHandled: Boolean;
    begin
        WindowAdjmtLevel := NewWindowAdjmtLevel;
        WindowItem := NewWindowItem;
        WindowAdjust := NewWindowAdjust;
        WindowFWLevel := NewWindowFWLevel;
        WindowEntry := NewWindowEntry;
        WindowOutbndEntry := NewWindowOutbndEntry;

        IsHandled := false;
        OnBeforeUpdateWindow(IsHandled);
        if IsHandled then
            exit;

        if IsTimeForUpdate() then begin
            if not WindowIsOpen then
                OpenWindow();

            IsHandled := false;
            OnUpdateWindowOnAfterOpenWindow(IsHandled);
            if IsHandled then
                exit;

            Window.Update(1, StrSubstNo(Text002, TempInvtAdjmtBuf.FieldCaption("Item No."), WindowItem));
            Window.Update(2, WindowAdjmtLevel);
            Window.Update(3, WindowAdjust);
            Window.Update(4, WindowFWLevel);
            Window.Update(5, WindowEntry);
            Window.Update(6, WindowOutbndEntry);
        end;
    end;

    local procedure IsTimeForUpdate(): Boolean
    begin
        if CurrentDateTime - WindowUpdateDateTime >= 1000 then begin
            WindowUpdateDateTime := CurrentDateTime;
            exit(true);
        end;
        exit(false);
    end;

    local procedure CopyItemToItem(var FromItem: Record Item; var ToItem: Record Item)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyItemToItem(FromItem, ToItem, IsHandled);
        if IsHandled then
            exit;

        ToItem.Reset();
        ToItem.DeleteAll();
        if FromItem.FindSet() then
            repeat
                ToItem := FromItem;
                ToItem.Insert();
            until FromItem.Next() = 0;
    end;

    local procedure CopyAvgCostAdjmtToAvgCostAdjmt(var FromAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point"; var ToAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point")
    begin
        ToAvgCostAdjmtEntryPoint.Reset();
        ToAvgCostAdjmtEntryPoint.DeleteAll();
        if FromAvgCostAdjmtEntryPoint.FindSet() then
            repeat
                ToAvgCostAdjmtEntryPoint := FromAvgCostAdjmtEntryPoint;
                ToAvgCostAdjmtEntryPoint.Insert();
                OnCopyAvgCostAdjmtToAvgCostAdjmtOnAfterInsert(ToAvgCostAdjmtEntryPoint);
            until FromAvgCostAdjmtEntryPoint.Next() = 0;
    end;

    local procedure CopyOrderAdmtEntryToOrderAdjmt(var FromInventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var ToInventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    begin
        ToInventoryAdjmtEntryOrder.Reset();
        ToInventoryAdjmtEntryOrder.DeleteAll();
        if FromInventoryAdjmtEntryOrder.FindSet() then
            repeat
                ToInventoryAdjmtEntryOrder := FromInventoryAdjmtEntryOrder;
                ToInventoryAdjmtEntryOrder.Insert();
            until FromInventoryAdjmtEntryOrder.Next() = 0;
    end;

    local procedure AdjustNotInvdRevaluation(TransItemLedgEntry: Record "Item Ledger Entry"; TransItemApplnEntry: Record "Item Application Entry")
    var
        TransValueEntry: Record "Value Entry";
        OrigItemLedgEntry: Record "Item Ledger Entry";
        CostElementBuf: Record "Cost Element Buffer";
        AdjustedCostElementBuf: Record "Cost Element Buffer";
    begin
        if TransValueEntry.NotInvdRevaluationExists(TransItemLedgEntry."Entry No.") then begin
            GetOrigPosItemLedgEntryNo(TransItemApplnEntry);
            OrigItemLedgEntry.Get(TransItemApplnEntry."Item Ledger Entry No.");
            repeat
                CalcTransEntryNewRevAmt(OrigItemLedgEntry, TransValueEntry, AdjustedCostElementBuf);
                CalcTransEntryOldRevAmt(TransValueEntry, CostElementBuf);

                UpdateAdjmtBuf(
                  TransValueEntry,
                  AdjustedCostElementBuf."Actual Cost" - CostElementBuf."Actual Cost",
                  AdjustedCostElementBuf."Actual Cost (ACY)" - CostElementBuf."Actual Cost (ACY)",
                  TransItemLedgEntry."Posting Date",
                  TransValueEntry."Entry Type");
            until TransValueEntry.Next() = 0;
        end;
    end;

    local procedure GetOrigPosItemLedgEntryNo(var ItemApplnEntry: Record "Item Application Entry")
    begin
        ItemApplnEntry.SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.");
        ItemApplnEntry.SetRange("Item Ledger Entry No.", ItemApplnEntry."Transferred-from Entry No.");
        ItemApplnEntry.SetRange("Inbound Item Entry No.", ItemApplnEntry."Transferred-from Entry No.");
        ItemApplnEntry.FindFirst();
        if ItemApplnEntry."Transferred-from Entry No." <> 0 then
            GetOrigPosItemLedgEntryNo(ItemApplnEntry);
    end;

    local procedure CalcTransEntryNewRevAmt(ItemLedgEntry: Record "Item Ledger Entry"; TransValueEntry: Record "Value Entry"; var AdjustedCostElementBuf: Record "Cost Element Buffer")
    var
        ValueEntry: Record "Value Entry";
        InvdQty: Decimal;
        OrigInvdQty: Decimal;
        ShareOfRevExpAmt: Decimal;
        OrigShareOfRevExpAmt: Decimal;
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetRange("Item Charge No.", '');
        if ValueEntry.FindSet() then
            repeat
                InvdQty := InvdQty + ValueEntry."Invoiced Quantity";
                if ValueEntry."Entry No." < TransValueEntry."Entry No." then
                    OrigInvdQty := OrigInvdQty + ValueEntry."Invoiced Quantity";
            until ValueEntry.Next() = 0;

        ShareOfRevExpAmt := (ItemLedgEntry.Quantity - InvdQty) / ItemLedgEntry.Quantity;
        OrigShareOfRevExpAmt := (ItemLedgEntry.Quantity - OrigInvdQty) / ItemLedgEntry.Quantity;

        if TempInvtAdjmtBuf.Get(TransValueEntry."Entry No.") then
            TransValueEntry.AddCost(TempInvtAdjmtBuf);
        AdjustedCostElementBuf."Actual Cost" := Round(
            (ShareOfRevExpAmt - OrigShareOfRevExpAmt) * TransValueEntry."Cost Amount (Actual)", GLSetup."Amount Rounding Precision");
        AdjustedCostElementBuf."Actual Cost (ACY)" := Round(
            (ShareOfRevExpAmt - OrigShareOfRevExpAmt) *
            TransValueEntry."Cost Amount (Actual) (ACY)", Currency."Amount Rounding Precision");
    end;

    local procedure CalcTransEntryOldRevAmt(TransValueEntry: Record "Value Entry"; var CostElementBuf: Record "Cost Element Buffer")
    begin
        Clear(CostElementBuf);
        TransValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        TransValueEntry.SetRange("Item Ledger Entry No.", TransValueEntry."Item Ledger Entry No.");
        TransValueEntry.SetRange("Entry Type", TransValueEntry."Entry Type"::Revaluation);
        TransValueEntry.SetRange("Applies-to Entry", TransValueEntry."Entry No.");
        if TransValueEntry.FindSet() then
            repeat
                if TempInvtAdjmtBuf.Get(TransValueEntry."Entry No.") then
                    TransValueEntry.AddCost(TempInvtAdjmtBuf);
                CostElementBuf."Actual Cost" := CostElementBuf."Actual Cost" + TransValueEntry."Cost Amount (Actual)";
                CostElementBuf."Actual Cost (ACY)" := CostElementBuf."Actual Cost (ACY)" + TransValueEntry."Cost Amount (Actual) (ACY)";
            until TransValueEntry.Next() = 0;
    end;

    local procedure IsInterimRevaluation(InbndValueEntry: Record "Value Entry"): Boolean
    begin
        exit(
              (InbndValueEntry."Entry Type" = InbndValueEntry."Entry Type"::Revaluation) and
              ((InbndValueEntry."Cost Amount (Expected)" <> 0) or (InbndValueEntry."Cost Amount (Expected) (ACY)" <> 0)));
    end;

    local procedure OutboundSalesEntryToAdjust(ItemLedgEntry: Record "Item Ledger Entry"): Boolean
    var
        ItemApplnEntry: Record "Item Application Entry";
        InbndItemLedgEntry: Record "Item Ledger Entry";
    begin
        if not ItemLedgEntry.IsOutbndSale() then
            exit(false);

        ItemApplnEntry.Reset();
        ItemApplnEntry.SetCurrentKey(
          "Outbound Item Entry No.", "Item Ledger Entry No.", "Cost Application", "Transferred-from Entry No.");
        ItemApplnEntry.SetRange("Outbound Item Entry No.", ItemLedgEntry."Entry No.");
        ItemApplnEntry.SetFilter("Item Ledger Entry No.", '<>%1', ItemLedgEntry."Entry No.");
        ItemApplnEntry.SetRange("Transferred-from Entry No.", 0);
        if ItemApplnEntry.FindSet() then
            repeat
                if InbndItemLedgEntry.Get(ItemApplnEntry."Inbound Item Entry No.") then
                    if not InbndItemLedgEntry."Completely Invoiced" then
                        exit(true);
            until ItemApplnEntry.Next() = 0;

        exit(false);
    end;

    local procedure InboundTransferEntryToAdjust(ItemLedgEntry: Record "Item Ledger Entry"): Boolean
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        if (ItemLedgEntry."Entry Type" <> ItemLedgEntry."Entry Type"::Transfer) or not ItemLedgEntry.Positive or
           ItemLedgEntry."Completely Invoiced"
        then
            exit(false);

        ItemApplnEntry.SetRange("Inbound Item Entry No.", ItemLedgEntry."Entry No.");
        ItemApplnEntry.SetFilter("Item Ledger Entry No.", '<>%1', ItemLedgEntry."Entry No.");
        ItemApplnEntry.SetRange("Transferred-from Entry No.", 0);
        exit(not ItemApplnEntry.IsEmpty());
    end;

    procedure SetJobUpdateProperties(SkipJobUpdate: Boolean)
    begin
        SkipUpdateJobItemCost := SkipJobUpdate;
    end;

    local procedure GetLastValidValueEntry(ValueEntryNo: Integer): Integer
    var
        "Integer": Record "Integer";
    begin
        TempAvgCostExceptionBuf.SetFilter(TempAvgCostExceptionBuf.Number, '>%1', ValueEntryNo);
        if not TempAvgCostExceptionBuf.FindFirst() then begin
            Integer.FindLast();
            TempAvgCostExceptionBuf.SetRange(TempAvgCostExceptionBuf.Number);
            exit(Integer.Number);
        end;
        exit(TempAvgCostExceptionBuf.Number);
    end;

    local procedure FillFixApplBuffer(ItemLedgerEntryNo: Integer)
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        if not TempFixApplBuffer.Get(ItemLedgerEntryNo) then
            if ItemApplnEntry.AppliedOutbndEntryExists(ItemLedgerEntryNo, true, false) then begin
                TempFixApplBuffer.Number := ItemLedgerEntryNo;
                TempFixApplBuffer.Insert();
                repeat
                    // buffer is filled with couple of entries which are applied and contains revaluation
                    TempFixApplBuffer.Number := ItemApplnEntry."Item Ledger Entry No.";
                    if TempFixApplBuffer.Insert() then;
                until ItemApplnEntry.Next() = 0;
            end;
    end;

    local procedure UpdateJobItemCost()
    var
        JobsSetup: Record "Jobs Setup";
        Job: Record Job;
        UpdateJobItemCost: Report "Update Job Item Cost";
    begin
        OnBeforeUpdateJobItemCost(TempJobToAdjustBuf);

        if JobsSetup.Get() then
            if JobsSetup."Automatic Update Job Item Cost" then
                if TempJobToAdjustBuf.FindSet() then
                    repeat
                        Job.SetRange("No.", TempJobToAdjustBuf."No.");
                        Clear(UpdateJobItemCost);
                        UpdateJobItemCost.SetTableView(Job);
                        UpdateJobItemCost.UseRequestPage := false;
                        UpdateJobItemCost.SetProperties(true);
                        UpdateJobItemCost.RunModal();
                    until TempJobToAdjustBuf.Next() = 0;
    end;

    local procedure FetchOpenItemEntriesToExclude(AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point"; var ExcludedValueEntry: Record "Value Entry"; var OpenEntries: Record "Integer" temporary; CalendarPeriod: Record Date)
    var
        OpenItemLedgEntry: Record "Item Ledger Entry";
        TempItemLedgEntryInChain: Record "Item Ledger Entry" temporary;
    begin
        OpenEntries.Reset();
        OpenEntries.DeleteAll();

        if OpenOutbndItemLedgEntriesExist(OpenItemLedgEntry, AvgCostAdjmtEntryPoint, CalendarPeriod) then
            repeat
                CopyOpenItemLedgEntryToBuf(OpenEntries, ExcludedValueEntry, OpenItemLedgEntry."Entry No.", CalendarPeriod."Period Start");
                GetChainOfAppliedEntries(OpenItemLedgEntry, TempItemLedgEntryInChain, false);
                if TempItemLedgEntryInChain.FindSet() then
                    repeat
                        CopyOpenItemLedgEntryToBuf(
                          OpenEntries, ExcludedValueEntry, TempItemLedgEntryInChain."Entry No.", CalendarPeriod."Period Start");
                    until TempItemLedgEntryInChain.Next() = 0;
            until OpenItemLedgEntry.Next() = 0;
    end;

    local procedure OpenOutbndItemLedgEntriesExist(var OpenItemLedgEntry: Record "Item Ledger Entry"; AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point"; CalendarPeriod: Record Date): Boolean
    begin
        OpenItemLedgEntry.SetCurrentKey("Item No.", Open, "Variant Code", Positive);
        OpenItemLedgEntry.SetRange("Item No.", AvgCostAdjmtEntryPoint."Item No.");
        OpenItemLedgEntry.SetRange(Open, true);
        OpenItemLedgEntry.SetRange(Positive, false);
        if not AvgCostAdjmtEntryPoint.IsAvgCostCalcTypeItem(CalendarPeriod."Period End") then begin
            OpenItemLedgEntry.SetRange("Location Code", AvgCostAdjmtEntryPoint."Location Code");
            OpenItemLedgEntry.SetRange("Variant Code", AvgCostAdjmtEntryPoint."Variant Code");
        end;
        OnOpenOutbndItemLedgEntriesExistOnAfterSetOpenItemLedgEntryFilters(OpenItemLedgEntry);
        exit(OpenItemLedgEntry.FindSet());
    end;

    local procedure ResetAvgBuffers(var OutbndValueEntry: Record "Value Entry"; var ExcludedValueEntry: Record "Value Entry")
    begin
        OutbndValueEntry.Reset();
        ExcludedValueEntry.Reset();
        TempAvgCostExceptionBuf.Reset();
        TempRevaluationPoint.Reset();
        TempValueEntryCalcdOutbndCostBuf.Reset();
        AvgCostBuf.Initialize(true);
    end;

    local procedure DeleteAvgBuffers(var OutbndValueEntry: Record "Value Entry"; var ExcludedValueEntry: Record "Value Entry")
    begin
        ResetAvgBuffers(OutbndValueEntry, ExcludedValueEntry);
        AvgCostBuf.Initialize(false);
        OutbndValueEntry.DeleteAll();
        ExcludedValueEntry.DeleteAll();
        TempAvgCostExceptionBuf.DeleteAll();
        TempRevaluationPoint.DeleteAll();
        TempValueEntryCalcdOutbndCostBuf.DeleteAll();
    end;

    local procedure InsertEntryPointToUpdate(var TempAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point" temporary; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    begin
        TempAvgCostAdjmtEntryPoint."Item No." := ItemNo;
        TempAvgCostAdjmtEntryPoint."Variant Code" := VariantCode;
        TempAvgCostAdjmtEntryPoint."Location Code" := LocationCode;
        TempAvgCostAdjmtEntryPoint."Valuation Date" := 0D;
        if TempAvgCostAdjmtEntryPoint.Insert() then;
    end;

    local procedure UpdateValuationPeriodHasOutput(ValueEntry: Record "Value Entry")
    var
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
        OutputValueEntry: Record "Value Entry";
        CalendarPeriod: Record Date;
    begin
        if ValueEntry."Item Ledger Entry Type" in
           [ValueEntry."Item Ledger Entry Type"::Consumption,
            ValueEntry."Item Ledger Entry Type"::"Assembly Consumption"]
        then
            if AvgCostAdjmtEntryPoint.ValuationExists(ValueEntry) then begin
                if (ConsumpAdjmtInPeriodWithOutput <> 0D) and
                   (ConsumpAdjmtInPeriodWithOutput <= AvgCostAdjmtEntryPoint."Valuation Date")
                then
                    exit;

                CalendarPeriod."Period Start" := AvgCostAdjmtEntryPoint."Valuation Date";
                AvgCostAdjmtEntryPoint.GetValuationPeriod(CalendarPeriod);

                OutputValueEntry.SetCurrentKey("Item No.", "Valuation Date");
                OutputValueEntry.SetRange("Item No.", ValueEntry."Item No.");
                OutputValueEntry.SetRange("Valuation Date", AvgCostAdjmtEntryPoint."Valuation Date", CalendarPeriod."Period End");

                OutputValueEntry.SetFilter(
                  OutputValueEntry."Item Ledger Entry Type", '%1|%2',
                  OutputValueEntry."Item Ledger Entry Type"::Output,
                  OutputValueEntry."Item Ledger Entry Type"::"Assembly Output");
                if not OutputValueEntry.IsEmpty() then
                    ConsumpAdjmtInPeriodWithOutput := AvgCostAdjmtEntryPoint."Valuation Date";
            end;
    end;

    local procedure CopyOpenItemLedgEntryToBuf(var OpenEntries: Record "Integer" temporary; var ExcludedValueEntry: Record "Value Entry"; OpenItemLedgEntryNo: Integer; PeriodStart: Date)
    begin
        if CollectOpenValueEntries(ExcludedValueEntry, OpenItemLedgEntryNo, PeriodStart) then begin
            OpenEntries.Number := OpenItemLedgEntryNo;
            if OpenEntries.Insert() then;
        end;
    end;

    local procedure CollectOpenValueEntries(var ExcludedValueEntry: Record "Value Entry"; ItemLedgerEntryNo: Integer; PeriodStart: Date) FoundEntries: Boolean
    var
        OpenValueEntry: Record "Value Entry";
    begin
        OpenValueEntry.SetCurrentKey("Item Ledger Entry No.", "Valuation Date");
        OpenValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
        OpenValueEntry.SetFilter("Valuation Date", '<%1', PeriodStart);
        FoundEntries := OpenValueEntry.FindSet();
        if FoundEntries then
            repeat
                ExcludedValueEntry := OpenValueEntry;
                if ExcludedValueEntry.Insert() then;
            until OpenValueEntry.Next() = 0;
    end;

    local procedure CopyJobToAdjustmentBuf(JobNo: Code[20])
    begin
        TempJobToAdjustBuf."No." := JobNo;
        if TempJobToAdjustBuf.Insert() then;
    end;

    local procedure UseStandardCostMirroring(ItemLedgEntry: Record "Item Ledger Entry"): Boolean
    var
        ReturnShipmentLine: Record "Return Shipment Line";
        EntryNo: Integer;
    begin
        if (ItemLedgEntry."Entry Type" <> ItemLedgEntry."Entry Type"::Purchase) or
           (ItemLedgEntry."Document Type" <> ItemLedgEntry."Document Type"::"Purchase Return Shipment")
        then
            exit(false);

        EntryNo := ItemLedgEntry."Entry No.";
        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("Document No.", "Document Type", "Document Line No.");
        ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type");
        ItemLedgEntry.SetRange("Document No.", ItemLedgEntry."Document No.");
        ItemLedgEntry.SetFilter("Document Line No.", '<>%1', ItemLedgEntry."Document Line No.");
        ItemLedgEntry.SetRange("Item No.", ItemLedgEntry."Item No.");
        ItemLedgEntry.SetRange(Correction, true);
        ItemLedgEntry.SetLoadFields("Document No.", "Document Line No.");
        if ItemLedgEntry.FindSet() then
            repeat
                ReturnShipmentLine.Get(ItemLedgEntry."Document No.", ItemLedgEntry."Document Line No.");
                if ReturnShipmentLine."Appl.-to Item Entry" = EntryNo then
                    exit(true);
            until ItemLedgEntry.Next() = 0;
        exit(false);
    end;

    local procedure IsOutputWithSelfConsumption(InbndValueEntry: Record "Value Entry"; OutbndValueEntry: Record "Value Entry"; var ItemLedgEntryInChain: Record "Item Ledger Entry"): Boolean
    var
        ConsumpItemLedgEntry: Record "Item Ledger Entry";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ConsumpValueEntry: Record "Value Entry";
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
        AvgCostValuePeriodDate: Record Date;
    begin
        if not (InbndValueEntry."Item Ledger Entry Type" in
                [InbndValueEntry."Item Ledger Entry Type"::Output,
                 InbndValueEntry."Item Ledger Entry Type"::"Assembly Output"])
        then
            exit(false);

        if not (OutbndValueEntry."Item Ledger Entry Type" in
                [OutbndValueEntry."Item Ledger Entry Type"::Consumption,
                 OutbndValueEntry."Item Ledger Entry Type"::"Assembly Consumption"])
        then
            exit(false);

        if not AvgCostAdjmtEntryPoint.ValuationExists(InbndValueEntry) then
            exit(false);

        AvgCostValuePeriodDate."Period Start" := AvgCostAdjmtEntryPoint."Valuation Date";
        AvgCostAdjmtEntryPoint.GetValuationPeriod(AvgCostValuePeriodDate);

        ConsumpValueEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.");
        ConsumpValueEntry.SetRange("Order Type", InbndValueEntry."Order Type");
        ConsumpValueEntry.SetRange("Order No.", InbndValueEntry."Order No.");
        if InbndValueEntry."Order Type" = InbndValueEntry."Order Type"::Production then
            ConsumpValueEntry.SetRange("Order Line No.", InbndValueEntry."Order Line No.");

        ConsumpValueEntry.SetRange("Item No.", InbndValueEntry."Item No."); // self-consumption
        ConsumpValueEntry.SetRange("Valuation Date", AvgCostAdjmtEntryPoint."Valuation Date", AvgCostValuePeriodDate."Period End");
        ConsumpValueEntry.SetFilter(
          ConsumpValueEntry."Item Ledger Entry Type", '%1|%2',
          ConsumpValueEntry."Item Ledger Entry Type"::Consumption, ConsumpValueEntry."Item Ledger Entry Type"::"Assembly Consumption");
        if not AvgCostAdjmtEntryPoint.IsAvgCostCalcTypeItem(InbndValueEntry."Valuation Date") then begin
            ConsumpValueEntry.SetRange("Variant Code", InbndValueEntry."Variant Code");
            ConsumpValueEntry.SetRange("Location Code", InbndValueEntry."Location Code");
        end;
        OnIsOutputWithSelfConsumptionOnAfterSetConsumpValueEntryFilters(ConsumpValueEntry);

        if ConsumpValueEntry.FindFirst() then begin
            ConsumpItemLedgEntry.Get(ConsumpValueEntry."Item Ledger Entry No.");
            GetChainOfAppliedEntries(ConsumpItemLedgEntry, TempItemLedgEntry, true);

            TempItemLedgEntry.Reset();
            TempItemLedgEntry.SetRange("Item No.", ConsumpValueEntry."Item No.");
            if not AvgCostAdjmtEntryPoint.IsAvgCostCalcTypeItem(InbndValueEntry."Valuation Date") then begin
                TempItemLedgEntry.SetRange("Location Code", ConsumpValueEntry."Location Code");
                TempItemLedgEntry.SetRange("Variant Code", ConsumpValueEntry."Variant Code");
            end;
            OnIsOutputWithSelfConsumptionOnAfterSetTempItemLedgEntryFilter(TempItemLedgEntry);

            if TempItemLedgEntry.FindSet() then
                repeat
                    ItemLedgEntryInChain := TempItemLedgEntry;
                    if ItemLedgEntryInChain.Insert() then;
                until TempItemLedgEntry.Next() = 0;
            exit(true);
        end;

        exit(false);
    end;

    local procedure RestoreValuesFromBuffers(var OutbndCostElementBuf: Record "Cost Element Buffer"; var AdjustedCostElementBuf: Record "Cost Element Buffer"; OutbndItemLedgEntryNo: Integer): Boolean
    begin
        TempValueEntryCalcdOutbndCostBuf.Reset();
        TempValueEntryCalcdOutbndCostBuf.SetRange("Item Ledger Entry No.", OutbndItemLedgEntryNo);
        if TempValueEntryCalcdOutbndCostBuf.IsEmpty() then
            exit(false);

        TempValueEntryCalcdOutbndCostBuf.FindSet();
        CopyValueEntryBufToCostElementBuf(OutbndCostElementBuf, TempValueEntryCalcdOutbndCostBuf);

        TempValueEntryCalcdOutbndCostBuf.Next();
        repeat
            CopyValueEntryBufToCostElementBuf(AdjustedCostElementBuf, TempValueEntryCalcdOutbndCostBuf);
        until TempValueEntryCalcdOutbndCostBuf.Next() = 0;

        exit(true);
    end;

    local procedure SaveValuesToBuffers(var OutbndCostElementBuf: Record "Cost Element Buffer"; var AdjustedCostElementBuf: Record "Cost Element Buffer"; OutbndItemLedgEntryNo: Integer)
    begin
        if AdjustedCostElementBuf.IsEmpty() then
            exit;

        CopyCostElementBufToValueEntryBuf(TempValueEntryCalcdOutbndCostBuf, OutbndCostElementBuf, OutbndItemLedgEntryNo);
        AdjustedCostElementBuf.FindSet();
        repeat
            CopyCostElementBufToValueEntryBuf(TempValueEntryCalcdOutbndCostBuf, AdjustedCostElementBuf, OutbndItemLedgEntryNo);
        until AdjustedCostElementBuf.Next() = 0;
    end;

    local procedure CopyCostElementBufToValueEntryBuf(var ValueEntryBuf: Record "Value Entry"; CostElementBuffer: Record "Cost Element Buffer"; ItemLedgEntryNo: Integer)
    var
        EntryNo: Integer;
    begin
        ValueEntryBuf.Reset();
        if ValueEntryBuf.FindLast() then
            EntryNo := ValueEntryBuf."Entry No.";

        ValueEntryBuf.Init();
        ValueEntryBuf."Entry No." := EntryNo + 1;
        ValueEntryBuf."Entry Type" := CostElementBuffer.Type;
        ValueEntryBuf."Variance Type" := CostElementBuffer."Variance Type";
        ValueEntryBuf."Item Ledger Entry No." := ItemLedgEntryNo;
        ValueEntryBuf."Cost Amount (Actual)" := CostElementBuffer."Actual Cost";
        ValueEntryBuf."Cost Amount (Actual) (ACY)" := CostElementBuffer."Actual Cost (ACY)";
        ValueEntryBuf."Cost Amount (Expected)" := CostElementBuffer."Expected Cost";
        ValueEntryBuf."Cost Amount (Expected) (ACY)" := CostElementBuffer."Expected Cost (ACY)";
        ValueEntryBuf."Cost Amount (Non-Invtbl.)" := CostElementBuffer."Rounding Residual";
        ValueEntryBuf."Cost Amount (Non-Invtbl.)(ACY)" := CostElementBuffer."Rounding Residual (ACY)";
        ValueEntryBuf."Invoiced Quantity" := CostElementBuffer."Invoiced Quantity";
        ValueEntryBuf."Valued Quantity" := CostElementBuffer."Remaining Quantity";
        ValueEntryBuf."Expected Cost" := CostElementBuffer."Inbound Completely Invoiced";
        OnCopyCostElementBufToValueEntryBufOnBeforeValueEntryBufInsert(ValueEntryBuf, CostElementBuffer);
        ValueEntryBuf.Insert();
    end;

    local procedure CopyValueEntryBufToCostElementBuf(var CostElementBuffer: Record "Cost Element Buffer"; ValueEntryBuf: Record "Value Entry")
    begin
        CostElementBuffer.Init();
        CostElementBuffer.Type := ValueEntryBuf."Entry Type";
        CostElementBuffer."Variance Type" := ValueEntryBuf."Variance Type";
        CostElementBuffer."Actual Cost" := ValueEntryBuf."Cost Amount (Actual)";
        CostElementBuffer."Actual Cost (ACY)" := ValueEntryBuf."Cost Amount (Actual) (ACY)";
        CostElementBuffer."Expected Cost" := ValueEntryBuf."Cost Amount (Expected)";
        CostElementBuffer."Expected Cost (ACY)" := ValueEntryBuf."Cost Amount (Expected) (ACY)";
        CostElementBuffer."Rounding Residual" := ValueEntryBuf."Cost Amount (Non-Invtbl.)";
        CostElementBuffer."Rounding Residual (ACY)" := ValueEntryBuf."Cost Amount (Non-Invtbl.)(ACY)";
        CostElementBuffer."Invoiced Quantity" := ValueEntryBuf."Invoiced Quantity";
        CostElementBuffer."Remaining Quantity" := ValueEntryBuf."Valued Quantity";
        CostElementBuffer."Inbound Completely Invoiced" := ValueEntryBuf."Expected Cost";
        OnCopyValueEntryBufToCostElementBufOnBeforeCostElementBufferInsert(CostElementBuffer, ValueEntryBuf);
        CostElementBuffer.Insert();
    end;

    local procedure ClearOutboundEntryCostBuffer(InboundEntryNo: Integer)
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        if ItemApplicationEntry.AppliedOutbndEntryExists(InboundEntryNo, false, false) then
            repeat
                TempValueEntryCalcdOutbndCostBuf.Reset();
                TempValueEntryCalcdOutbndCostBuf.SetRange("Item Ledger Entry No.", ItemApplicationEntry."Outbound Item Entry No.");
                if not TempValueEntryCalcdOutbndCostBuf.IsEmpty() then
                    TempValueEntryCalcdOutbndCostBuf.DeleteAll();
            until ItemApplicationEntry.Next() = 0;
    end;

    local procedure EntriesForDeletedItemsExist(): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetCurrentKey("Item No.", "Applied Entry to Adjust");
        ItemLedgerEntry.SetRange("Item No.", '');
        ItemLedgerEntry.SetRange("Applied Entry to Adjust", true);
        exit(not ItemLedgerEntry.IsEmpty());
    end;

    local procedure GetChainOfAppliedEntries(FromItemLedgerEntry: Record "Item Ledger Entry"; var TempItemLedgerEntryChain: Record "Item Ledger Entry" temporary; WithinValuationDate: Boolean)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemApplnEntry: Record "Item Application Entry";
        ListOfEntries: List of [Integer];
        EntryNo: Integer;
    begin
        if ItemApplicationChain.ContainsKey(FromItemLedgerEntry."Entry No.") then begin
            TempItemLedgerEntryChain.Reset();
            TempItemLedgerEntryChain.DeleteAll();
            foreach EntryNo in ItemApplicationChain.Get(FromItemLedgerEntry."Entry No.") do begin
                ItemLedgerEntry.Get(EntryNo);
                TempItemLedgerEntryChain := ItemLedgerEntry;
                if TempItemLedgerEntryChain.Insert() then;
            end;
        end else begin
            ItemApplnEntry.GetVisitedEntries(FromItemLedgerEntry, TempItemLedgerEntryChain, WithinValuationDate);
            if TempItemLedgerEntryChain.FindSet() then begin
                repeat
                    ListOfEntries.Add(TempItemLedgerEntryChain."Entry No.");
                until TempItemLedgerEntryChain.Next() = 0;
                ItemApplicationChain.Add(FromItemLedgerEntry."Entry No.", ListOfEntries);
            end;
        end;
    end;

    local procedure IsAvgCostException(ValueEntry: Record "Value Entry"; AvgCostByItem: Boolean): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
    begin
        if ValueEntry."Partial Revaluation" then
            exit(true);
        if ValueEntry."Item Charge No." <> '' then
            exit(true);

        ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.");
        if ItemLedgerEntry.Positive then
            exit(false);

        GetChainOfAppliedEntries(ItemLedgerEntry, TempItemLedgerEntry, true);
        TempItemLedgerEntry.SetRange("Item No.", ValueEntry."Item No.");
        TempItemLedgerEntry.SetRange(Positive, true);
        if not AvgCostByItem then begin
            TempItemLedgerEntry.SetRange("Location Code", ValueEntry."Location Code");
            TempItemLedgerEntry.SetRange("Variant Code", ValueEntry."Variant Code");
        end;
        exit(not TempItemLedgerEntry.IsEmpty());
    end;

    local procedure CollectItemLedgerEntryTypesUsed(ItemNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.CollectItemLedgerEntryTypesUsed(ItemLedgerEntryTypesUsed, StrSubstNo('''%1''', ItemNo));
    end;

    local procedure ItemLedgerEntryTypeIsUsed(ItemLedgerEntryType: Enum "Item Ledger Entry Type"): Boolean
    begin
        if not ItemLedgerEntryTypesUsed.ContainsKey(ItemLedgerEntryType) then
            exit(true);

        exit(ItemLedgerEntryTypesUsed.Get(ItemLedgerEntryType));
    end;

    // Extension interface for local procedures

    procedure CallInitializeAdjmt()
    begin
        InitializeAdjmt();
    end;

    procedure CallFinalizeAdjmt()
    begin
        FinalizeAdjmt();
    end;

    procedure CallInvtToAdjustExist(var ToItem: Record Item): Boolean
    begin
        exit(InvtToAdjustExist(ToItem));
    end;

    procedure CallMakeSingleLevelAdjmt(var TheItem: Record Item; var TempAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point" temporary)
    begin
        MakeSingleLevelAdjmt(TheItem, TempAvgCostAdjmtEntryPoint);
    end;

    procedure CallWIPToAdjustExist(var ToInventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"): Boolean
    begin
        exit(WIPToAdjustExist(ToInventoryAdjmtEntryOrder));
    end;

    procedure CallMakeWIPAdjmt(var SourceInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var TempAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point" temporary)
    begin
        MakeWIPAdjmt(SourceInvtAdjmtEntryOrder, TempAvgCostAdjmtEntryPoint);
    end;

    procedure CallAssemblyToAdjustExists(var ToInventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"): Boolean
    begin
        exit(AssemblyToAdjustExists(ToInventoryAdjmtEntryOrder));
    end;

    procedure CallMakeAssemblyAdjmt(var SourceInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var TempAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point" temporary)
    begin
        MakeAssemblyAdjmt(SourceInvtAdjmtEntryOrder, TempAvgCostAdjmtEntryPoint);
    end;

    procedure CallUpdateAdjmtBuf(OrigValueEntry: Record "Value Entry"; NewAdjustedCost: Decimal; NewAdjustedCostACY: Decimal; ItemLedgEntryPostingDate: Date; EntryType: Enum "Cost Entry Type"): Boolean
    begin
        exit(UpdateAdjmtBuf(OrigValueEntry, NewAdjustedCost, NewAdjustedCostACY, ItemLedgEntryPostingDate, EntryType));
    end;

    procedure CallPostAdjmtBuf(var TempAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point" temporary)
    begin
        PostAdjmtBuf(TempAvgCostAdjmtEntryPoint);
    end;

    procedure CallPostOutputAdjmtBuf(var TempAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point" temporary)
    begin
        PostOutputAdjmtBuf(TempAvgCostAdjmtEntryPoint);
    end;

    procedure CallSetAppliedEntryToAdjustFromBuf(ItemNo: Code[20])
    begin
        SetAppliedEntryToAdjustFromBuf(ItemNo);
    end;

    procedure CallAppliedEntryToAdjustBufExists(ItemNo: Code[20]): Boolean
    begin
        exit(AppliedEntryToAdjustBufExists((ItemNo)));
    end;

    procedure CallUpdateJobItemCost()
    begin
        UpdateJobItemCost();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCalcInbndEntryAdjustedCost(var AdjustedCostElementBuf: Record "Cost Element Buffer"; var InbndValueEntry: Record "Value Entry"; InbndItemLedgEntry: Record "Item Ledger Entry"; ItemApplnEntry: Record "Item Application Entry"; OutbndItemLedgEntryNo: Integer; var CompletelyInvoiced: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAdjustOutbndAvgEntryOnBeforeForwardAvgCostToInbndEntries(var OutbndItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAdjustItemAvgCostOnAfterLastTempAvgCostAdjmtEntryPoint(var TempAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point" temporary; var Restart: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAdjustItemAvgCostOnAfterCalcRestart(var TempExcludedValueEntry: Record "Value Entry" temporary; var Restart: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAvgValueEntriesToAdjustExistOnAfterSetAvgValueEntryFilters(var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAvgValueEntriesToAdjustExistOnAfterSetChildValueEntryFilters(var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAvgValueEntriesToAdjustExistOnFindNextRangeOnBeforeAvgValueEntriesToAdjustExist(var OutbndValueEntry: Record "Value Entry"; var ExcludedValueEntry: Record "Value Entry"; var AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetValuationPeriod(var CalendarPeriod: Record Date; Item: record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVisitedEntries(var ExcludedValueEntry: Record "Value Entry"; OutbndValueEntry: Record "Value Entry"; var ItemLedgEntryInChain: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsAvgCostItem(var Item: Record Item; var AvgCostItem: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMakeMultiLevelAdjmt(var Item: Record Item; IsOnlineAdjmt: Boolean; PostToGL: Boolean; var FilterItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInbndEntryAdjustedCost(var AdjustedCostElementBuf: Record "Cost Element Buffer"; ItemApplnEntry: Record "Item Application Entry"; OutbndItemLedgEntryNo: Integer; InbndItemLedgEntryNo: Integer; ExactCostReversing: Boolean; Recursion: Boolean; var CompletelyInvoiced: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyILEToILE(var Item: Record Item; ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyItemToItem(var FromItem: Record Item; var ToItem: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsUpdateCompletelyInvoiced(ItemLedgEntry: Record "Item Ledger Entry"; CompletelyInvoiced: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMakeMultiLevelAdjmt(var Item: Record Item; IsOnlineAdjmt: Boolean; var PostToGL: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; OrigValueEntry: Record "Value Entry"; NewAdjustedCost: Decimal; NewAdjustedCostACY: Decimal; SkipUpdateJobItemCost: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenWindow(var IsHandled: Boolean; var WindowDialog: Dialog; var WindowIsOpen: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAdjmtBuf(OrigValueEntry: Record "Value Entry"; NewAdjustedCost: Decimal; NewAdjustedCostACY: Decimal; ItemLedgEntryPostingDate: Date; EntryType: Enum "Cost Entry Type"; var Result: Boolean; var IsHandled: Boolean; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateWindow(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateItemUnitCost(var TempAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point" temporary; var IsHandled: Boolean; var Item: Record Item; var TempItemLedgerEntry: Record "Item Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateConsumpAvgEntry(ValueEntry: Record "Value Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyAvgCostAdjmtToAvgCostAdjmtOnAfterInsert(var AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyCostElementBufToValueEntryBufOnBeforeValueEntryBufInsert(var ValueEntryBuf: Record "Value Entry"; CostElementBuffer: Record "Cost Element Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyValueEntryBufToCostElementBufOnBeforeCostElementBufferInsert(var CostElementBuffer: Record "Cost Element Buffer"; ValueEntryBuf: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExcludeAvgCostOnValuationDateOnAfterSetItemLedgEntryInChainFilters(var ItemLedgerEntryInChain: Record "Item Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnForwardAppliedCostOnAfterSetAppliedQty(ItemLedgerEntry: Record "Item Ledger Entry"; var AppliedQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetOrigValueEntryOnAfterOrigValueEntryFound(var OrigValueEntry: Record "Value Entry"; ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsOutputWithSelfConsumptionOnAfterSetTempItemLedgEntryFilter(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsOutputWithSelfConsumptionOnAfterSetConsumpValueEntryFilters(var ConsumpValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenOutbndItemLedgEntriesExistOnAfterSetOpenItemLedgEntryFilters(var OpenItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineCopyFromValueEntry(var ItemJournalLine: Record "Item Journal Line"; ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnAfterItemJnlPostLineRunWithCheck(var ItemJournalLine: Record "Item Journal Line"; ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnAfterSetPostingDate(var ItemJournalLine: Record "Item Journal Line"; ValueEntry: Record "Value Entry"; PostingDateForClosedPeriod: Date; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeMultiLevelAdjmtOnAfterMakeAdjmt(var TempAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point" temporary; var FilterItem: Record Item; var RndgResidualBuf: Record "Rounding Residual Buffer"; IsOnlineAdjmt: Boolean; PostToGL: Boolean; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeSingleLevelAdjmtOnAfterUpdateItemUnitCost(var TheItem: Record Item; var TempAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point" temporary; var LevelExceeded: Boolean; IsOnlineAdjmt: Boolean; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInvtToAdjustExistOnBeforeCopyItemToItem(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateJobItemCost(var Job: Record Job);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemUnitCostOnAfterItemGet(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemUnitCostOnAfterModifyItemNotStandardCostingMethod(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemUnitCostOnBeforeModifyItemNotStandardCostingMethod(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateConsumpAvgEntryOnAfterSetItemLedgEntryFilters(var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnBeforePostItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; OrigValueEntry: Record "Value Entry"; var InvtAdjmtBuf: Record "Inventory Adjustment Buffer"; var GLSetup: Record "General Ledger Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitAdjmtJnlLine(var ItemJnlLine: Record "Item Journal Line"; OrigValueEntry: Record "Value Entry"; EntryType: Enum "Cost Entry Type"; VarianceType: Enum "Cost Variance Type"; InvoicedQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWIPToAdjustExistOnAfterInventoryAdjmtEntryOrderSetFilters(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMakeSingleLevelAdjmt(var TheItem: Record Item; var TempAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAdjustItemAvgCostOnBeforeAdjustValueEntries()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAvgValueEntriesToAdjustExistOnBeforeIsNotAdjustment(var ValueEntry: Record "Value Entry"; var OutbndValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeSingleLevelAdjmtOnBeforeCollectAvgCostAdjmtEntryPointToUpdate(var TheItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitializeAdjmtOnAfterGetPostingDate(var PostingDateForClosedPeriod: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAdjustAppliedInbndEntriesOnAfterSetFilter(var InbndValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateIndirectCostAdjmtOnAfterPostItemJnlLine(ValueEntry: Record "Value Entry"; NewAdjustedCost: Decimal; NewAdjustedCostACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdjmtBufOnAfterPostExpectedCost(ValueEntry: Record "Value Entry"; TempInventoryAdjustmentBuffer: Record "Inventory Adjustment Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdjmtBufOnAfterPostNewCost(ValueEntry: Record "Value Entry"; TempInventoryAdjustmentBuffer: Record "Inventory Adjustment Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeSingleLevelAdjmtOnAfterLevelExceeded(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeSingleLevelAdjmtOnBeforePostAdjmtBuf(var Item: Record Item; var TempAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point" temporary; var TempInventoryAdjustmentBuffer: Record "Inventory Adjustment Buffer" temporary; var TempRoundingResidualBuffer: Record "Rounding Residual Buffer" temporary; PostingDateForClosedPeriod: Date; Currency: Record Currency; SkipUpdateJobItemCost: Boolean; var TempJobToAdjustBuf: Record Job temporary; ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnForwardAppliedCostOnBeforeUpdateWindow(var ItemLedgerEntry: Record "Item Ledger Entry"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAdjustAppliedOutbndEntriesOnBeforeCheckExpectedCost(var Item: Record Item; var OutbndValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcInbndEntryAdjustedCostOnBeforeAddCost(var Item: Record Item; var InbndValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAdjustItemAvgCostOnBeforeUpdateWindow(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAdjmtBufOnBeforeHasNewCost(OrigValueEntry: Record "Value Entry"; NewAdjustedCost: Decimal; NewAdjustedCostACY: Decimal; ItemLedgEntryPostingDate: Date; EntryType: Enum "Cost Entry Type"; var IsHandled: Boolean; var TempInvtAdjmtBuf: Record "Inventory Adjustment Buffer" temporary; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateWindowOnAfterOpenWindow(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvgCostOnAfterAssignRoundingError(var RoundingError: Decimal; var RoundingErrorACY: Decimal; var CostElementBuffer: Record "Cost Element Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAdjustOutbndAvgEntryOnNewCostElementBuf(var OutbndValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAdjmtBufOnAfterAddActualCostBuf(OrigValueEntry: Record "Value Entry"; NewAdjustedCost: Decimal; NewAdjustedCostACY: Decimal; ItemLedgEntryPostingDate: Date; TempInventoryAdjustmentBuffer: Record "Inventory Adjustment Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEliminateRndgResidualOnBeforeCheckHasNewCost(InbndItemLedgerEntry: Record "Item Ledger Entry"; ValueEntry: Record "Value Entry"; RndgCost: Decimal; RndgCostACY: Decimal; var IsHandled: Boolean)
    begin
    end;
    
    [IntegrationEvent(false, false)]
    local procedure OnBeforeAdjustItem(var TheItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAdjustItem(var TheItem: Record Item)
    begin
    end;    
}
