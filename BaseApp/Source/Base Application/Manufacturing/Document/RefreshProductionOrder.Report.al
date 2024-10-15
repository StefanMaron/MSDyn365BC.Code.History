namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Family;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;

report 99001025 "Refresh Production Order"
{
    Caption = 'Refresh Production Order';
    ProcessingOnly = true;
    TransactionType = Update;

    dataset
    {
        dataitem("Production Order"; "Production Order")
        {
            DataItemTableView = sorting(Status, "No.");
            RequestFilterFields = Status, "No.";

            trigger OnAfterGetRecord()
            var
                ProdOrderLine: Record "Prod. Order Line";
                ProdOrderRtngLine: Record "Prod. Order Routing Line";
                ProdOrderComp: Record "Prod. Order Component";
                ProdOrder: Record "Production Order";
                ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
                RoutingNo: Code[20];
                ErrorOccured: Boolean;
                IsHandled: Boolean;
            begin
                if Status = Status::Finished then
                    CurrReport.Skip();

                TestField("Due Date");

                if CalcLines and IsComponentPicked("Production Order") then
                    if not Confirm(StrSubstNo(DeletePickedLinesQst, "No.")) then
                        CurrReport.Skip();

                Window.Update(1, Status);
                Window.Update(2, "No.");

                RoutingNo := GetRoutingNo("Production Order");
                UpdateRoutingNo("Production Order", RoutingNo);

                ProdOrderLine.LockTable();
                OnBeforeCalcProdOrder("Production Order", Direction);
                CheckReservationExist();

                if CalcLines then begin
                    OnBeforeCalcProdOrderLines("Production Order", Direction, CalcLines, CalcRoutings, CalcComponents, IsHandled, ErrorOccured);
                    if not IsHandled then
                        if not CreateProdOrderLines.Copy("Production Order", Direction, "Production Order"."Variant Code", false) then
                            ErrorOccured := true;
                end else begin
                    ProdOrderLine.SetRange(Status, Status);
                    ProdOrderLine.SetRange("Prod. Order No.", "No.");
                    IsHandled := false;
                    OnBeforeCalcRoutingsOrComponents("Production Order", ProdOrderLine, CalcComponents, CalcRoutings, IsHandled);
                    if not IsHandled then
                        if CalcRoutings or CalcComponents then begin
                            if ProdOrderLine.Find('-') then
                                repeat
                                    if CalcRoutings then begin
                                        ProdOrderRtngLine.SetRange(Status, Status);
                                        ProdOrderRtngLine.SetRange("Prod. Order No.", "No.");
                                        ProdOrderRtngLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
                                        ProdOrderRtngLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
                                        if ProdOrderRtngLine.FindSet(true) then
                                            repeat
                                                ProdOrderRtngLine.SetSkipUpdateOfCompBinCodes(true);
                                                ProdOrderRtngLine.Delete(true);
                                            until ProdOrderRtngLine.Next() = 0;
                                    end;
                                    if CalcComponents then begin
                                        ProdOrderComp.SetRange(Status, Status);
                                        ProdOrderComp.SetRange("Prod. Order No.", "No.");
                                        ProdOrderComp.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
                                        ProdOrderComp.DeleteAll(true);
                                    end;
                                until ProdOrderLine.Next() = 0;
                            if ProdOrderLine.Find('-') then
                                repeat
                                    if CalcComponents then
                                        CheckProductionBOMStatus(ProdOrderLine."Production BOM No.", ProdOrderLine."Production BOM Version Code");
                                    if CalcRoutings then
                                        CheckRoutingStatus(ProdOrderLine."Routing No.", ProdOrderLine."Routing Version Code");
                                    ProdOrderLine."Due Date" := "Due Date";
                                    IsHandled := false;
                                    OnBeforeCalcProdOrderLine(ProdOrderLine, Direction, CalcLines, CalcRoutings, CalcComponents, IsHandled, ErrorOccured);
                                    if not IsHandled then
                                        if not CalcProdOrder.Calculate(ProdOrderLine, Direction, CalcRoutings, CalcComponents, false, false) then
                                            ErrorOccured := true;
                                until ProdOrderLine.Next() = 0;
                        end;
                end;
                OnProductionOrderOnAfterGetRecordOnAfterCalcRoutingsOrComponents("Production Order", CalcLines, CalcRoutings, CalcComponents, ErrorOccured);

                if (Direction = Direction::Backward) and ("Source Type" = "Source Type"::Family) then begin
                    SetUpdateEndDate();
                    Validate("Due Date", "Due Date");
                end;

                if Status = Status::Released then begin
                    ProdOrderStatusMgt.FlushProdOrder("Production Order", Status, WorkDate());
                    WhseProdRelease.Release("Production Order");
                    if CreateInbRqst then
                        WhseOutputProdRelease.Release("Production Order");
                end;

                OnAfterRefreshProdOrder("Production Order", ErrorOccured);
                if ErrorOccured then
                    Message(Text005, ProdOrder.TableCaption(), ProdOrderLine.FieldCaption("Bin Code"));
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(
                  Text000 +
                  Text001 +
                  Text002);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(Direction; Direction)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Scheduling direction';
                        OptionCaption = 'Forward,Back';
                        ToolTip = 'Specifies whether you want the scheduling to be refreshed forward or backward.';
                    }
                    group(Calculate)
                    {
                        Caption = 'Calculate';
                        field(CalcLines; CalcLines)
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Lines';
                            ToolTip = 'Specifies if you want the program to calculate the production order lines.';

                            trigger OnValidate()
                            begin
                                if CalcLines then begin
                                    CalcRoutings := true;
                                    CalcComponents := true;
                                end;
                            end;
                        }
                        field(CalcRoutings; CalcRoutings)
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Routings';
                            ToolTip = 'Specifies if you want the program to calculate the routing.';

                            trigger OnValidate()
                            begin
                                if not CalcRoutings then
                                    if CalcLines then
                                        Error(Text003);
                            end;
                        }
                        field(CalcComponents; CalcComponents)
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Component Need';
                            ToolTip = 'Specifies if you want the program to calculate the component requirement.';

                            trigger OnValidate()
                            begin
                                if not CalcComponents then
                                    if CalcLines then
                                        Error(Text004);
                            end;
                        }
                    }
                    group(Warehouse)
                    {
                        Caption = 'Warehouse';
                        field(CreateInbRqst; CreateInbRqst)
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Create Inbound Request';
                            ToolTip = 'Specifies if you want to create an inbound request when calculating and updating a production order.';
                        }
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            CalcLines := true;
            CalcRoutings := true;
            CalcComponents := true;

            OnAfterOnInit(Direction, CalcLines, CalcRoutings, CalcComponents, CreateInbRqst);
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        Direction := Direction::Backward;
        OnAfterInitReport();
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Refreshing Production Orders...\\';
#pragma warning disable AA0470
        Text001: Label 'Status         #1##########\';
        Text002: Label 'No.            #2##########';
