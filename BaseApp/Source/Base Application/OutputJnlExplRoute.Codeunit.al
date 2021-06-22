codeunit 5406 "Output Jnl.-Expl. Route"
{
    Permissions = TableData "Item Journal Line" = imd,
                  TableData "Prod. Order Line" = r,
                  TableData "Prod. Order Routing Line" = r;
    TableNo = "Item Journal Line";

    trigger OnRun()
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ItemJnlLine: Record "Item Journal Line";
        CostCalcMgt: Codeunit "Cost Calculation Management";
        ItemJnlLineReserve: Codeunit "Item Jnl. Line-Reserve";
        NextLineNo: Integer;
        LineSpacing: Integer;
        BaseQtyToPost: Decimal;
        SkipRecord: Boolean;
        IsLastOperation: Boolean;
    begin
        if ("Order Type" <> "Order Type"::Production) or ("Order No." = '') then
            exit;

        if not ItemJnlLineReserve.DeleteLineConfirm(Rec) then
            exit;

        ProdOrderLine.Reset();
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", "Order No.");
        if "Order Line No." <> 0 then
            ProdOrderLine.SetRange("Line No.", "Order Line No.");
        if "Item No." <> '' then
            ProdOrderLine.SetRange("Item No.", "Item No.");
        if "Routing Reference No." <> 0 then
            ProdOrderLine.SetRange("Routing Reference No.", "Routing Reference No.");
        if "Routing No." <> '' then
            ProdOrderLine.SetRange("Routing No.", "Routing No.");

        ProdOrderRtngLine.SetRange(Status, ProdOrderRtngLine.Status::Released);
        ProdOrderRtngLine.SetRange("Prod. Order No.", "Order No.");
        if "Operation No." <> '' then
            ProdOrderRtngLine.SetRange("Operation No.", "Operation No.");
        ProdOrderRtngLine.SetFilter("Routing Status", '<> %1', ProdOrderRtngLine."Routing Status"::Finished);
        ProdOrderRtngLine.SetRange("Flushing Method", ProdOrderRtngLine."Flushing Method"::Manual);

        // Clear fields in xRec to ensure that validation code regarding dimensions is executed:
        "Order Line No." := 0;
        "Item No." := '';
        "Routing Reference No." := 0;
        "Routing No." := '';

        ItemJnlLine := Rec;

        ItemJnlLine.SetRange(
          "Journal Template Name", "Journal Template Name");
        ItemJnlLine.SetRange(
          "Journal Batch Name", "Journal Batch Name");

        if ItemJnlLine.Find('>') then begin
            LineSpacing :=
              (ItemJnlLine."Line No." - "Line No.") div
              (1 + ProdOrderLine.Count * ProdOrderRtngLine.Count);
            if LineSpacing = 0 then
                Error(Text000);
        end else
            LineSpacing := 10000;

        NextLineNo := "Line No.";

        if not ProdOrderLine.Find('-') then
            Error(Text001);

        repeat
            ProdOrderRtngLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
            ProdOrderRtngLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
            if ProdOrderRtngLine.Find('-') then begin
                repeat
                    BaseQtyToPost :=
                      CostCalcMgt.CalcQtyAdjdForRoutingScrap(
                        ProdOrderLine."Quantity (Base)",
                        ProdOrderRtngLine."Scrap Factor % (Accumulated)",
                        ProdOrderRtngLine."Fixed Scrap Qty. (Accum.)") -
                      CostCalcMgt.CalcActOutputQtyBase(ProdOrderLine, ProdOrderRtngLine);
                    OnAfterCalcBaseQtyToPost(ProdOrderRtngLine, BaseQtyToPost);
                    if BaseQtyToPost > 0 then begin
                        SkipRecord := false;
                        IsLastOperation := ProdOrderRtngLine."Next Operation No." = '';
                        OnBeforeInsertOutputJnlLineWithRtngLine(Rec, ProdOrderLine, SkipRecord, IsLastOperation, ProdOrderRtngLine);
                        if not SkipRecord then begin
                            InsertOutputJnlLine(
                              Rec, NextLineNo, LineSpacing,
                              ProdOrderLine."Line No.",
                              ProdOrderLine."Item No.",
                              ProdOrderLine."Variant Code",
                              ProdOrderLine."Location Code",
                              ProdOrderLine."Bin Code",
                              ProdOrderLine."Routing No.", ProdOrderLine."Routing Reference No.",
                              ProdOrderRtngLine."Operation No.",
                              ProdOrderLine."Unit of Measure Code",
                              BaseQtyToPost / ProdOrderLine."Qty. per Unit of Measure",
                              IsLastOperation);
                            if IsLastOperation then
                                ItemTrackingMgt.CopyItemTracking(ProdOrderLine.RowID1, LastItemJnlLine.RowID1, false);
                        end;
                    end;
                until ProdOrderRtngLine.Next = 0;
            end else
                if ProdOrderLine."Remaining Quantity" > 0 then begin
                    OnBeforeInsertOutputJnlLineWithoutRtngLine(Rec, ProdOrderLine);
                    InsertOutputJnlLine(
                      Rec, NextLineNo, LineSpacing,
                      ProdOrderLine."Line No.",
                      ProdOrderLine."Item No.",
                      ProdOrderLine."Variant Code",
                      ProdOrderLine."Location Code",
                      ProdOrderLine."Bin Code",
                      ProdOrderLine."Routing No.", ProdOrderLine."Routing Reference No.", '',
                      ProdOrderLine."Unit of Measure Code",
                      ProdOrderLine."Remaining Quantity",
                      true);
                    ItemTrackingMgt.CopyItemTracking(ProdOrderLine.RowID1, LastItemJnlLine.RowID1, false);
                end;
        until ProdOrderLine.Next = 0;

        ItemJnlLineReserve.DeleteLine(Rec);

        OnBeforeDeleteItemJnlLine(Rec);
        Delete;
    end;

    var
        Text000: Label 'There are not enough free line numbers to explode the route.';
        Text001: Label 'There is nothing to explode.';
        LastItemJnlLine: Record "Item Journal Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";

    local procedure InsertOutputJnlLine(ItemJnlLine: Record "Item Journal Line"; var NextLineNo: Integer; LineSpacing: Integer; ProdOrderLineNo: Integer; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]; RoutingNo: Code[20]; RoutingRefNo: Integer; OperationNo: Code[10]; UnitOfMeasureCode: Code[10]; QtyToPost: Decimal; LastOperation: Boolean)
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        NextLineNo := NextLineNo + LineSpacing;

        ItemJnlLine."Line No." := NextLineNo;
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Output);
        ItemJnlLine.Validate("Order Line No.", ProdOrderLineNo);
        ItemJnlLine.Validate("Item No.", ItemNo);
        ItemJnlLine.Validate("Variant Code", VariantCode);
        ItemJnlLine.Validate("Location Code", LocationCode);
        if BinCode <> '' then
            ItemJnlLine.Validate("Bin Code", BinCode);
        ItemJnlLine.Validate("Routing No.", RoutingNo);
        ItemJnlLine.Validate("Routing Reference No.", RoutingRefNo);
        ItemJnlLine.Validate("Operation No.", OperationNo);
        ItemJnlLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        ItemJnlLine.Validate("Setup Time", 0);
        ItemJnlLine.Validate("Run Time", 0);
        if (LocationCode <> '') and LastOperation then
            ItemJnlLine.CheckWhse(LocationCode, QtyToPost);
        if ItemJnlLine.SubcontractingWorkCenterUsed then
            ItemJnlLine.Validate("Output Quantity", 0)
        else
            ItemJnlLine.Validate("Output Quantity", QtyToPost);

        OnBeforeOutputItemJnlLineInsert(ItemJnlLine, LastOperation);
        DimMgt.UpdateGlobalDimFromDimSetID(
          ItemJnlLine."Dimension Set ID", ItemJnlLine."Shortcut Dimension 1 Code", ItemJnlLine."Shortcut Dimension 2 Code");
        ItemJnlLine.Insert();

        OnAfterInsertItemJnlLine(ItemJnlLine);

        LastItemJnlLine := ItemJnlLine;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcBaseQtyToPost(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var BaseQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertItemJnlLine(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteItemJnlLine(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertOutputJnlLineWithRtngLine(ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line"; var SkipRecord: Boolean; var IsLastOperation: Boolean; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertOutputJnlLineWithoutRtngLine(ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOutputItemJnlLineInsert(var ItemJournalLine: Record "Item Journal Line"; LastOperation: Boolean)
    begin
    end;
}

