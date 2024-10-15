codeunit 99000857 "Prod. Order Line-Planning"
{
    var
        ProductionOrder: Record "Production Order";
        ProductionTxt: Label 'Production';

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnSetDemandTypeFromUnplannedDemand', '', false, false)]
    local procedure ReqLineOnSetDemandTypeFromUnplannedDemand(var RequisitionLine: Record "Requisition Line"; UnplannedDemand: Record "Unplanned Demand")
    begin
        if UnplannedDemand."Demand Type" = UnplannedDemand."Demand Type"::Production then
            RequisitionLine."Demand Type" := Database::"Prod. Order Component";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Unplanned Demand", 'OnValidateDemandOrderNoOnGetSourceFields', '', false, false)]
    local procedure OnValidateDemandOrderNoOnGetSourceFields(var UnplannedDemand: Record "Unplanned Demand")
    var
        ProdOrder: Record "Production Order";
    begin
        case UnplannedDemand."Demand Type" of
            UnplannedDemand."Demand Type"::Production:
                begin
                    ProdOrder.Get(UnplannedDemand."Demand SubType", UnplannedDemand."Demand Order No.");
                    UnplannedDemand.Description := ProdOrder.Description;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Carry Out Action Msg. - Plan.", 'OnCheckDemandType', '', false, false)]
    local procedure CarryOutActionMsgPlanOnCheckDemandType(RequisitionLine: Record "Requisition Line")
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        if RequisitionLine."Demand Type" = Database::"Prod. Order Component" then begin
            ProdOrderComp.Get(RequisitionLine."Demand Subtype", RequisitionLine."Demand Order No.", RequisitionLine."Demand Line No.", RequisitionLine."Demand Ref. No.");
            RequisitionLine.TestField("No.", ProdOrderComp."Item No.");
            if not ((RequisitionLine."Demand Date" = WorkDate()) and (ProdOrderComp."Due Date" in [0D, WorkDate()])) then
                RequisitionLine.TestField("Demand Date", ProdOrderComp."Due Date");
            RequisitionLine.TestField("Qty. per UOM (Demand)", ProdOrderComp."Qty. per Unit of Measure");
            RequisitionLine.TestField("Variant Code", ProdOrderComp."Variant Code");
            RequisitionLine.TestField("Location Code", ProdOrderComp."Location Code");
            ProdOrderComp.CalcFields("Reserved Qty. (Base)");
            RequisitionLine.TestField(
                RequisitionLine."Demand Quantity (Base)",
                ProdOrderComp."Remaining Qty. (Base)" - ProdOrderComp."Reserved Qty. (Base)");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Order Planning Mgt.", 'OnInsertDemandLinesOnCopyItemTracking', '', false, false)]
    local procedure OnInsertDemandLinesOnCopyItemTracking(var RequisitionLine: Record "Requisition Line"; UnplannedDemand: Record "Unplanned Demand")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
    begin
        if UnplannedDemand."Demand Type" = UnplannedDemand."Demand Type"::Production then begin
            ProdOrderComponent.Get(UnplannedDemand."Demand SubType", UnplannedDemand."Demand Order No.", UnplannedDemand."Demand Line No.", UnplannedDemand."Demand Ref. No.");
            ItemTrackingManagement.CopyItemTracking(ProdOrderComponent.RowID1(), RequisitionLine.RowID1(), true);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnBeforeShowDemandOrder', '', false, false)]
    local procedure OrderPlanningOnBeforeShowDemandOrder(RequisitionLine: Record "Requisition Line")
    begin
        if RequisitionLine."Demand Type" = Database::"Prod. Order Component" then begin
            ProductionOrder.Get(RequisitionLine."Demand Subtype", RequisitionLine."Demand Order No.");
            case ProductionOrder.Status of
                ProductionOrder.Status::Planned:
                    PAGE.Run(PAGE::"Planned Production Order", ProductionOrder);
                ProductionOrder.Status::"Firm Planned":
                    PAGE.Run(PAGE::"Firm Planned Prod. Order", ProductionOrder);
                ProductionOrder.Status::Released:
                    PAGE.Run(PAGE::"Released Production Order", ProductionOrder);
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnSetRecDemandFilter', '', false, false)]
    local procedure OnSetRecDemandFilter(var RequisitionLine: Record "Requisition Line"; DemandOrderFilter: Enum "Demand Order Source Type")
    begin
        if DemandOrderFilter = DemandOrderFilter::"Production Demand" then begin
            RequisitionLine.SetRange("Demand Type", Database::"Prod. Order Component");
            RequisitionLine.SetCurrentKey("User ID", "Demand Type", "Worksheet Template Name", "Journal Batch Name", "Line No.");
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnAfterStatusTextOnFormat', '', false, false)]
    local procedure OnAfterStatusTextOnFormat(var RequisitionLine: Record "Requisition Line"; var Text: Text)
    begin
        if RequisitionLine."Demand Line No." = 0 then
            if RequisitionLine."Demand Type" = Database::"Prod. Order Component" then
                Text := Format(Enum::"Production Order Status".FromInteger(RequisitionLine.Status));
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnAfterDemandTypeTextOnFormat', '', false, false)]
    local procedure OnAfterDemandTypeTextOnFormat(var RequisitionLine: Record "Requisition Line"; var Text: Text)
    begin
        if RequisitionLine."Demand Line No." = 0 then
            if RequisitionLine."Demand Type" = Database::"Prod. Order Component" then
                Text := ProductionTxt;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnAfterDemandSubtypeTextOnFormat', '', false, false)]
    local procedure OnAfterDemandSubtypeTextOnFormat(var RequisitionLine: Record "Requisition Line"; var Text: Text)
    begin
        if RequisitionLine."Demand Type" = Database::"Prod. Order Component" then
            Text := Format(Enum::"Production Order Status".FromInteger(RequisitionLine.Status));
    end;
}