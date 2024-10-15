namespace Microsoft.Inventory.Requisition;

using Microsoft.Assembly.Document;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Projects.Project.Planning;
using Microsoft.Sales.Document;
using Microsoft.Service.Document;

codeunit 5522 "Order Planning Mgt."
{
    trigger OnRun()
    begin
    end;

    var
        TempUnplannedDemand: Record "Unplanned Demand";
        ProdOrderComp: Record "Prod. Order Component";
        CompanyInfo: Record "Company Information";
        UOMMgt: Codeunit "Unit of Measure Management";
        DemandType: Enum "Unplanned Demand Type";
        HasGotCompanyInfo: Boolean;
        Text000: Label 'Generating Lines to Plan @1@@@@@@@';
        Text001: Label 'Item Substitution is not possible for the active line.';
        Text003: Label 'You cannot use this function because the active line has no %1.';
        Text004: Label 'All items are available and no planning lines are created.';
        DelReqLine: Boolean;

    procedure GetOrdersToPlan(var ReqLine: Record "Requisition Line")
    begin
        PrepareRequisitionRecord(ReqLine);
        RunGetUnplannedDemand();
        TransformUnplannedDemandToRequisitionLines(ReqLine);
    end;

    local procedure RunGetUnplannedDemand()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunGetUnplannedDemand(TempUnplannedDemand, IsHandled);
        if IsHandled then
            exit;

        Codeunit.Run(Codeunit::"Get Unplanned Demand", TempUnplannedDemand);
    end;

    procedure PlanSpecificSalesOrder(var ReqLine: Record "Requisition Line"; SalesOrderNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        GetUnplannedDemand: Codeunit "Get Unplanned Demand";
    begin
        SetSalesOrder();
        PrepareRequisitionRecord(ReqLine);

        GetUnplannedDemand.SetIncludeMetDemandForSpecificSalesOrderNo(SalesOrderNo);
        GetUnplannedDemand.Run(TempUnplannedDemand);

        TransformUnplannedDemandToRequisitionLines(ReqLine);

        ReqLine.SetRange("Demand Order No.", SalesOrderNo);
        ReqLine.SetRange("Demand Subtype", SalesHeader."Document Type"::Order);
    end;

    procedure PrepareRequisitionRecord(var RequisitionLine: Record "Requisition Line")
    begin
        RequisitionLine.SetCurrentKey("User ID", "Worksheet Template Name");
        RequisitionLine.SetRange("User ID", UserId);
        RequisitionLine.SetRange("Worksheet Template Name", '');
        OnPrepareRequisitionRecordOnBeforeDeleteAll(RequisitionLine);
        if not RequisitionLine.IsEmpty() then
            RequisitionLine.DeleteAll(true);

        RequisitionLine.Reset();
        RequisitionLine.SetRange("Worksheet Template Name", '');
        RequisitionLine.SetRange("Journal Batch Name", RequisitionLine.GetJnlBatchNameForOrderPlanning());
        if RequisitionLine.FindLast() then;
    end;

    local procedure TransformUnplannedDemandToRequisitionLines(var RequisitionLine: Record "Requisition Line")
    var
        Window: Dialog;
        WindowUpdateDateTime: DateTime;
        i: Integer;
        NoOfRecords: Integer;
    begin
        TempUnplannedDemand.SetCurrentKey("Demand Date", Level);
        TempUnplannedDemand.SetRange(Level, 0);

        i := 0;
        Window.Open(Text000);
        WindowUpdateDateTime := CurrentDateTime;
        NoOfRecords := TempUnplannedDemand.Count;

        if TempUnplannedDemand.Find('-') then
            repeat
                i := i + 1;
                if CurrentDateTime - WindowUpdateDateTime >= 300 then begin
                    WindowUpdateDateTime := CurrentDateTime;
                    Window.Update(1, Round(i / NoOfRecords * 10000, 1));
                end;

                InsertDemandLines(RequisitionLine);
                TempUnplannedDemand.Delete();
            until TempUnplannedDemand.Next() = 0;

        Window.Close();

        RequisitionLine.Reset();
        RequisitionLine.SetCurrentKey("User ID", "Worksheet Template Name");
        RequisitionLine.SetRange("User ID", UserId);
        if not RequisitionLine.FindFirst() then
            Error(Text004);

        OnAfterTransformUnplannedDemandToRequisitionLines(RequisitionLine);
        Commit();
    end;

    local procedure InsertDemandLines(var ReqLine: Record "Requisition Line")
    var
        UnplannedDemand: Record "Unplanned Demand";
        Item: Record Item;
        HeaderExists: Boolean;
    begin
        UnplannedDemand.Copy(TempUnplannedDemand);

        TempUnplannedDemand.Reset();
        TempUnplannedDemand.SetRecFilter();
        TempUnplannedDemand.SetRange("Demand Line No.");
        TempUnplannedDemand.SetRange("Demand Ref. No.");
        TempUnplannedDemand.SetRange(Level, 1);
        OnInsertDemandLinesOnBeforeFindUnplannedDemand(TempUnplannedDemand, ReqLine);
        TempUnplannedDemand.Find('-');
        HeaderExists := false;

        repeat
            if DemandType in [TempUnplannedDemand."Demand Type", DemandType::" "] then begin
                if not HeaderExists then
                    InsertDemandHeader(UnplannedDemand, ReqLine);
                HeaderExists := true;

                ReqLine.TransferFromUnplannedDemand(TempUnplannedDemand);
                ReqLine.SetSupplyQty(TempUnplannedDemand."Quantity (Base)", TempUnplannedDemand."Needed Qty. (Base)");
                ReqLine.SetSupplyDates(TempUnplannedDemand."Demand Date");
                InsertReqLineFromUnplannedDemand(ReqLine, Item);
            end;
            TempUnplannedDemand.Delete();
        until TempUnplannedDemand.Next() = 0;

        TempUnplannedDemand.Copy(UnplannedDemand);
    end;

    local procedure InsertReqLineFromUnplannedDemand(var ReqLine: Record "Requisition Line"; var Item: Record Item)
    var
        SalesLine: Record "Sales Line";
        ServLine: Record "Service Line";
        AsmLine: Record "Assembly Line";
        ProdOrderComp2: Record "Prod. Order Component";
        PlanningLineMgt: Codeunit "Planning Line Management";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnInsertDemandLinesOnBeforeReqLineInsert(ReqLine, TempUnplannedDemand, IsHandled);
        if IsHandled then
            exit;

        ReqLine.Insert();
        OnInsertDemandLinesOnAfterReqLineInsert(ReqLine, TempUnplannedDemand);
        if Item."No." <> TempUnplannedDemand."Item No." then
            Item.Get(TempUnplannedDemand."Item No.");
        if Item."Item Tracking Code" <> '' then
            case TempUnplannedDemand."Demand Type" of
                TempUnplannedDemand."Demand Type"::Sales:
                    begin
                        SalesLine.Get(TempUnplannedDemand."Demand SubType", TempUnplannedDemand."Demand Order No.", TempUnplannedDemand."Demand Line No.");
                        ItemTrackingMgt.CopyItemTracking(SalesLine.RowID1(), ReqLine.RowID1(), true);
                    end;
                TempUnplannedDemand."Demand Type"::Production:
                    begin
                        ProdOrderComp2.Get(TempUnplannedDemand."Demand SubType", TempUnplannedDemand."Demand Order No.", TempUnplannedDemand."Demand Line No.", TempUnplannedDemand."Demand Ref. No.");
                        ItemTrackingMgt.CopyItemTracking(ProdOrderComp2.RowID1(), ReqLine.RowID1(), true);
                    end;
                TempUnplannedDemand."Demand Type"::Service:
                    begin
                        ServLine.Get(TempUnplannedDemand."Demand SubType", TempUnplannedDemand."Demand Order No.", TempUnplannedDemand."Demand Line No.");
                        ItemTrackingMgt.CopyItemTracking(ServLine.RowID1(), ReqLine.RowID1(), true);
                    end;
                TempUnplannedDemand."Demand Type"::Assembly:
                    begin
                        AsmLine.Get(TempUnplannedDemand."Demand SubType", TempUnplannedDemand."Demand Order No.", TempUnplannedDemand."Demand Line No.");
                        ItemTrackingMgt.CopyItemTracking(AsmLine.RowID1(), ReqLine.RowID1(), true);
                    end;
            end;
        if ReqLine.Quantity > 0 then
            PlanningLineMgt.Calculate(ReqLine, 1, true, true, 0);
        ReqLine.Find('+');
    end;

    local procedure InsertDemandHeader(UnplannedDemand: Record "Unplanned Demand"; var ReqLine: Record "Requisition Line")
    begin
        ReqLine.Init();
        ReqLine."Journal Batch Name" := ReqLine.GetJnlBatchNameForOrderPlanning();
        case UnplannedDemand."Demand Type" of
            UnplannedDemand."Demand Type"::Sales:
                ReqLine."Demand Type" := Database::"Sales Line";
            UnplannedDemand."Demand Type"::Production:
                ReqLine."Demand Type" := Database::"Prod. Order Component";
            UnplannedDemand."Demand Type"::Service:
                ReqLine."Demand Type" := Database::"Service Line";
            UnplannedDemand."Demand Type"::Job:
                ReqLine."Demand Type" := Database::"Job Planning Line";
            UnplannedDemand."Demand Type"::Assembly:
                ReqLine."Demand Type" := Database::"Assembly Line";
        end;
        ReqLine."Demand Subtype" := UnplannedDemand."Demand SubType";
        ReqLine."Demand Order No." := UnplannedDemand."Demand Order No.";
        ReqLine.Status := UnplannedDemand.Status;
        ReqLine."Demand Date" := UnplannedDemand."Demand Date";
        ReqLine.Description := UnplannedDemand.Description;

        ReqLine.Level := 0;
        ReqLine."Replenishment System" := ReqLine."Replenishment System"::" ";
        IncreaseReqLineNo(UnplannedDemand, ReqLine);
        ReqLine."User ID" := CopyStr(UserId(), 1, MaxStrLen(ReqLine."User ID"));
        OnInsertDemandHeaderOnBeforeReqLineInsert(UnplannedDemand, ReqLine);
        ReqLine.Insert();
        OnInsertDemandHeaderOnAfterReqLineInsert(UnplannedDemand, ReqLine);
    end;

    local procedure IncreaseReqLineNo(var UnplannedDemand: Record "Unplanned Demand"; var ReqLine: Record "Requisition Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIncreaseReqLineNo(UnplannedDemand, ReqLine, IsHandled);
        if IsHandled then
            exit;

        ReqLine."Line No." := ReqLine."Line No." + 10000;
    end;

    procedure DeleteLine(): Boolean
    begin
        exit(DelReqLine);
    end;

    procedure CalcNeededQty(AvailableQty: Decimal; DemandQty: Decimal): Decimal
    begin
        case true of
            AvailableQty >= DemandQty:
                exit(0);
            AvailableQty < 0:
                exit(DemandQty);
            else
                exit(DemandQty - AvailableQty);
        end;
    end;

    procedure CalcATPQty(ItemNo: Text[250]; VariantFilter: Text[250]; LocationFilter: Text[250]; DemandDate: Date): Decimal
    var
        Item: Record Item;
        AvailableToPromise: Codeunit "Available to Promise";
        GrossRequirement: Decimal;
        ScheduledRcpt: Decimal;
        ODF: DateFormula;
    begin
        if ItemNo = '' then
            exit(0);

        Item.Get(ItemNo);
        Item.SetRange("Variant Filter", VariantFilter);
        Item.SetRange("Location Filter", LocationFilter);
        Item.SetRange("Date Filter", 0D, DemandDate);
        Item.SetRange("Drop Shipment Filter", false);
        if DemandDate = 0D then
            DemandDate := WorkDate();
        Evaluate(ODF, '<0D>');

        OnCalcATPQtyOnBeforeCalcQtyAvailabletoPromise(Item);
        exit(
            AvailableToPromise.CalcQtyAvailableToPromise(Item, GrossRequirement, ScheduledRcpt, DemandDate, Enum::"Analysis Period Type"::Day, ODF))
    end;

    procedure CalcATPEarliestDate(ItemNo: Text[250]; VariantFilter: Text[250]; LocationFilter: Text[250]; DemandDate: Date; Quantity: Decimal): Date
    var
        Item: Record Item;
        AvailableToPromise: Codeunit "Available to Promise";
        AvailableQty: Decimal;
    begin
        if ItemNo = '' then
            exit(0D);

        GetCompanyInfo();
        if DemandDate = 0D then
            DemandDate := WorkDate();

        Item.Get(ItemNo);
        Item.SetRange("Variant Filter", VariantFilter);
        Item.SetRange("Location Filter", LocationFilter);
        Item.SetRange("Drop Shipment Filter", false);
        exit(
          AvailableToPromise.CalcEarliestAvailabilityDate(
            Item, Quantity, DemandDate, Quantity, DemandDate, AvailableQty,
            CompanyInfo."Check-Avail. Time Bucket", CompanyInfo."Check-Avail. Period Calc."));
    end;

    local procedure GetCompanyInfo()
    begin
        if HasGotCompanyInfo then
            exit;
        HasGotCompanyInfo := CompanyInfo.Get();
    end;

    procedure SetSalesOrder()
    begin
        DemandType := DemandType::Sales;
    end;

    procedure SetProdOrder()
    begin
        DemandType := DemandType::Production;
    end;

    procedure SetServOrder()
    begin
        DemandType := DemandType::Service;
    end;

    procedure SetJobOrder()
    begin
        DemandType := DemandType::Job;
    end;

    procedure SetAsmOrder()
    begin
        DemandType := DemandType::Assembly;
    end;

    procedure InsertAltSupplySubstitution(var ReqLine: Record "Requisition Line")
    var
        TempItemSub: Record "Item Substitution" temporary;
        TempReqLine2: Record "Requisition Line" temporary;
        ItemSubstMgt: Codeunit "Item Subst.";
        PlanningLineMgt: Codeunit "Planning Line Management";
        UnAvailableQtyBase: Decimal;
    begin
        if not SubstitutionPossible(ReqLine) then
            Error(Text001);

        Clear(ItemSubstMgt);
        if not ItemSubstMgt.PrepareSubstList(
             ReqLine."No.",
             ReqLine."Variant Code",
             ReqLine."Location Code",
             ReqLine."Due Date",
             true)
        then
            ItemSubstMgt.ErrorMessage(ReqLine."No.", ReqLine."Variant Code");

        ItemSubstMgt.GetTempItemSubstList(TempItemSub);

        TempItemSub.Reset();
        TempItemSub.SetRange("Variant Code", ReqLine."Variant Code");
        TempItemSub.SetRange("Location Filter", ReqLine."Location Code");
        if TempItemSub.FindFirst() then;
        if PAGE.RunModal(PAGE::"Item Substitution Entries", TempItemSub) = ACTION::LookupOK then begin
            // Update sourceline
            ProdOrderComp.Get(ReqLine."Demand Subtype", ReqLine."Demand Order No.", ReqLine."Demand Line No.", ReqLine."Demand Ref. No.");
            ItemSubstMgt.UpdateComponent(
              ProdOrderComp, TempItemSub."Substitute No.", TempItemSub."Substitute Variant Code");
            ProdOrderComp.Modify(true);
            ProdOrderComp.AutoReserve();

            if TempItemSub."Quantity Avail. on Shpt. Date" >= ReqLine."Needed Quantity (Base)" then begin
                ReqLine.Delete(true);
                DelReqLine := true;
            end else begin
                TempReqLine2 := ReqLine; // Save Original Line

                UnAvailableQtyBase :=
                  CalcNeededQty(
                    TempItemSub."Quantity Avail. on Shpt. Date", TempReqLine2."Demand Quantity (Base)");

                // Update Req.Line
                ReqLine."Worksheet Template Name" := TempReqLine2."Worksheet Template Name";
                ReqLine."Journal Batch Name" := TempReqLine2."Journal Batch Name";
                ReqLine."Line No." := TempReqLine2."Line No.";
                ReqLine."Location Code" := ProdOrderComp."Location Code";
                ReqLine."Bin Code" := ProdOrderComp."Bin Code";
                ReqLine.Validate("No.", ProdOrderComp."Item No.");
                ReqLine.Validate("Variant Code", ProdOrderComp."Variant Code");
                ReqLine."Unit Of Measure Code (Demand)" := ProdOrderComp."Unit of Measure Code";
                ReqLine."Qty. per UOM (Demand)" := ProdOrderComp."Qty. per Unit of Measure";
                ReqLine.SetSupplyQty(TempReqLine2."Demand Quantity (Base)", UnAvailableQtyBase);
                ReqLine.SetSupplyDates(TempReqLine2."Demand Date");
                ReqLine."Original Item No." := TempReqLine2."No.";
                ReqLine."Original Variant Code" := TempReqLine2."Variant Code";
                OnBeforeReqLineModify(ReqLine, TempReqLine2, ProdOrderComp);
                ReqLine.Modify();
                PlanningLineMgt.Calculate(ReqLine, 1, true, true, 0);
            end;
        end;
    end;

    procedure SubstitutionPossible(ReqLine: Record "Requisition Line"): Boolean
    var
        Item: Record Item;
    begin
        if (ReqLine.Type <> ReqLine.Type::Item) or
           (ReqLine."Demand Type" <> Database::"Prod. Order Component")
        then
            exit(false);

        if not Item.Get(ReqLine."No.") then
            exit(false);

        if Item."Manufacturing Policy" = Item."Manufacturing Policy"::"Make-to-Order" then
            exit(false);

        ReqLine.CalcFields("Reserved Qty. (Base)");
        if ReqLine."Reserved Qty. (Base)" <> 0 then
            exit(false);

        if ProdOrderComp.Get(
             ReqLine."Demand Subtype",
             ReqLine."Demand Order No.",
             ReqLine."Demand Line No.",
             ReqLine."Demand Ref. No.")
        then
            if ProdOrderComp."Supplied-by Line No." <> 0 then
                exit(false);

        Item.CalcFields("Substitutes Exist");
        exit(Item."Substitutes Exist");
    end;

    procedure InsertAltSupplyLocation(var ReqLine: Record "Requisition Line")
    var
        Location: Record Location;
        TempReqLine: Record "Requisition Line" temporary;
        AvailableQtyBase: Decimal;
        NextLineNo: Integer;
    begin
        ReqLine.TestField(Type, ReqLine.Type::Item);
        if ReqLine."Location Code" = '' then
            Error(Text003, ReqLine.FieldCaption("Location Code"));

        NextLineNo := 0;

        Location.Reset();
        Location.SetRange("Use As In-Transit", false);
        Location.SetFilter(Code, '<>%1', ReqLine."Location Code");
        if Location.Find('-') then
            repeat
                AvailableQtyBase :=
                  CalcATPQty(
                    ReqLine."No.", ReqLine."Variant Code", Location.Code, ReqLine."Demand Date");

                if AvailableQtyBase > 0 then
                    AvailableQtyBase -= PromisedTransferQty(ReqLine, Location.Code);

                if AvailableQtyBase > 0 then begin
                    CalcNextLineNo(NextLineNo);
                    TempReqLine := ReqLine;
                    TempReqLine."Line No." += NextLineNo;
                    TempReqLine."Transfer-from Code" := Location.Code;

                    if TempReqLine."Qty. per Unit of Measure" = 0 then
                        TempReqLine."Qty. per Unit of Measure" := 1;

                    TempReqLine."Demand Qty. Available" :=
                      Round(AvailableQtyBase / TempReqLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                    TempReqLine.Quantity := Round(AvailableQtyBase / TempReqLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                    TempReqLine."Quantity (Base)" := AvailableQtyBase;

                    OnInsertAltSupplyLocationOnBeforeTempReqLineInsert(TempReqLine);
                    TempReqLine.Insert();
                end;
            until Location.Next() = 0;

        TempReqLine.SetRange("No.", TempReqLine."No.");
        if PAGE.RunModal(PAGE::"Get Alternative Supply", TempReqLine) = ACTION::LookupOK then begin
            ReqLine.Validate("Replenishment System", ReqLine."Replenishment System"::Transfer);
            ReqLine.Validate("Supply From", TempReqLine."Transfer-from Code");
            ReqLine.CalcStartingDate('');
            if TempReqLine."Quantity (Base)" < ReqLine."Quantity (Base)" then
                ReqLine.Validate(
                  Quantity, Round(TempReqLine."Quantity (Base)" / ReqLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision()));
        end;
    end;

    local procedure CalcNextLineNo(var NextLineNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcNextLineNo(NextLineNo, IsHandled);
        if IsHandled then
            exit;

        NextLineNo += 10000;
    end;

    local procedure PromisedTransferQty(ReqLine: Record "Requisition Line"; LocationCode: Code[10]) OrderQtyBase: Decimal
    var
        ReqLine2: Record "Requisition Line";
    begin
        ReqLine2.Reset();
        ReqLine2.SetCurrentKey("Worksheet Template Name", "Journal Batch Name", Type, "No.", "Due Date");
        ReqLine2.SetRange("Worksheet Template Name", '');
        ReqLine2.SetRange(Type, ReqLine2.Type::Item);
        ReqLine2.SetRange("No.", ReqLine."No.");
        ReqLine2.SetRange("User ID", UserId);
        ReqLine2.SetRange("Variant Code", ReqLine."Variant Code");
        ReqLine2.SetRange("Replenishment System", ReqLine2."Replenishment System"::Transfer);
        ReqLine2.SetRange("Supply From", LocationCode);
        ReqLine2.SetFilter("Line No.", '<>%1', ReqLine."Line No.");
        if ReqLine2.Find('-') then
            repeat
                OrderQtyBase += ReqLine2."Quantity (Base)";
            until ReqLine2.Next() = 0;
    end;

    procedure AvailQtyOnOtherLocations(ReqLine: Record "Requisition Line"): Decimal
    var
        Location: Record Location;
        AvailableQtyBase: Decimal;
        AvailableQtyBaseTotal: Decimal;
    begin
        if ReqLine."Location Code" = '' then
            exit(0);

        AvailableQtyBaseTotal := 0;
        Location.Reset();
        Location.SetRange("Use As In-Transit", false);
        if ReqLine."Location Code" <> '' then
            Location.SetFilter(Code, '<>%1', ReqLine."Location Code")
        else
            Location.SetFilter(Code, '<>''''');
        OnAvailQtyOnOtherLocationsOnAfterLocationSetFilters(ReqLine, Location);
        if Location.Find('-') then
            repeat
                AvailableQtyBase :=
                  CalcATPQty(
                    ReqLine."No.", ReqLine."Variant Code", Location.Code, ReqLine."Demand Date");

                if AvailableQtyBase > 0 then
                    AvailableQtyBase -= PromisedTransferQty(ReqLine, Location.Code);
                if AvailableQtyBase > 0 then
                    AvailableQtyBaseTotal += AvailableQtyBase;
            until Location.Next() = 0;

        exit(AvailableQtyBaseTotal);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransformUnplannedDemandToRequisitionLines(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAvailQtyOnOtherLocationsOnAfterLocationSetFilters(RequisitionLine: Record "Requisition Line"; var Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcNextLineNo(var NextLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIncreaseReqLineNo(var UnplannedDemand: Record "Unplanned Demand"; var ReqLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReqLineModify(var RequisitionLine: Record "Requisition Line"; RequisitionLine2: Record "Requisition Line"; ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunGetUnplannedDemand(var UnplannedDemand: Record "Unplanned Demand"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcATPQtyOnBeforeCalcQtyAvailabletoPromise(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertAltSupplyLocationOnBeforeTempReqLineInsert(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertDemandHeaderOnAfterReqLineInsert(UnplannedDemand: Record "Unplanned Demand"; var ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertDemandHeaderOnBeforeReqLineInsert(UnplannedDemand: Record "Unplanned Demand"; var ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertDemandLinesOnAfterReqLineInsert(var RequisitionLine: Record "Requisition Line"; var UnplannedDemand: Record "Unplanned Demand")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertDemandLinesOnBeforeReqLineInsert(var RequisitionLine: Record "Requisition Line"; var UnplannedDemand: Record "Unplanned Demand"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareRequisitionRecordOnBeforeDeleteAll(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertDemandLinesOnBeforeFindUnplannedDemand(var TempUnplannedDemand: Record "Unplanned Demand" temporary; var RequisitionLine: Record "Requisition Line")
    begin
    end;
}

