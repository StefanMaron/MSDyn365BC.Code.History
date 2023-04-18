codeunit 5803 "Show Avg. Calc. - Item"
{
    TableNo = Item;

    trigger OnRun()
    var
        ValueEntry: Record "Value Entry";
    begin
        with ValueEntry do begin
            SetCurrentKey("Item No.", "Valuation Date", "Location Code", "Variant Code");
            SetRange("Item No.", Rec."No.");
            SetFilter("Valuation Date", Rec.GetFilter("Date Filter"));
            SetFilter("Location Code", Rec.GetFilter("Location Filter"));
            SetFilter("Variant Code", Rec.GetFilter("Variant Filter"));
            OnRunOnAfterValueEntrySetFilters(ValueEntry, Rec);
        end;
        PAGE.RunModal(PAGE::"Value Entries", ValueEntry, ValueEntry."Cost Amount (Actual)");
    end;

    procedure DrillDownAvgCostAdjmtPoint(var Item: Record Item)
    var
        AvgCostCalcOverview: Page "Average Cost Calc. Overview";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDrillDownAvgCostAdjmtPoint(Item, IsHandled);
        if IsHandled then
            exit;

        AvgCostCalcOverview.SetItem(Item);
        AvgCostCalcOverview.RunModal();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDrillDownAvgCostAdjmtPoint(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterValueEntrySetFilters(var ValueEntry: Record "Value Entry"; var Item: Record Item)
    begin
    end;
}

