namespace Microsoft.Inventory.Planning;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Planning;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;

codeunit 99000809 "Planning Line Management"
{
    Permissions = TableData "Manufacturing Setup" = rm,
                  TableData "Routing Header" = r,
                  TableData "Production BOM Header" = r,
                  TableData "Production BOM Line" = r,
                  TableData "Prod. Order Capacity Need" = rd,
                  TableData "Planning Component" = rimd,
                  TableData "Planning Routing Line" = rimd;

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'BOM phantom structure for %1 is higher than 50 levels.';
#pragma warning restore AA0470
        Text002: Label 'There is not enough space to insert lower level Make-to-Order lines.';
#pragma warning restore AA0074
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        ReqLine: Record "Requisition Line";
        ProdBOMLine: array[50] of Record "Production BOM Line";
        AsmBOMComp: array[50] of Record "BOM Component";
        PlanningRtngLine2: Record "Planning Routing Line";
        PlanningComponent: Record "Planning Component";
        TempPlanningComponent: Record "Planning Component" temporary;
        TempPlanningErrorLog: Record "Planning Error Log" temporary;
        CalcPlanningRtngLine: Codeunit "Calculate Planning Route Line";
        UOMMgt: Codeunit "Unit of Measure Management";
        CostCalcMgt: Codeunit "Cost Calculation Management";
        PlanningRoutingMgt: Codeunit PlanningRoutingManagement;
        VersionMgt: Codeunit VersionManagement;
        GetPlanningParameters: Codeunit "Planning-Get Parameters";
        LeadTimeMgt: Codeunit "Lead-Time Management";
        CalendarMgt: Codeunit "Shop Calendar Management";
        LineSpacing: array[50] of Integer;
        NextPlanningCompLineNo: Integer;
        Blocked: Boolean;
        PlanningResiliency: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text010: Label 'The line with %1 %2 for %3 %4 or one of its versions, has no %5 defined.';
        Text011: Label '%1 has recalculate set to false.';
        Text012: Label 'You must specify %1 in %2 %3.';
        Text014: Label 'Production BOM Header No. %1 used by Item %2 has BOM levels that exceed 50.';
#pragma warning restore AA0470
        Text015: Label 'There is no more space to insert another line in the worksheet.';
#pragma warning restore AA0074

    local procedure TransferRouting(var ReqLine: Record "Requisition Line")
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferRouting(ReqLine, PlanningResiliency, IsHandled);
        if IsHandled then
            exit;

        if ReqLine."Routing No." = '' then
            exit;

        RoutingHeader.Get(ReqLine."Routing No.");
        RoutingLine.SetRange("Routing No.", ReqLine."Routing No.");
        RoutingLine.SetRange("Version Code", ReqLine."Routing Version Code");
        if RoutingLine.Find('-') then
            repeat
                if PlanningResiliency and PlanningRoutingLine.Recalculate then
                    TempPlanningErrorLog.SetError(
                      StrSubstNo(Text011, PlanningRoutingLine.TableCaption()),
                      Database::"Routing Header", RoutingHeader.GetPosition());
                PlanningRoutingLine.TestField(Recalculate, false);
                CheckRoutingLine(RoutingHeader, RoutingLine);
                TransferRoutingLine(PlanningRoutingLine, ReqLine, RoutingLine);
            until RoutingLine.Next() = 0;

        OnAfterTransferRouting(ReqLine);
    end;

    local procedure TransferRoutingLine(var PlanningRoutingLine: Record "Planning Routing Line"; ReqLine: Record "Requisition Line"; RoutingLine: Record "Routing Line")
    var
        WorkCenter: Record "Work Center";
        SubcontractorPrices: Record "Subcontractor Prices";
        SubcontractingPricesMgt: Codeunit SubcontractingPricesMgt;
        IsHandled: Boolean;	
    begin
        OnBeforeTransferRoutingLine(PlanningRoutingLine, ReqLine, RoutingLine, IsHandled);
        if IsHandled then
            exit;
        PlanningRoutingLine.TransferFromReqLine(ReqLine);
        PlanningRoutingLine.TransferFromRoutingLine(RoutingLine);

        OnTransferRoutingLineOnBeforeCalcRoutingCostPerUnit(PlanningRoutingLine, ReqLine, RoutingLine);

        if RoutingLine.Type = RoutingLine.Type::"Work Center" then
            WorkCenter.Get(RoutingLine."Work Center No.");

        if (RoutingLine.Type = RoutingLine.Type::"Work Center") and (WorkCenter."Subcontractor No." <> '') then begin
            SubcontractorPrices."Vendor No." := WorkCenter."Subcontractor No.";
            SubcontractorPrices."Item No." := ReqLine."No.";
            SubcontractorPrices."Standard Task Code" := PlanningRoutingLine."Standard Task Code";
            SubcontractorPrices."Work Center No." := WorkCenter."No.";
            SubcontractorPrices."Variant Code" := ReqLine."Variant Code";
            SubcontractorPrices."Unit of Measure Code" := ReqLine."Unit of Measure Code";
            SubcontractorPrices."Start Date" := ReqLine."Order Date";
            SubcontractorPrices."Currency Code" := '';
            SubcontractingPricesMgt.GetRoutingPricelistCost(
              SubcontractorPrices, WorkCenter,
              PlanningRoutingLine."Direct Unit Cost", PlanningRoutingLine."Indirect Cost %", PlanningRoutingLine."Overhead Rate", PlanningRoutingLine."Unit Cost per", PlanningRoutingLine."Unit Cost Calculation",
              ReqLine.Quantity, ReqLine."Qty. per Unit of Measure", ReqLine."Quantity (Base)");
        end else
            CostCalcMgt.CalcRoutingCostPerUnit(
              PlanningRoutingLine.Type, PlanningRoutingLine."No.", PlanningRoutingLine."Direct Unit Cost", PlanningRoutingLine."Indirect Cost %", PlanningRoutingLine."Overhead Rate", PlanningRoutingLine."Unit Cost per", PlanningRoutingLine."Unit Cost Calculation");

        OnTransferRoutingLineOnBeforeValidateDirectUnitCost(ReqLine, RoutingLine, PlanningRoutingLine);
        PlanningRoutingLine.Validate("Direct Unit Cost");

        PlanningRoutingLine.UpdateDatetime();
        OnAfterTransferRtngLine(ReqLine, RoutingLine, PlanningRoutingLine);
        PlanningRoutingLine.Insert();
    end;

    local procedure TransferBOM(ProdBOMNo: Code[20]; Level: Integer; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal)
    var
        BOMHeader: Record "Production BOM Header";
        CompSKU: Record "Stockkeeping Unit";
        ProductionBOMVersion: Record "Production BOM Version";
        Item: Record Item;
        VersionCode: Code[20];
        ReqQty: Decimal;
        IsHandled: Boolean;
        UpdateCondition: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferBOM(ProdBOMNo, Level, LineQtyPerUOM, ItemQtyPerUOM, ReqLine, Blocked, IsHandled);
        if not IsHandled then begin

            if ReqLine."Production BOM No." = '' then
                exit;

            PlanningComponent.LockTable();

            if Level > 50 then begin
                if PlanningResiliency then begin
                    BOMHeader.Get(ReqLine."Production BOM No.");
                    TempPlanningErrorLog.SetError(
                      StrSubstNo(Text014, ReqLine."Production BOM No.", ReqLine."No."),
                      Database::"Production BOM Header", BOMHeader.GetPosition());
                end;
                Error(
                  Text000,
                  ProdBOMNo);
            end;

            if NextPlanningCompLineNo = 0 then begin
                PlanningComponent.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
                PlanningComponent.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
                PlanningComponent.SetRange("Worksheet Line No.", ReqLine."Line No.");
                if PlanningComponent.Find('+') then
                    NextPlanningCompLineNo := PlanningComponent."Line No.";
                PlanningComponent.Reset();
            end;

            BOMHeader.Get(ProdBOMNo);

            if Level > 1 then
                VersionCode := VersionMgt.GetBOMVersion(ProdBOMNo, ReqLine."Starting Date", true)
            else
                VersionCode := ReqLine."Production BOM Version Code";
            if VersionCode <> '' then begin
                ProductionBOMVersion.Get(ProdBOMNo, VersionCode);
                ProductionBOMVersion.TestField(Status, ProductionBOMVersion.Status::Certified);
            end else
                BOMHeader.TestField(Status, BOMHeader.Status::Certified);

            ProdBOMLine[Level].SetRange("Production BOM No.", ProdBOMNo);
            if Level > 1 then
                ProdBOMLine[Level].SetRange("Version Code", VersionMgt.GetBOMVersion(BOMHeader."No.", ReqLine."Starting Date", true))
            else
                ProdBOMLine[Level].SetRange("Version Code", ReqLine."Production BOM Version Code");
            ProdBOMLine[Level].SetFilter("Starting Date", '%1|..%2', 0D, ReqLine."Starting Date");
            ProdBOMLine[Level].SetFilter("Ending Date", '%1|%2..', 0D, ReqLine."Starting Date");
            OnTransferBOMOnAfterProdBOMLineSetFilters(ProdBOMLine[Level], ReqLine);
            if ProdBOMLine[Level].Find('-') then
                repeat
                    IsHandled := false;
                    OnTransferBOMOnBeforeTransferPlanningComponent(ReqLine, ProdBOMLine[Level], Blocked, IsHandled, Level);
                    if not IsHandled then begin
                        if ProdBOMLine[Level]."Routing Link Code" <> '' then begin
                            PlanningRtngLine2.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
                            PlanningRtngLine2.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
                            PlanningRtngLine2.SetRange("Worksheet Line No.", ReqLine."Line No.");
                            PlanningRtngLine2.SetRange("Routing Link Code", ProdBOMLine[Level]."Routing Link Code");
                            PlanningRtngLine2.FindFirst();
                            ReqQty :=
                              ProdBOMLine[Level].Quantity *
                              (1 + ProdBOMLine[Level]."Scrap %" / 100) *
                              (1 + PlanningRtngLine2."Scrap Factor % (Accumulated)") *
                              LineQtyPerUOM / ItemQtyPerUOM +
                              PlanningRtngLine2."Fixed Scrap Qty. (Accum.)";
                        end else
                            ReqQty :=
                              ProdBOMLine[Level].Quantity *
                              (1 + ProdBOMLine[Level]."Scrap %" / 100) *
                              LineQtyPerUOM / ItemQtyPerUOM;

                        OnTransferBOMOnAfterCalculateReqQty(ReqQty, ProdBOMLine[Level], PlanningRtngLine2, LineQtyPerUOM, ItemQtyPerUOM);
                        case ProdBOMLine[Level].Type of
                            ProdBOMLine[Level].Type::Item:
                                begin
                                    IsHandled := false;
                                    Item.SetLoadFields(Blocked);
                                    Item.Get(ProdBOMLine[Level]."No.");
                                    UpdateCondition := (ReqQty <> 0) or ((ReqQty = 0) and not (Item.Blocked));
                                    OnTransferBOMOnBeforeUpdatePlanningComp(ProdBOMLine[Level], UpdateCondition, IsHandled);
                                    if not IsHandled then
                                        if UpdateCondition then begin
                                            if not IsPlannedComp(PlanningComponent, ReqLine, ProdBOMLine[Level]) then begin
                                                NextPlanningCompLineNo := NextPlanningCompLineNo + 10000;
                                                CreatePlanningComponentFromProdBOM(
                                                  PlanningComponent, ReqLine, ProdBOMLine[Level], CompSKU, LineQtyPerUOM, ItemQtyPerUOM);
                                            end else begin
                                                PlanningComponent.Reset();
                                                PlanningComponent.BlockDynamicTracking(Blocked);
                                                PlanningComponent.SetRequisitionLine(ReqLine);
                                                PlanningComponent.Validate(
                                                  "Quantity per",
                                                  PlanningComponent."Quantity per" + ProdBOMLine[Level]."Quantity per" * LineQtyPerUOM / ItemQtyPerUOM);
                                                PlanningComponent.Validate("Routing Link Code", ProdBOMLine[Level]."Routing Link Code");
                                                OnBeforeModifyPlanningComponent(ReqLine, ProdBOMLine[Level], PlanningComponent, LineQtyPerUOM, ItemQtyPerUOM);
                                                PlanningComponent.Modify();
                                            end;

                                            // A temporary list of Planning Components handled is sustained:
                                            TempPlanningComponent := PlanningComponent;
                                            if not TempPlanningComponent.Insert() then
                                                TempPlanningComponent.Modify();
                                        end;
                                end;
                            ProdBOMLine[Level].Type::"Production BOM":
                                begin
                                    OnTransferBOMOnBeforeTransferProductionBOM(ReqQty, ProdBOMLine[Level], LineQtyPerUOM, ItemQtyPerUOM, ReqLine);
                                    TransferBOM(ProdBOMLine[Level]."No.", Level + 1, ReqQty, 1);
                                    ProdBOMLine[Level].SetRange("Production BOM No.", ProdBOMNo);
                                    if Level > 1 then
                                        ProdBOMLine[Level].SetRange("Version Code", VersionMgt.GetBOMVersion(ProdBOMNo, ReqLine."Starting Date", true))
                                    else
                                        ProdBOMLine[Level].SetRange("Version Code", ProdBOMLine[Level]."Version Code");
                                    ProdBOMLine[Level].SetFilter("Starting Date", '%1|..%2', 0D, ReqLine."Starting Date");
                                    ProdBOMLine[Level].SetFilter("Ending Date", '%1|%2..', 0D, ReqLine."Starting Date");
                                end;
                        end;
                    end;
                until ProdBOMLine[Level].Next() = 0;
        end;
        OnAfterTransferBOM(ReqLine, ProdBOMNo, Level, LineQtyPerUOM, ItemQtyPerUOM);
    end;

    local procedure TransferAsmBOM(ParentItemNo: Code[20]; Level: Integer; Quantity: Decimal)
    var
        ParentItem: Record Item;
        CompSKU: Record "Stockkeeping Unit";
        Item2: Record Item;
        ReqQty: Decimal;
    begin
        PlanningComponent.LockTable();

        if Level > 50 then begin
            if PlanningResiliency then begin
                Item.Get(ReqLine."No.");
                TempPlanningErrorLog.SetError(
                  StrSubstNo(Text014, ReqLine."No.", ReqLine."No."),
                  Database::Item, Item.GetPosition());
            end;
            Error(
              Text000,
              ParentItemNo);
        end;

        if NextPlanningCompLineNo = 0 then begin
            PlanningComponent.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
            PlanningComponent.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
            PlanningComponent.SetRange("Worksheet Line No.", ReqLine."Line No.");
            if PlanningComponent.Find('+') then
                NextPlanningCompLineNo := PlanningComponent."Line No.";
            PlanningComponent.Reset();
        end;

        ParentItem.Get(ParentItemNo);

        AsmBOMComp[Level].SetRange("Parent Item No.", ParentItemNo);
        if AsmBOMComp[Level].Find('-') then
            repeat
                ReqQty := Quantity * AsmBOMComp[Level]."Quantity per";
                case AsmBOMComp[Level].Type of
                    AsmBOMComp[Level].Type::Item:
                        if ReqQty <> 0 then begin
                            if not IsPlannedAsmComp(PlanningComponent, ReqLine, AsmBOMComp[Level]) then begin
                                NextPlanningCompLineNo := NextPlanningCompLineNo + 10000;

                                PlanningComponent.Reset();
                                PlanningComponent.Init();
                                PlanningComponent.BlockDynamicTracking(Blocked);
                                PlanningComponent.SetRequisitionLine(ReqLine);
                                PlanningComponent."Worksheet Template Name" := ReqLine."Worksheet Template Name";
                                PlanningComponent."Worksheet Batch Name" := ReqLine."Journal Batch Name";
                                PlanningComponent."Worksheet Line No." := ReqLine."Line No.";
                                PlanningComponent."Line No." := NextPlanningCompLineNo;
                                PlanningComponent.Validate("Item No.", AsmBOMComp[Level]."No.");
                                PlanningComponent."Variant Code" := AsmBOMComp[Level]."Variant Code";
                                if IsInventoryItem(AsmBOMComp[Level]."No.") then
                                    PlanningComponent."Location Code" := SKU."Components at Location";
                                PlanningComponent.Description := CopyStr(AsmBOMComp[Level].Description, 1, MaxStrLen(PlanningComponent.Description));
                                PlanningComponent."Planning Line Origin" := ReqLine."Planning Line Origin";
                                PlanningComponent.Validate("Unit of Measure Code", AsmBOMComp[Level]."Unit of Measure Code");
                                PlanningComponent."Quantity per" := Quantity * AsmBOMComp[Level]."Quantity per";
                                OnTransferAsmBOMOnBeforeGetDefaultBin(PlanningComponent, AsmBOMComp[Level], ReqLine);
                                PlanningComponent.GetDefaultBin();
                                PlanningComponent.Quantity := AsmBOMComp[Level]."Quantity per";
                                PlanningComponent.Position := AsmBOMComp[Level].Position;
                                PlanningComponent."Position 2" := AsmBOMComp[Level]."Position 2";
                                PlanningComponent."Position 3" := AsmBOMComp[Level]."Position 3";
                                PlanningComponent."Lead-Time Offset" := AsmBOMComp[Level]."Lead-Time Offset";
                                PlanningComponent.Validate("Routing Link Code");
                                PlanningComponent.Validate("Scrap %", 0);
                                PlanningComponent.Validate("Calculation Formula", PlanningComponent."Calculation Formula"::" ");
                                GetPlanningParameters.AtSKU(
                                  CompSKU,
                                  PlanningComponent."Item No.",
                                  PlanningComponent."Variant Code",
                                  PlanningComponent."Location Code");
                                if Item2.Get(PlanningComponent."Item No.") then
                                    PlanningComponent.Critical := Item2.Critical;

                                PlanningComponent."Flushing Method" := CompSKU."Flushing Method";
                                PlanningComponent."Ref. Order Type" := ReqLine."Ref. Order Type";
                                PlanningComponent."Ref. Order Status" := ReqLine."Ref. Order Status";
                                PlanningComponent."Ref. Order No." := ReqLine."Ref. Order No.";
                                OnBeforeInsertAsmPlanningComponent(ReqLine, AsmBOMComp[Level], PlanningComponent);
                                PlanningComponent.Insert();
                            end else begin
                                PlanningComponent.Reset();
                                PlanningComponent.BlockDynamicTracking(Blocked);
                                PlanningComponent.SetRequisitionLine(ReqLine);
                                PlanningComponent.Validate(
                                  "Quantity per",
                                  PlanningComponent."Quantity per" +
                                  Quantity *
                                  AsmBOMComp[Level]."Quantity per");
                                PlanningComponent.Validate("Routing Link Code", '');
                                PlanningComponent.Modify();
                            end;

                            // A temporary list of Planning Components handled is sustained:
                            TempPlanningComponent := PlanningComponent;
                            if not TempPlanningComponent.Insert() then
                                TempPlanningComponent.Modify();
                        end;
                end;
            until AsmBOMComp[Level].Next() = 0;
    end;

    local procedure CalculateComponents()
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        PlanningComponent.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
        PlanningComponent.SetRange("Worksheet Line No.", ReqLine."Line No.");

        if PlanningComponent.Find('-') then
            repeat
                PlanningComponent.BlockDynamicTracking(Blocked);
                PlanningComponent.SetRequisitionLine(ReqLine);
                PlanningComponent.Validate("Routing Link Code");
                PlanningComponent.Modify();
                PlanningAssignment.ChkAssignOne(PlanningComponent."Item No.", PlanningComponent."Variant Code", PlanningComponent."Location Code", PlanningComponent."Due Date");
            until PlanningComponent.Next() = 0;
    end;

    procedure CalculateRoutingFromActual(PlanningRtngLine: Record "Planning Routing Line"; Direction: Option Forward,Backward; CalcStartEndDate: Boolean)
    begin
        if (ReqLine."Worksheet Template Name" <> PlanningRtngLine."Worksheet Template Name") or
           (ReqLine."Journal Batch Name" <> PlanningRtngLine."Worksheet Batch Name") or
           (ReqLine."Line No." <> PlanningRtngLine."Worksheet Line No.")
        then
            ReqLine.Get(
              PlanningRtngLine."Worksheet Template Name",
              PlanningRtngLine."Worksheet Batch Name", PlanningRtngLine."Worksheet Line No.");

        if PlanningRoutingMgt.NeedsCalculation(
             PlanningRtngLine."Worksheet Template Name",
             PlanningRtngLine."Worksheet Batch Name",
             PlanningRtngLine."Worksheet Line No.")
        then begin
            PlanningRoutingMgt.Calculate(ReqLine);
            PlanningRtngLine.Get(
              PlanningRtngLine."Worksheet Template Name",
              PlanningRtngLine."Worksheet Batch Name",
              PlanningRtngLine."Worksheet Line No.", PlanningRtngLine."Operation No.");
        end;
        if Direction = Direction::Forward then
            PlanningRtngLine.SetCurrentKey(
              "Worksheet Template Name",
              "Worksheet Batch Name",
              "Worksheet Line No.",
              "Sequence No.(Forward)")
        else
            PlanningRtngLine.SetCurrentKey(
              "Worksheet Template Name",
              "Worksheet Batch Name",
              "Worksheet Line No.",
              "Sequence No.(Backward)");

        PlanningRtngLine.SetRange("Worksheet Template Name", PlanningRtngLine."Worksheet Template Name");
        PlanningRtngLine.SetRange("Worksheet Batch Name", PlanningRtngLine."Worksheet Batch Name");
        PlanningRtngLine.SetRange("Worksheet Line No.", PlanningRtngLine."Worksheet Line No.");

        repeat
            if CalcStartEndDate then
                if ((Direction = Direction::Forward) and (PlanningRtngLine."Previous Operation No." <> '')) or
                   ((Direction = Direction::Backward) and (PlanningRtngLine."Next Operation No." <> ''))
                then begin
                    PlanningRtngLine."Starting Time" := 0T;
                    PlanningRtngLine."Starting Date" := 0D;
                    PlanningRtngLine."Ending Time" := 235959T;
                    PlanningRtngLine."Ending Date" := CalendarMgt.GetMaxDate();
                end;
            Clear(CalcPlanningRtngLine);
            if PlanningResiliency then
                CalcPlanningRtngLine.SetResiliencyOn(
                  ReqLine."Worksheet Template Name", ReqLine."Journal Batch Name", ReqLine."No.");
            CalcPlanningRtngLine.CalculateRouteLine(PlanningRtngLine, Direction, CalcStartEndDate, ReqLine);
            CalcStartEndDate := true;
        until PlanningRtngLine.Next() = 0;
    end;

    local procedure CalculateRouting(Direction: Option Forward,Backward)
    var
        PlanningRtngLine: Record "Planning Routing Line";
    begin
        if PlanningRoutingMgt.NeedsCalculation(
             ReqLine."Worksheet Template Name",
             ReqLine."Journal Batch Name",
             ReqLine."Line No.")
        then
            PlanningRoutingMgt.Calculate(ReqLine);

        if Direction = Direction::Forward then
            PlanningRtngLine.SetCurrentKey(
              "Worksheet Template Name",
              "Worksheet Batch Name",
              "Worksheet Line No.",
              "Sequence No.(Forward)")
        else
            PlanningRtngLine.SetCurrentKey(
              "Worksheet Template Name",
              "Worksheet Batch Name",
              "Worksheet Line No.",
              "Sequence No.(Backward)");

        PlanningRtngLine.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
        PlanningRtngLine.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
        PlanningRtngLine.SetRange("Worksheet Line No.", ReqLine."Line No.");
        if not PlanningRtngLine.FindFirst() then begin
            if Direction = Direction::Forward then
                ReqLine.CalcEndingDate('')
            else
                ReqLine.CalcStartingDate('');
            ReqLine.UpdateDatetime();
            OnCalculateRoutingOnAfterUpdateReqLine(ReqLine, Direction);
            exit;
        end;

        if Direction = Direction::Forward then begin
            PlanningRtngLine."Starting Date" := ReqLine."Starting Date";
            PlanningRtngLine."Starting Time" := ReqLine."Starting Time";
        end else begin
            PlanningRtngLine."Ending Date" := ReqLine."Ending Date";
            PlanningRtngLine."Ending Time" := ReqLine."Ending Time";
        end;
        CalculateRoutingFromActual(PlanningRtngLine, Direction, false);

        CalculatePlanningLineDates(ReqLine);
    end;

    procedure CalculatePlanningLineDates(var ReqLine2: Record "Requisition Line")
    var
        PlanningRtngLine: Record "Planning Routing Line";
        IsLineModified: Boolean;
    begin
        PlanningRtngLine.SetRange("Worksheet Template Name", ReqLine2."Worksheet Template Name");
        PlanningRtngLine.SetRange("Worksheet Batch Name", ReqLine2."Journal Batch Name");
        PlanningRtngLine.SetRange("Worksheet Line No.", ReqLine2."Line No.");
        PlanningRtngLine.SetFilter("Next Operation No.", '%1', '');

        if PlanningRtngLine.FindFirst() then begin
            ReqLine2."Ending Date" := PlanningRtngLine."Ending Date";
            ReqLine2."Ending Time" := PlanningRtngLine."Ending Time";
            IsLineModified := true;
        end;

        PlanningRtngLine.SetRange("Next Operation No.");
        PlanningRtngLine.SetFilter("Previous Operation No.", '%1', '');
        if PlanningRtngLine.FindFirst() then begin
            ReqLine2."Starting Date" := PlanningRtngLine."Starting Date";
            ReqLine2."Starting Time" := PlanningRtngLine."Starting Time";
            ReqLine2."Order Date" := PlanningRtngLine."Starting Date";
            IsLineModified := true;
        end;

        if IsLineModified then begin
            ReqLine2.UpdateDatetime();
            ReqLine2.Modify();
        end;
    end;

    procedure Calculate(var ReqLine2: Record "Requisition Line"; Direction: Option Forward,Backward; CalcRouting: Boolean; CalcComponents: Boolean; PlanningLevel: Integer)
    var
        PlanningRtngLine: Record "Planning Routing Line";
        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculate(ReqLine2, Direction, CalcRouting, CalcComponents, PlanningLevel, IsHandled);
        if IsHandled then
            exit;

        ReqLine := ReqLine2;
        if ReqLine."Action Message" <> ReqLine."Action Message"::Cancel then
            ReqLine.TestField(Quantity);
        if Direction = Direction::Backward then
            ReqLine.TestField("Ending Date")
        else
            ReqLine.TestField("Starting Date");

        if CalcRouting then begin
            PlanningRtngLine.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
            PlanningRtngLine.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
            PlanningRtngLine.SetRange("Worksheet Line No.", ReqLine."Line No.");
            PlanningRtngLine.DeleteAll();

            ProdOrderCapNeed.SetCurrentKey(
              "Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.");
            ProdOrderCapNeed.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
            ProdOrderCapNeed.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
            ProdOrderCapNeed.SetRange("Worksheet Line No.", ReqLine."Line No.");
            ProdOrderCapNeed.DeleteAll();
            TransferRouting(ReqLine);
        end;

        if CalcComponents then begin
            PlanningComponent.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
            PlanningComponent.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
            PlanningComponent.SetRange("Worksheet Line No.", ReqLine."Line No.");
            if PlanningComponent.Find('-') then
                repeat
                    PlanningComponent.BlockDynamicTracking(Blocked);
                    PlanningComponent.Delete(true);
                until PlanningComponent.Next() = 0;
            if ReqLine."Planning Level" = 0 then
                ReqLine.DeleteMultiLevel();
            if (ReqLine."Replenishment System" = ReqLine."Replenishment System"::Assembly) or
               ((ReqLine."Replenishment System" = ReqLine."Replenishment System"::"Prod. Order") and (ReqLine."Production BOM No." <> ''))
            then begin
                Item.Get(ReqLine."No.");
                GetPlanningParameters.AtSKU(SKU, ReqLine."No.", ReqLine."Variant Code", ReqLine."Location Code");

                if ReqLine."Replenishment System" = ReqLine."Replenishment System"::Assembly then
                    TransferAsmBOM(Item."No.", 1, ReqLine."Qty. per Unit of Measure")
                else begin
                    IsHandled := false;
                    OnCalculateOnBeforeTransferBOM(ReqLine, SKU, PlanningResiliency, IsHandled);
                    if not IsHandled then
                        TransferBOM(
                          ReqLine."Production BOM No.", 1, ReqLine."Qty. per Unit of Measure",
                          UOMMgt.GetQtyPerUnitOfMeasure(
                            Item, VersionMgt.GetBOMUnitOfMeasure(ReqLine."Production BOM No.", ReqLine."Production BOM Version Code")));
                end;
            end;
        end;
        Recalculate(ReqLine, Direction);
        ReqLine2 := ReqLine;
        if CalcComponents and
           (SKU."Manufacturing Policy" = SKU."Manufacturing Policy"::"Make-to-Order")
        then
            CheckMultiLevelStructure(ReqLine, CalcRouting, CalcComponents, PlanningLevel);

        OnAfterCalculate(CalcComponents, SKU, ReqLine2);
    end;

    local procedure CreatePlanningComponentFromProdBOM(var PlanningComponent: Record "Planning Component"; ReqLine: Record "Requisition Line"; ProdBOMLine: Record "Production BOM Line"; CompSKU: Record "Stockkeeping Unit"; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal)
    var
        Item2: Record Item;
    begin
        PlanningComponent.Reset();
        PlanningComponent.Init();
        PlanningComponent.BlockDynamicTracking(Blocked);
        PlanningComponent.SetRequisitionLine(ReqLine);
        PlanningComponent."Worksheet Template Name" := ReqLine."Worksheet Template Name";
        PlanningComponent."Worksheet Batch Name" := ReqLine."Journal Batch Name";
        PlanningComponent."Worksheet Line No." := ReqLine."Line No.";
        PlanningComponent."Line No." := NextPlanningCompLineNo;
        PlanningComponent.Validate("Item No.", ProdBOMLine."No.");
        PlanningComponent."Variant Code" := ProdBOMLine."Variant Code";
        if IsInventoryItem(ProdBOMLine."No.") then
            PlanningComponent."Location Code" := SKU."Components at Location";
        PlanningComponent.Description := ProdBOMLine.Description;
        PlanningComponent."Planning Line Origin" := ReqLine."Planning Line Origin";
        PlanningComponent.Validate("Unit of Measure Code", ProdBOMLine."Unit of Measure Code");
        PlanningComponent."Quantity per" := ProdBOMLine."Quantity per" * LineQtyPerUOM / ItemQtyPerUOM;
        PlanningComponent.Validate("Routing Link Code", ProdBOMLine."Routing Link Code");
        PlanningComponent.Length := ProdBOMLine.Length;
        PlanningComponent.Width := ProdBOMLine.Width;
        PlanningComponent.Weight := ProdBOMLine.Weight;
        PlanningComponent.Depth := ProdBOMLine.Depth;
        PlanningComponent.Quantity := ProdBOMLine.Quantity;
        PlanningComponent.Position := ProdBOMLine.Position;
        PlanningComponent."Position 2" := ProdBOMLine."Position 2";
        PlanningComponent."Position 3" := ProdBOMLine."Position 3";
        PlanningComponent."Lead-Time Offset" := ProdBOMLine."Lead-Time Offset";
        PlanningComponent.Validate("Scrap %", ProdBOMLine."Scrap %");
        PlanningComponent.Validate("Calculation Formula", ProdBOMLine."Calculation Formula");

        GetPlanningParameters.AtSKU(CompSKU, PlanningComponent."Item No.", PlanningComponent."Variant Code", PlanningComponent."Location Code");
        if Item2.Get(PlanningComponent."Item No.") then
            PlanningComponent.Critical := Item2.Critical;

        PlanningComponent."Flushing Method" := CompSKU."Flushing Method";
        OnTransferBOMOnBeforeGetDefaultBin(PlanningComponent, ProdBOMLine, ReqLine, SKU);
        PlanningComponent.GetDefaultBin();

        if SetPlanningLevelCode(PlanningComponent, ProdBOMLine, SKU, CompSKU) then
            PlanningComponent."Planning Level Code" := ReqLine."Planning Level" + 1;

        PlanningComponent."Ref. Order Type" := ReqLine."Ref. Order Type";
        PlanningComponent."Ref. Order Status" := ReqLine."Ref. Order Status";
        PlanningComponent."Ref. Order No." := ReqLine."Ref. Order No.";
        OnBeforeInsertPlanningComponent(ReqLine, ProdBOMLine, PlanningComponent, LineQtyPerUOM, ItemQtyPerUOM);
        PlanningComponent.Insert();
    end;

    local procedure SetPlanningLevelCode(var PlanningComponent: Record "Planning Component"; var ProdBOMLine: Record "Production BOM Line"; var SKU: Record "Stockkeeping Unit"; var ComponentSKU: Record "Stockkeeping Unit") Result: Boolean
    begin
        Result :=
            (SKU."Manufacturing Policy" = SKU."Manufacturing Policy"::"Make-to-Order") and
            (ComponentSKU."Manufacturing Policy" = ComponentSKU."Manufacturing Policy"::"Make-to-Order") and
            (ComponentSKU."Replenishment System" = ComponentSKU."Replenishment System"::"Prod. Order");

        OnAfterSetPlanningLevelCode(PlanningComponent, ProdBOMLine, SKU, ComponentSKU, Result);
    end;

    procedure Recalculate(var ReqLine2: Record "Requisition Line"; Direction: Option Forward,Backward)
    begin
        RecalculateWithOptionalModify(ReqLine2, Direction, true);
    end;

    procedure RecalculateWithOptionalModify(var ReqLine2: Record "Requisition Line"; Direction: Option Forward,Backward; ModifyRec: Boolean)
    begin
        OnBeforeRecalculateWithOptionalModify(ReqLine2, Direction);

        ReqLine := ReqLine2;

        CalculateRouting(Direction);
        if ModifyRec then
            ReqLine.Modify(true);
        CalculateComponents();
        if ReqLine."Planning Level" > 0 then begin
            if Direction = Direction::Forward then
                ReqLine."Due Date" := ReqLine."Ending Date"
        end else
            if (ReqLine."Due Date" < ReqLine."Ending Date") or
               (Direction = Direction::Forward)
            then
                ReqLine."Due Date" :=
                  LeadTimeMgt.GetPlannedDueDate(
                    ReqLine."No.",
                    ReqLine."Location Code",
                    ReqLine."Variant Code",
                    ReqLine."Ending Date",
                    ReqLine."Vendor No.",
                    ReqLine."Ref. Order Type");
        ReqLine.UpdateDatetime();
        ReqLine2 := ReqLine;

        OnAfterRecalculateWithOptionalModify(ReqLine2, Direction);
    end;

    local procedure CheckRoutingLine(RoutingHeader: Record "Routing Header"; RoutingLine: Record "Routing Line")
    var
        MachineCenter: Record "Machine Center";
    begin
        if PlanningResiliency and (RoutingLine."No." = '') then begin
            RoutingHeader.Get(RoutingLine."Routing No.");
            TempPlanningErrorLog.SetError(
              StrSubstNo(
                Text010,
                RoutingLine.FieldCaption("Operation No."), RoutingLine."Operation No.",
                RoutingHeader.TableCaption(), RoutingHeader."No.",
                RoutingLine.FieldCaption("No.")),
              Database::"Routing Header", RoutingHeader.GetPosition());
        end;
        RoutingLine.TestField("No.");

        if PlanningResiliency and (RoutingLine."Work Center No." = '') then begin
            MachineCenter.Get(RoutingLine."No.");
            TempPlanningErrorLog.SetError(
              StrSubstNo(
                Text012,
                MachineCenter.FieldCaption("Work Center No."),
                MachineCenter.TableCaption(),
                MachineCenter."No."),
              Database::"Machine Center", MachineCenter.GetPosition());
        end;
        RoutingLine.TestField("Work Center No.");
    end;

    procedure CheckMultiLevelStructure(ReqLine2: Record "Requisition Line"; CalcRouting: Boolean; CalcComponents: Boolean; PlanningLevel: Integer)
    var
        ReqLine3: Record "Requisition Line";
        Item3: Record Item;
        PlanningComp: Record "Planning Component";
        TrackingSpecification: Record "Tracking Specification";
        PlngComponentReserve: Codeunit "Plng. Component-Reserve";
        PlanningLineNo: Integer;
        NoOfComponents: Integer;
        ShouldExit: Boolean;
        ThrowLineSpacingError: Boolean;
    begin
        if PlanningLevel < 0 then
            exit;

        if not Item3.Get(ReqLine2."No.") then
            exit;

        ShouldExit := Item3."Manufacturing Policy" <> Item3."Manufacturing Policy"::"Make-to-Order";
        OnCheckMultiLevelStructureOnAfterCalcShouldExitManufacturingPolicy(ReqLine2, ShouldExit);
        if ShouldExit then
            exit;

        PlanningLineNo := ReqLine2."Line No.";

        PlanningComp.SetRange("Worksheet Line No.", ReqLine2."Line No.");
        PlanningComp.SetFilter("Item No.", '<>%1', '');
        PlanningComp.SetFilter("Expected Quantity", '<>0');
        PlanningComp.SetFilter("Planning Level Code", '>0');
        OnCheckMultiLevelStructureOnAfterPlanningCompSetFilters(PlanningComp, ReqLine2);
        NoOfComponents := PlanningComp.Count();
        if PlanningLevel = 0 then begin
            ReqLine3.Reset();
            ReqLine3.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
            ReqLine3.SetRange("Journal Batch Name", ReqLine."Journal Batch Name");
            ReqLine3 := ReqLine2;
            if ReqLine3.Find('>') then
                LineSpacing[1] := (ReqLine3."Line No." - ReqLine."Line No.") div (1 + NoOfComponents)
            else
                LineSpacing[1] := 10000;
        end else
            if (PlanningLevel > 0) and (PlanningLevel < 50) then
                LineSpacing[PlanningLevel + 1] := LineSpacing[PlanningLevel] div (1 + NoOfComponents);

        if PlanningComp.Find('-') then
            repeat
                ThrowLineSpacingError := LineSpacing[PlanningLevel + 1] = 0;
                OnCheckMultiLevelStructureOnAfterCalcThrowLineSpacingError(ReqLine2, LineSpacing, PlanningLineNo, ThrowLineSpacingError);
                if ThrowLineSpacingError then begin
                    if PlanningResiliency then
                        TempPlanningErrorLog.SetError(Text015, Database::"Requisition Line", ReqLine.GetPosition());
                    Error(Text002);
                end;
                ReqLine3.Init();
                ReqLine3.BlockDynamicTracking(Blocked);
                ReqLine3."Worksheet Template Name" := ReqLine2."Worksheet Template Name";
                ReqLine3."Journal Batch Name" := ReqLine2."Journal Batch Name";
                PlanningLineNo := PlanningLineNo + LineSpacing[PlanningLevel + 1];
                ReqLine3."Line No." := PlanningLineNo;
                ReqLine3."Ref. Order Type" := ReqLine2."Ref. Order Type";
                ReqLine3."Ref. Order Status" := ReqLine2."Ref. Order Status";
                ReqLine3."Ref. Order No." := ReqLine2."Ref. Order No.";

                ReqLine3."Planning Line Origin" := ReqLine2."Planning Line Origin";
                ReqLine3.Level := ReqLine2.Level;
                ReqLine3."Demand Type" := ReqLine2."Demand Type";
                ReqLine3."Demand Subtype" := ReqLine2."Demand Subtype";
                ReqLine3."Demand Order No." := ReqLine2."Demand Order No.";
                ReqLine3."Demand Line No." := ReqLine2."Demand Line No.";
                ReqLine3."Demand Ref. No." := ReqLine2."Demand Ref. No.";
                ReqLine3."Demand Ref. No." := ReqLine2."Demand Ref. No.";
                ReqLine3."Demand Date" := ReqLine2."Demand Date";
                ReqLine3.Status := ReqLine2.Status;
                ReqLine3."User ID" := ReqLine2."User ID";

                ReqLine3.Type := ReqLine3.Type::Item;
                ReqLine3.Validate("No.", PlanningComp."Item No.");
                ReqLine3."Action Message" := ReqLine2."Action Message";
                ReqLine3."Accept Action Message" := ReqLine2."Accept Action Message";
                ReqLine3.Description := PlanningComp.Description;
                ReqLine3."Variant Code" := PlanningComp."Variant Code";
                ReqLine3."Unit of Measure Code" := PlanningComp."Unit of Measure Code";
                ReqLine3."Location Code" := PlanningComp."Location Code";
                ReqLine3."Bin Code" := PlanningComp."Bin Code";
                ReqLine3."Ending Date" := PlanningComp."Due Date";
                ReqLine3.Validate("Ending Time", PlanningComp."Due Time");
                ReqLine3."Due Date" := PlanningComp."Due Date";
                ReqLine3."Demand Date" := PlanningComp."Due Date";
                OnCheckMultiLevelStructureOnBeforeValidateQuantity(ReqLine3, PlanningComp);
                ReqLine3.Validate(Quantity, PlanningComp."Expected Quantity");
                ReqLine3.Validate("Needed Quantity", PlanningComp."Expected Quantity");
                ReqLine3.Validate("Demand Quantity", PlanningComp."Expected Quantity");
                ReqLine3."Demand Qty. Available" := 0;

                ReqLine3."Planning Level" := PlanningLevel + 1;
                ReqLine3."Related to Planning Line" := ReqLine2."Line No.";
                ReqLine3."Order Promising ID" := ReqLine2."Order Promising ID";
                ReqLine3."Order Promising Line ID" := ReqLine2."Order Promising Line ID";
                OnCheckMultiLevelStructureOnBeforeInsertPlanningLine(ReqLine3, PlanningComp);
                InsertPlanningLine(ReqLine3);
                ReqLine3.Quantity :=
                  Round(
                    ReqLine3."Quantity (Base)" /
                    ReqLine3."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                ReqLine3."Net Quantity (Base)" :=
                  (ReqLine3.Quantity -
                   ReqLine3."Original Quantity") *
                  ReqLine3."Qty. per Unit of Measure";
                ReqLine3.Modify();
                if PlanningComp."Location Code" = ReqLine3."Location Code" then begin
                    TrackingSpecification.InitTrackingSpecification(
                        DATABASE::"Requisition Line", 0,
                        ReqLine3."Worksheet Template Name", ReqLine3."Journal Batch Name", 0, ReqLine3."Line No.",
                        ReqLine3."Variant Code", ReqLine3."Location Code", ReqLine3."Qty. per Unit of Measure");
                    PlngComponentReserve.BindToTracking(
                        PlanningComp, TrackingSpecification, ReqLine3.Description, ReqLine3."Ending Date",
                        PlanningComp."Expected Quantity", PlanningComp."Expected Quantity (Base)");
                end;
                PlanningComp."Supplied-by Line No." := ReqLine3."Line No.";
                PlanningComp.Modify();
                ReqLine3.Validate("Production BOM No.");
                ReqLine3.Validate("Routing No.");
                ReqLine3.Modify();
                Calculate(ReqLine3, 1, CalcRouting, CalcComponents, PlanningLevel + 1);
                ReqLine3.Modify();
            until PlanningComp.Next() = 0;
    end;

    local procedure InsertPlanningLine(var ReqLine: Record "Requisition Line")
    var
        ReqLine2: Record "Requisition Line";
    begin
        ReqLine2 := ReqLine;
        ReqLine2.SetCurrentKey("Worksheet Template Name", "Journal Batch Name", Type, "No.");
        ReqLine2.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
        ReqLine2.SetRange("Journal Batch Name", ReqLine."Journal Batch Name");
        ReqLine2.SetRange(Type, ReqLine.Type::Item);
        ReqLine2.SetRange("No.", ReqLine."No.");
        ReqLine2.SetRange("Variant Code", ReqLine."Variant Code");
        ReqLine2.SetRange("Ref. Order Type", ReqLine."Ref. Order Type");
        ReqLine2.SetRange("Ref. Order Status", ReqLine."Ref. Order Status");
        ReqLine2.SetRange("Ref. Order No.", ReqLine."Ref. Order No.");
        ReqLine2.SetFilter("Planning Level", '>%1', 0);
        OnInsertPlanningLineOnAfterReqLine2SetFilters(ReqLine2, ReqLine);

        if ReqLine2.FindFirst() then begin
            ReqLine2.BlockDynamicTracking(Blocked);
            ReqLine2.Validate(Quantity, ReqLine2.Quantity + ReqLine.Quantity);

            if ReqLine2."Due Date" > ReqLine."Due Date" then
                ReqLine2."Due Date" := ReqLine."Due Date";

            if ReqLine2."Ending Date" > ReqLine."Ending Date" then begin
                ReqLine2."Ending Date" := ReqLine."Ending Date";
                ReqLine2."Ending Time" := ReqLine."Ending Time";
            end else
                if (ReqLine2."Ending Date" = ReqLine."Ending Date") and
                   (ReqLine2."Ending Time" > ReqLine."Ending Time")
                then
                    ReqLine2."Ending Time" := ReqLine."Ending Time";

            if ReqLine2."Planning Level" < ReqLine."Planning Level" then
                ReqLine2."Planning Level" := ReqLine."Planning Level";

            ReqLine2.Modify();
            ReqLine := ReqLine2;
        end else
            ReqLine.Insert();

        OnAfterInsertPlanningLine(ReqLine);
    end;

    procedure BlockDynamicTracking(SetBlock: Boolean)
    begin
        Blocked := SetBlock;
    end;

    procedure GetPlanningCompList(var PlanningCompList: Record "Planning Component" temporary)
    begin
        // The procedure returns a list of the Planning Components handled.
        if TempPlanningComponent.Find('-') then
            repeat
                PlanningCompList := TempPlanningComponent;
                if not PlanningCompList.Insert() then
                    PlanningCompList.Modify();
                TempPlanningComponent.Delete();
            until TempPlanningComponent.Next() = 0;
    end;

    local procedure IsPlannedComp(var PlanningComp: Record "Planning Component"; ReqLine: Record "Requisition Line"; ProdBOMLine: Record "Production BOM Line"): Boolean
    var
        PlanningComp2: Record "Planning Component";
    begin
        PlanningComp2 := PlanningComp;

        PlanningComp.SetCurrentKey("Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.", "Item No.");
        PlanningComp.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
        PlanningComp.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
        PlanningComp.SetRange("Worksheet Line No.", ReqLine."Line No.");
        PlanningComp.SetRange("Item No.", ProdBOMLine."No.");
        if PlanningComp.Find('-') then
            repeat
                if IsPlannedCompFound(PlanningComp, ProdBOMLine) then
                    exit(true);
            until PlanningComp.Next() = 0;

        PlanningComp := PlanningComp2;
        exit(false);
    end;

    local procedure IsPlannedCompFound(PlanningComp: Record "Planning Component"; ProdBOMLine: Record "Production BOM Line"): Boolean
    var
        IsFound: Boolean;
    begin
        IsFound :=
            (PlanningComp."Variant Code" = ProdBOMLine."Variant Code") and
            (PlanningComp."Routing Link Code" = ProdBOMLine."Routing Link Code") and
            (PlanningComp.Position = ProdBOMLine.Position) and
            (PlanningComp."Position 2" = ProdBOMLine."Position 2") and
            (PlanningComp."Position 3" = ProdBOMLine."Position 3") and
            (PlanningComp.Length = ProdBOMLine.Length) and
            (PlanningComp.Width = ProdBOMLine.Width) and
            (PlanningComp.Weight = ProdBOMLine.Weight) and
            (PlanningComp.Depth = ProdBOMLine.Depth) and
            (PlanningComp."Unit of Measure Code" = ProdBOMLine."Unit of Measure Code") and
            (PlanningComp."Calculation Formula" = ProdBOMLine."Calculation Formula");
        OnAfterIsPlannedCompFound(PlanningComp, ProdBOMLine, IsFound, SKU);
        exit(IsFound);
    end;

    local procedure IsPlannedAsmComp(var PlanningComp: Record "Planning Component"; ReqLine: Record "Requisition Line"; AsmBOMComp: Record "BOM Component"): Boolean
    var
        PlanningComp2: Record "Planning Component";
    begin
        PlanningComp2 := PlanningComp;

        PlanningComp.SetCurrentKey("Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.", "Item No.");
        PlanningComp.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
        PlanningComp.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
        PlanningComp.SetRange("Worksheet Line No.", ReqLine."Line No.");
        PlanningComp.SetRange("Item No.", AsmBOMComp."No.");
        if PlanningComp.Find('-') then
            repeat
                if IsPlannedAsmCompFound(PlanningComp, AsmBOMComp) then
                    exit(true);
            until PlanningComp.Next() = 0;

        PlanningComp := PlanningComp2;
        exit(false);
    end;

    local procedure IsPlannedAsmCompFound(PlanningComp: Record "Planning Component"; AsmBOMComp: Record "BOM Component"): Boolean
    var
        IsFound: Boolean;
    begin
        IsFound :=
            (PlanningComp."Variant Code" = AsmBOMComp."Variant Code") and
            (PlanningComp.Position = AsmBOMComp.Position) and
            (PlanningComp."Position 2" = AsmBOMComp."Position 2") and
            (PlanningComp."Position 3" = AsmBOMComp."Position 3") and
            (PlanningComp."Unit of Measure Code" = AsmBOMComp."Unit of Measure Code");
        OnAfterIsPlannedAsmCompFound(PlanningComp, AsmBOMComp, IsFound);
        exit(IsFound);
    end;

    procedure SetResiliencyOn(WkshTemplName: Code[10]; JnlBatchName: Code[10]; ItemNo: Code[20])
    begin
        PlanningResiliency := true;
        TempPlanningErrorLog.SetJnlBatch(WkshTemplName, JnlBatchName, ItemNo);
    end;

    procedure GetResiliencyError(var PlanningErrorLog: Record "Planning Error Log"): Boolean
    begin
        TempPlanningComponent.DeleteAll();
        if CalcPlanningRtngLine.GetResiliencyError(PlanningErrorLog) then
            exit(true);
        exit(TempPlanningErrorLog.GetError(PlanningErrorLog));
    end;

    local procedure IsInventoryItem(ItemNo: Code[20]): Boolean
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        exit(Item.IsInventoriableType());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertPlanningLine(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsPlannedCompFound(var PlanningComp: Record "Planning Component"; var ProdBOMLine: Record "Production BOM Line"; var IsFound: Boolean; var SKU: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsPlannedAsmCompFound(PlanningComp: Record "Planning Component"; AsmBOMComp: Record "BOM Component"; var IsFound: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferBOM(RequisitionLine: Record "Requisition Line"; ProdBOMNo: Code[20]; Level: Integer; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecalculateWithOptionalModify(var RequisitionLine: Record "Requisition Line"; Direction: Option Forward,Backward)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferRouting(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferRtngLine(var ReqLine: Record "Requisition Line"; var RoutingLine: Record "Routing Line"; var PlanningRoutingLine: Record "Planning Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMOnAfterProdBOMLineSetFilters(var ProdBOMLine: Record "Production BOM Line"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMOnBeforeGetDefaultBin(var PlanningComponent: Record "Planning Component"; var ProductionBOMLine: Record "Production BOM Line"; RequisitionLine: Record "Requisition Line"; var StockkeepingUnit: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferRoutingLineOnBeforeValidateDirectUnitCost(var ReqLine: Record "Requisition Line"; var RoutingLine: Record "Routing Line"; var PlanningRoutingLine: Record "Planning Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferRoutingLineOnBeforeCalcRoutingCostPerUnit(var PlanningRoutingLine: Record "Planning Routing Line"; ReqLine: Record "Requisition Line"; RoutingLine: Record "Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculate(var ReqLine2: Record "Requisition Line"; Direction: Option Forward,Backward; CalcRouting: Boolean; CalcComponents: Boolean; PlanningLevel: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPlanningComponent(var ReqLine: Record "Requisition Line"; var ProductionBOMLine: Record "Production BOM Line"; var PlanningComponent: Record "Planning Component"; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyPlanningComponent(var ReqLine: Record "Requisition Line"; var ProductionBOMLine: Record "Production BOM Line"; var PlanningComponent: Record "Planning Component"; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertAsmPlanningComponent(var ReqLine: Record "Requisition Line"; var BOMComponent: Record "BOM Component"; var PlanningComponent: Record "Planning Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecalculateWithOptionalModify(var RequisitionLine: Record "Requisition Line"; Direction: Option Forward,Backward)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferBOM(ProdBOMNo: Code[20]; Level: Integer; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal; var RequisitionLine: Record "Requisition Line"; Blocked: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferRouting(var RequisitionLine: Record "Requisition Line"; PlanningResilency: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateOnBeforeTransferBOM(var RequisitionLine: Record "Requisition Line"; var StockkeepingUnit: Record "Stockkeeping Unit"; PlanningResilency: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateRoutingOnAfterUpdateReqLine(var RequisitionLine: Record "Requisition Line"; Direction: Option Forward,Backward)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckMultiLevelStructureOnBeforeInsertPlanningLine(var ReqLine: Record "Requisition Line"; var PlanningComponent: Record "Planning Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckMultiLevelStructureOnAfterPlanningCompSetFilters(var PlanningComponent: Record "Planning Component"; RequisitionLine2: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckMultiLevelStructureOnAfterCalcThrowLineSpacingError(RequisitionLine: Record "Requisition Line"; var LineSpacing: array[50] of Integer; var PlanningLineNo: Integer; var ThrowLineSpacingError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMOnBeforeTransferPlanningComponent(var RequisitionLine: Record "Requisition Line"; var ProductionBOMLine: Record "Production BOM Line"; Blocked: Boolean; var IsHandled: Boolean; Level: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMOnBeforeTransferProductionBOM(var ReqQty: Decimal; ProductionBOMLine: Record "Production BOM Line"; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMOnBeforeUpdatePlanningComp(var ProductionBOMLine: Record "Production BOM Line"; var UpdateCondition: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMOnAfterCalculateReqQty(var ReqQty: Decimal; ProductionBOMLine: Record "Production BOM Line"; PlanningRoutingLine: Record "Planning Routing Line"; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferAsmBOMOnBeforeGetDefaultBin(var PlanningComponent: Record "Planning Component"; var AsmBOMComponent: Record "BOM Component"; ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckMultiLevelStructureOnBeforeValidateQuantity(var RequisitionLine: Record "Requisition Line"; var PlanningComponent: Record "Planning Component");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPlanningLineOnAfterReqLine2SetFilters(var ReqLine2: Record "Requisition Line"; var ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckMultiLevelStructureOnAfterCalcShouldExitManufacturingPolicy(var RequisitionLine: Record "Requisition Line"; var ShouldExit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculate(var CalcComponents: Boolean; var SKU: Record "Stockkeeping Unit"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPlanningLevelCode(var PlanningComponent: Record "Planning Component"; var ProdBOMLine: Record "Production BOM Line"; var SKU: Record "Stockkeeping Unit"; var ComponentSKU: Record "Stockkeeping Unit"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferRoutingLine(var PlanningRoutingLine: Record "Planning Routing Line"; RequisitionLine: Record "Requisition Line"; RoutingLine: Record "Routing Line"; var IsHandled: Boolean)
    begin
    end;
}