#pragma warning restore AA0470
        Text003: Label 'Routings must be calculated, when lines are calculated.';
        Text004: Label 'Component Need must be calculated, when lines are calculated.';
#pragma warning restore AA0074
        CalcProdOrder: Codeunit "Calculate Prod. Order";
        CreateProdOrderLines: Codeunit "Create Prod. Order Lines";
        WhseProdRelease: Codeunit "Whse.-Production Release";
        WhseOutputProdRelease: Codeunit "Whse.-Output Prod. Release";
        Window: Dialog;
        Direction: Option Forward,Backward;
        CalcLines: Boolean;
        CalcRoutings: Boolean;
        CalcComponents: Boolean;
        CreateInbRqst: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text005: Label 'One or more of the lines on this %1 require special warehouse handling. The %2 for these lines has been set to blank.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0470
        DeletePickedLinesQst: Label 'Components for production order %1 have already been picked. Do you want to continue?', Comment = 'Production order no.: Components for production order 101001 have already been picked. Do you want to continue?';
#pragma warning restore AA0470

    local procedure CheckReservationExist()
    var
        ProdOrderLine2: Record "Prod. Order Line";
        ProdOrderComp2: Record "Prod. Order Component";
    begin
        // Not allowed to refresh if reservations exist
        if not (CalcLines or CalcComponents) then
            exit;

        ProdOrderLine2.SetRange(Status, "Production Order".Status);
        ProdOrderLine2.SetRange("Prod. Order No.", "Production Order"."No.");
        if ProdOrderLine2.Find('-') then
            repeat
                if CalcLines then begin
                    ProdOrderLine2.CalcFields("Reserved Qty. (Base)");
                    if ProdOrderLine2."Reserved Qty. (Base)" <> 0 then
                        if ShouldCheckReservedQty(
                             ProdOrderLine2."Prod. Order No.", 0, Database::"Prod. Order Line",
                             ProdOrderLine2.Status, ProdOrderLine2."Line No.", Database::"Prod. Order Component")
                        then
                            ProdOrderLine2.TestField("Reserved Qty. (Base)", 0);
                end;

                if CalcComponents then begin
                    ProdOrderComp2.SetRange(Status, ProdOrderLine2.Status);
                    ProdOrderComp2.SetRange("Prod. Order No.", ProdOrderLine2."Prod. Order No.");
                    ProdOrderComp2.SetRange("Prod. Order Line No.", ProdOrderLine2."Line No.");
                    ProdOrderComp2.SetAutoCalcFields("Reserved Qty. (Base)");
                    if ProdOrderComp2.Find('-') then
                        repeat
                            OnCheckReservationExistOnBeforeCheckProdOrderComp2ReservedQtyBase(ProdOrderComp2);
                            if ProdOrderComp2."Reserved Qty. (Base)" <> 0 then
                                if ShouldCheckReservedQty(
                                     ProdOrderComp2."Prod. Order No.", ProdOrderComp2."Line No.",
                                     Database::"Prod. Order Component", ProdOrderComp2.Status,
                                     ProdOrderComp2."Prod. Order Line No.", Database::"Prod. Order Line")
                                then
                                    ProdOrderComp2.TestField("Reserved Qty. (Base)", 0);
                        until ProdOrderComp2.Next() = 0;
                end;
            until ProdOrderLine2.Next() = 0;
    end;

    local procedure ShouldCheckReservedQty(ProdOrderNo: Code[20]; LineNo: Integer; SourceType: Integer; Status: Enum "Production Order Status"; ProdOrderLineNo: Integer; SourceType2: Integer): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.SetSourceFilter(SourceType, Status.AsInteger(), ProdOrderNo, LineNo, true);
        ReservEntry.SetSourceFilter('', ProdOrderLineNo);
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
        if ReservEntry.FindFirst() then begin
            ReservEntry.Get(ReservEntry."Entry No.", not ReservEntry.Positive);
            exit(
              not ((ReservEntry."Source Type" = SourceType2) and
                   (ReservEntry."Source ID" = ProdOrderNo) and (ReservEntry."Source Subtype" = Status.AsInteger())));
        end;

        exit(false);
    end;

    local procedure UpdateRoutingNo(var ProductionOrder: Record "Production Order"; RoutingNo: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateRoutingNo("Production Order", RoutingNo, IsHandled, CalcLines, CalcComponents, CalcRoutings);
        if IsHandled then
            exit;

        if RoutingNo <> ProductionOrder."Routing No." then begin
            ProductionOrder."Routing No." := RoutingNo;
            ProductionOrder.Modify();
        end;
    end;

    local procedure CheckProductionBOMStatus(ProdBOMNo: Code[20]; ProdBOMVersionNo: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        if ProdBOMNo = '' then
            exit;

        if ProdBOMVersionNo = '' then begin
            ProductionBOMHeader.Get(ProdBOMNo);
            ProductionBOMHeader.TestField(Status, ProductionBOMHeader.Status::Certified);
        end else begin
            ProductionBOMVersion.Get(ProdBOMNo, ProdBOMVersionNo);
            ProductionBOMVersion.TestField(Status, ProductionBOMVersion.Status::Certified);
        end;
    end;

    local procedure CheckRoutingStatus(RoutingNo: Code[20]; RoutingVersionNo: Code[20])
    var
        RoutingHeader: Record "Routing Header";
        RoutingVersion: Record "Routing Version";
    begin
        if RoutingNo = '' then
            exit;

        if RoutingVersionNo = '' then begin
            RoutingHeader.Get(RoutingNo);
            RoutingHeader.TestField(Status, RoutingHeader.Status::Certified);
        end else begin
            RoutingVersion.Get(RoutingNo, RoutingVersionNo);
            RoutingVersion.TestField(Status, RoutingVersion.Status::Certified);
        end;
    end;

    procedure InitializeRequest(Direction2: Option Forward,Backward; CalcLines2: Boolean; CalcRoutings2: Boolean; CalcComponents2: Boolean; CreateInbRqst2: Boolean)
    begin
        Direction := Direction2;
        CalcLines := CalcLines2;
        CalcRoutings := CalcRoutings2;
        CalcComponents := CalcComponents2;
        CreateInbRqst := CreateInbRqst2;
    end;

    local procedure IsComponentPicked(ProdOrder: Record "Production Order"): Boolean
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        ProdOrderComp.SetRange(Status, ProdOrder.Status);
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.SetFilter("Qty. Picked", '<>0');
        exit(not ProdOrderComp.IsEmpty);
    end;

    local procedure GetRoutingNo(ProdOrder: Record "Production Order") RoutingNo: Code[20]
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        Family: Record Family;
    begin
        RoutingNo := ProdOrder."Routing No.";
        case ProdOrder."Source Type" of
            ProdOrder."Source Type"::Item:
                begin
                    if Item.Get(ProdOrder."Source No.") then
                        RoutingNo := Item."Routing No.";
                    if StockkeepingUnit.Get(ProdOrder."Location Code", ProdOrder."Source No.", ProdOrder."Variant Code") and
                        (StockkeepingUnit."Routing No." <> '')
                    then
                        RoutingNo := StockkeepingUnit."Routing No.";
                end;
            ProdOrder."Source Type"::Family:
                if Family.Get(ProdOrder."Source No.") then
                    RoutingNo := Family."Routing No.";
        end;

        OnAfterGetRoutingNo(ProdOrder, RoutingNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRoutingNo(var ProductionOrder: Record "Production Order"; var RoutingNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRefreshProdOrder(var ProductionOrder: Record "Production Order"; ErrorOccured: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnInit(var Direction: Option; var CalcLines: Boolean; var CalcRoutings: Boolean; var CalcComponents: Boolean; var CreateInbRqst: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcProdOrder(var ProductionOrder: Record "Production Order"; Direction: Option Forward,Backward)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; var Direction: Option Forward,Backward; CalcLines: Boolean; CalcRoutings: Boolean; CalcComponents: Boolean; var IsHandled: Boolean; var ErrorOccured: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcProdOrderLines(var ProductionOrder: Record "Production Order"; Direction: Option Forward,Backward; CalcLines: Boolean; CalcRoutings: Boolean; CalcComponents: Boolean; var IsHandled: Boolean; var ErrorOccured: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcRoutingsOrComponents(var ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; var CalcComponents: Boolean; var CalcRoutings: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateRoutingNo(var ProductionOrder: Record "Production Order"; RoutingNo: Code[20]; var IsHandled: Boolean; var CalcLines: Boolean; var CalcComponents: Boolean; var CalcRoutings: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckReservationExistOnBeforeCheckProdOrderComp2ReservedQtyBase(var ProdOrderComp2: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInitReport()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProductionOrderOnAfterGetRecordOnAfterCalcRoutingsOrComponents(var ProductionOrder: Record "Production Order"; CalcLines: Boolean; CalcRoutings: Boolean; CalcComponents: Boolean; var ErrorOccured: Boolean)
    begin
    end;
}

