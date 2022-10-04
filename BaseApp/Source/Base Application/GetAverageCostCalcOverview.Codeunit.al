codeunit 5847 "Get Average Cost Calc Overview"
{
    TableNo = "Average Cost Calc. Overview";

    trigger OnRun()
    begin
        AvgCostAdjmtEntryPoint.SetRange("Item No.", "Item No.");
        AvgCostAdjmtEntryPoint.SetFilter("Location Code", GetFilter("Location Code"));
        AvgCostAdjmtEntryPoint.SetFilter("Variant Code", GetFilter("Variant Code"));
        AvgCostAdjmtEntryPoint.SetFilter("Valuation Date", GetFilter("Valuation Date"));
        OnRunOnSetAvgCostAdjmtEntryPointFilters(AvgCostAdjmtEntryPoint, Rec);

        Reset();
        DeleteAll();
        if AvgCostAdjmtEntryPoint.Find('-') then
            repeat
                Init();
                Type := Type::"Closing Entry";
                "Entry No." := "Entry No." + 1;
                CopyAvgCostAdjmtEntryPointFieldsToAverageCostCalcOverview(AvgCostAdjmtEntryPoint, Rec);
                "Attached to Valuation Date" := "Valuation Date";
                "Attached to Entry No." := "Entry No.";
                if EntriesExist(Rec) then begin
                    OnBeforeAvgCostAdjmtEntryPointInsert(Rec, AvgCostAdjmtEntryPoint);
                    Insert();
                end else
                    AvgCostAdjmtEntryPoint.Delete();
            until AvgCostAdjmtEntryPoint.Next() = 0;
    end;

    var
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
        ValueEntry: Record "Value Entry";
        Item: Record Item;
        CalendarPeriod: Record Date;
        AttachedToEntryNo: Integer;

    procedure Calculate(var AvgCostCalcOverview: Record "Average Cost Calc. Overview")
    var
        AvgCostCalcOverview2: Record "Average Cost Calc. Overview";
        FirstEntryNo: Integer;
    begin
        with ValueEntry do begin
            AvgCostCalcOverview2 := AvgCostCalcOverview;
            AvgCostCalcOverview.Find();
            AvgCostCalcOverview.TestField("Item No.");
            AvgCostCalcOverview.TestField(Type, AvgCostCalcOverview.Type::"Closing Entry");

            AttachedToEntryNo := AvgCostCalcOverview."Entry No.";

            Item.Get("Item No.");
            OnCalculateOnAfterGetItem(Item, AvgCostCalcOverview);
            if Item."Costing Method" = Item."Costing Method"::Average then begin
                CalendarPeriod."Period Start" := AvgCostCalcOverview."Valuation Date";
                AvgCostAdjmtEntryPoint."Valuation Date" := AvgCostCalcOverview."Valuation Date";
                AvgCostAdjmtEntryPoint.GetValuationPeriod(CalendarPeriod);
                AvgCostCalcOverview.SetRange("Valuation Date", CalendarPeriod."Period Start", CalendarPeriod."Period End");
            end else
                AvgCostCalcOverview.SetRange("Valuation Date", AvgCostCalcOverview2."Valuation Date");

            if not (Item."Costing Method" = Item."Costing Method"::Average) or
               not AvgCostAdjmtEntryPoint.IsAvgCostCalcTypeItem(AvgCostCalcOverview."Valuation Date")
            then begin
                AvgCostCalcOverview.SetRange("Variant Code", AvgCostCalcOverview."Variant Code");
                AvgCostCalcOverview.SetRange("Location Code", AvgCostCalcOverview."Location Code");
            end;
            AvgCostCalcOverview.SetRange(Level, 1, 2);
            AvgCostCalcOverview.DeleteAll();
            AvgCostCalcOverview.Reset();
            AvgCostCalcOverview.Find('+');

            FirstEntryNo := 0;
            if EntriesExist(AvgCostCalcOverview2) then
                repeat
                    InsertAvgCostCalcOvervwFromILE(AvgCostCalcOverview, ValueEntry, AvgCostCalcOverview2."Valuation Date");
                    if FirstEntryNo = 0 then
                        FirstEntryNo := AvgCostCalcOverview."Entry No.";
                until Next() = 0;

            if AvgCostCalcOverview.Get(FirstEntryNo) then;
        end;
    end;

    local procedure InsertAvgCostCalcOvervwFromILE(var AvgCostCalcOverview: Record "Average Cost Calc. Overview"; ValueEntry: Record "Value Entry"; ValuationDate: Date)
    var
        CopyOfAvgCostCalcOverview: Record "Average Cost Calc. Overview";
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemApplnEntry: Record "Item Application Entry";
        ModifyLine: Boolean;
    begin
        with AvgCostCalcOverview do begin
            CopyOfAvgCostCalcOverview.Copy(AvgCostCalcOverview);

            SetCurrentKey("Item Ledger Entry No.");
            SetRange("Item Ledger Entry No.", ValueEntry."Item Ledger Entry No.");
            SetRange("Attached to Entry No.", AttachedToEntryNo);
            SetRange("Attached to Valuation Date", ValuationDate);
            if ValueEntry."Partial Revaluation" then
                SetRange(Type, Type::Revaluation);
            ModifyLine := Find('-');
            if not ModifyLine then begin
                ItemLedgEntry.Get(ValueEntry."Item Ledger Entry No.");
                Init();
                CopyItemLedgerEntryFieldsToAverageCostCalcOverview(ItemLedgEntry, AvgCostCalcOverview);
                "Entry No." := CopyOfAvgCostCalcOverview."Entry No." + 1;
                case true of
                    ValueEntry."Partial Revaluation":
                        Type := Type::Revaluation;
                    ItemLedgEntry.Positive:
                        if ItemApplnEntry.IsAppliedFromIncrease(ItemLedgEntry."Entry No.") then
                            Type := Type::"Applied Increase"
                        else
                            Type := Type::Increase;
                    ItemLedgEntry."Applies-to Entry" <> 0:
                        Type := Type::"Applied Decrease";
                    else
                        Type := Type::Decrease;
                end;
                "Attached to Entry No." := AttachedToEntryNo;
                "Attached to Valuation Date" := ValuationDate;
                "Valuation Date" := ValueEntry."Valuation Date";
                Quantity := 0;
                Level := 1;
            end;

            Quantity := Quantity + ValueEntry."Item Ledger Entry Quantity";
            "Cost Amount (Actual)" := "Cost Amount (Actual)" + ValueEntry."Cost Amount (Actual)";
            "Cost Amount (Expected)" := "Cost Amount (Expected)" + ValueEntry."Cost Amount (Expected)";

            OnBeforeModifyAvgCostCalcOverview(AvgCostCalcOverview, ValueEntry, ModifyLine);
            if ModifyLine then
                Modify()
            else begin
                Insert();
                CopyOfAvgCostCalcOverview := AvgCostCalcOverview;
            end;
            Copy(CopyOfAvgCostCalcOverview);
        end;
    end;

    local procedure CopyItemLedgerEntryFieldsToAverageCostCalcOverview(var ItemLedgerEntry: Record "Item Ledger Entry"; var AverageCostCalcOverview: Record "Average Cost Calc. Overview")
    begin
        AverageCostCalcOverview."Item No." := ItemLedgerEntry."Item No.";
        AverageCostCalcOverview."Location Code" := ItemLedgerEntry."Location Code";
        AverageCostCalcOverview."Variant Code" := ItemLedgerEntry."Variant Code";
        AverageCostCalcOverview."Posting Date" := ItemLedgerEntry."Posting Date";
        AverageCostCalcOverview."Item Ledger Entry No." := ItemLedgerEntry."Entry No.";
        AverageCostCalcOverview."Entry Type" := ItemLedgerEntry."Entry Type";
        AverageCostCalcOverview."Document Type" := ItemLedgerEntry."Document Type".AsInteger();
        AverageCostCalcOverview."Document No." := ItemLedgerEntry."Document No.";
        AverageCostCalcOverview."Document Line No." := ItemLedgerEntry."Document Line No.";
        AverageCostCalcOverview.Description := ItemLedgerEntry.Description;

        OnAfterCopyItemLedgerEntryFieldsToAverageCostCalcOverview(ItemLedgerEntry, AverageCostCalcOverview);
    end;

    local procedure CopyAvgCostAdjmtEntryPointFieldsToAverageCostCalcOverview(var AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point"; var AverageCostCalcOverview: Record "Average Cost Calc. Overview")
    begin
        AverageCostCalcOverview."Item No." := AvgCostAdjmtEntryPoint."Item No.";
        AverageCostCalcOverview."Variant Code" := AvgCostAdjmtEntryPoint."Variant Code";
        AverageCostCalcOverview."Location Code" := AvgCostAdjmtEntryPoint."Location Code";
        AverageCostCalcOverview."Valuation Date" := AvgCostAdjmtEntryPoint."Valuation Date";
        AverageCostCalcOverview."Cost is Adjusted" := AvgCostAdjmtEntryPoint."Cost Is Adjusted";

        OnAfterCopyAvgCostAdjmtEntryPointFieldsToAverageCostCalcOverview(AvgCostAdjmtEntryPoint, AverageCostCalcOverview)
    end;

    procedure EntriesExist(var AvgCostCalcOverview: Record "Average Cost Calc. Overview"): Boolean
    begin
        with ValueEntry do begin
            Item.Get(AvgCostCalcOverview."Item No.");
            OnEntriesExistOnAfterGetItem(Item, AvgCostCalcOverview);

            Reset();
            SetCurrentKey("Item No.", "Valuation Date", "Location Code", "Variant Code");
            SetRange("Item No.", AvgCostCalcOverview."Item No.");

            if Item."Costing Method" = Item."Costing Method"::Average then begin
                CalendarPeriod."Period Start" := AvgCostCalcOverview."Valuation Date";
                AvgCostAdjmtEntryPoint."Valuation Date" := AvgCostCalcOverview."Valuation Date";
                AvgCostAdjmtEntryPoint.GetValuationPeriod(CalendarPeriod);
                SetRange("Valuation Date", CalendarPeriod."Period Start", CalendarPeriod."Period End");
            end else
                SetRange("Valuation Date", AvgCostCalcOverview."Valuation Date");

            if not AvgCostAdjmtEntryPoint.IsAvgCostCalcTypeItem(AvgCostCalcOverview."Valuation Date") or
               not (Item."Costing Method" = Item."Costing Method"::Average)
            then begin
                SetRange("Location Code", AvgCostCalcOverview."Location Code");
                SetRange("Variant Code", AvgCostCalcOverview."Variant Code");
            end;
            OnEntriesExistOnBeforeFind(ValueEntry, Item, AvgCostCalcOverview);
            exit(Find('-'));
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyAvgCostAdjmtEntryPointFieldsToAverageCostCalcOverview(var AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point"; var AverageCostCalcOverview: Record "Average Cost Calc. Overview")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemLedgerEntryFieldsToAverageCostCalcOverview(var ItemLedgerEntry: Record "Item Ledger Entry"; var AverageCostCalcOverview: Record "Average Cost Calc. Overview")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAvgCostAdjmtEntryPointInsert(var AverageCostCalcOverview: Record "Average Cost Calc. Overview"; AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyAvgCostCalcOverview(var AverageCostCalcOverview: Record "Average Cost Calc. Overview"; ValueEntry: Record "Value Entry"; ModifyLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateOnAfterGetItem(var Item: Record Item; var AvgCostCalcOverview: Record "Average Cost Calc. Overview")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEntriesExistOnAfterGetItem(var Item: Record Item; var AvgCostCalcOverview: Record "Average Cost Calc. Overview")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEntriesExistOnBeforeFind(var ValueEntry: Record "Value Entry"; var Item: Record Item; var AverageCostCalcOverview: Record "Average Cost Calc. Overview")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnSetAvgCostAdjmtEntryPointFilters(var AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point"; var AverageCostCalcOverview: Record "Average Cost Calc. Overview")
    begin
    end;
}

