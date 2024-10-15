codeunit 99000851 "Assembly Line-Planning"
{
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyTxt: Label 'Assembly';

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnSetDemandTypeFromUnplannedDemand', '', false, false)]
    local procedure ReqLineOnSetDemandTypeFromUnplannedDemand(var RequisitionLine: Record "Requisition Line"; UnplannedDemand: Record "Unplanned Demand")
    begin
        if UnplannedDemand."Demand Type" = UnplannedDemand."Demand Type"::Assembly then
            RequisitionLine."Demand Type" := Database::"Assembly Line";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Unplanned Demand", 'OnValidateDemandOrderNoOnGetSourceFields', '', false, false)]
    local procedure OnValidateDemandOrderNoOnGetSourceFields(var UnplannedDemand: Record "Unplanned Demand")
    var
        AsmHeader: Record "Assembly Header";
    begin
        case UnplannedDemand."Demand Type" of
            UnplannedDemand."Demand Type"::Assembly:
                begin
                    AsmHeader.Get(UnplannedDemand."Demand SubType", UnplannedDemand."Demand Order No.");
                    UnplannedDemand.Description := AsmHeader.Description;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Carry Out Action Msg. - Plan.", 'OnCheckDemandType', '', false, false)]
    local procedure CarryOutActionMsgPlanOnCheckDemandType(RequisitionLine: Record "Requisition Line")
    var
        AssemblyLine: Record "Assembly Line";
    begin
        if RequisitionLine."Demand Type" = Database::"Assembly Line" then begin
            AssemblyLine.Get(RequisitionLine."Demand Subtype", RequisitionLine."Demand Order No.", RequisitionLine."Demand Line No.");
            AssemblyLine.TestField(Type, AssemblyLine.Type::Item);
            if not ((RequisitionLine."Demand Date" = WorkDate()) and (AssemblyLine."Due Date" in [0D, WorkDate()])) then
                RequisitionLine.TestField("Demand Date", AssemblyLine."Due Date");
            RequisitionLine.TestField("No.", AssemblyLine."No.");
            RequisitionLine.TestField("Qty. per UOM (Demand)", AssemblyLine."Qty. per Unit of Measure");
            RequisitionLine.TestField("Variant Code", AssemblyLine."Variant Code");
            RequisitionLine.TestField("Location Code", AssemblyLine."Location Code");
            AssemblyLine.CalcFields("Reserved Qty. (Base)");
            RequisitionLine.TestField(
                RequisitionLine."Demand Quantity (Base)",
                -AssemblyLine.SignedXX(AssemblyLine."Remaining Quantity (Base)" - AssemblyLine."Reserved Qty. (Base)"))
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Order Planning Mgt.", 'OnInsertDemandLinesOnCopyItemTracking', '', false, false)]
    local procedure OnInsertDemandLinesOnCopyItemTracking(var RequisitionLine: Record "Requisition Line"; UnplannedDemand: Record "Unplanned Demand")
    var
        AssemblyLine: Record "Assembly Line";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
    begin
        if UnplannedDemand."Demand Type" = UnplannedDemand."Demand Type"::Assembly then begin
            AssemblyLine.Get(UnplannedDemand."Demand SubType", UnplannedDemand."Demand Order No.", UnplannedDemand."Demand Line No.");
            ItemTrackingManagement.CopyItemTracking(AssemblyLine.RowID1(), RequisitionLine.RowID1(), true);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnBeforeShowDemandOrder', '', false, false)]
    local procedure OrderPlanningOnBeforeShowDemandOrder(RequisitionLine: Record "Requisition Line")
    begin
        if RequisitionLine."Demand Type" = Database::"Assembly Line" then begin
            AssemblyHeader.Get(RequisitionLine."Demand Subtype", RequisitionLine."Demand Order No.");
            case AssemblyHeader."Document Type" of
                AssemblyHeader."Document Type"::Order:
                    PAGE.Run(PAGE::"Assembly Order", AssemblyHeader);
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnSetRecDemandFilter', '', false, false)]
    local procedure OnSetRecDemandFilter(var RequisitionLine: Record "Requisition Line"; DemandOrderFilter: Enum "Demand Order Source Type")
    begin
        if DemandOrderFilter = DemandOrderFilter::"Assembly Demand" then begin
            RequisitionLine.SetRange("Demand Type", Database::"Assembly Line");
            RequisitionLine.SetCurrentKey("User ID", "Demand Type", "Worksheet Template Name", "Journal Batch Name", "Line No.");
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnAfterStatusTextOnFormat', '', false, false)]
    local procedure OnAfterStatusTextOnFormat(var RequisitionLine: Record "Requisition Line"; var Text: Text)
    begin
        if RequisitionLine."Demand Line No." = 0 then
            if RequisitionLine."Demand Type" = Database::"Assembly Line" then begin
                AssemblyHeader.Status := RequisitionLine.Status;
                Text := Format(AssemblyHeader.Status);
            end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnAfterDemandTypeTextOnFormat', '', false, false)]
    local procedure OnAfterDemandTypeTextOnFormat(var RequisitionLine: Record "Requisition Line"; var Text: Text)
    begin
        if RequisitionLine."Demand Line No." = 0 then
            if RequisitionLine."Demand Type" = Database::"Assembly Line" then
                Text := AssemblyTxt;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnAfterDemandSubtypeTextOnFormat', '', false, false)]
    local procedure OnAfterDemandSubtypeTextOnFormat(var RequisitionLine: Record "Requisition Line"; var Text: Text)
    begin
        if RequisitionLine."Demand Type" = Database::"Assembly Line" then
            Text := Format(Enum::"Assembly Document Type".FromInteger(RequisitionLine."Demand Subtype"));
    end;
}