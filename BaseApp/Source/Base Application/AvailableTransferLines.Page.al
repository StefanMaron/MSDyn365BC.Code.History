page 99000896 "Available - Transfer Lines"
{
    Caption = 'Available - Transfer Lines';
    DataCaptionExpression = CaptionText;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Transfer Line";
    SourceTableView = SORTING("Document No.", "Line No.");

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Transfer-from Code"; "Transfer-from Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location that items are transferred from.';
                }
                field("Transfer-to Code"; "Transfer-to Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location that the items are transferred to.';
                }
                field("Shipment Date"; "Shipment Date")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                }
                field("Receipt Date"; "Receipt Date")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the date that you expect the transfer-to location to receive the items on this line.';
                }
                field("Quantity (Base)"; "Quantity (Base)")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the quantity on the line expressed in base units of measure.';
                }
                field("Reserved Qty. Inbnd. (Base)"; "Reserved Qty. Inbnd. (Base)")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies the quantity of the item reserved at the transfer-to location, expressed in base units of measure.';
                }
                field("Reserved Qty. Outbnd. (Base)"; "Reserved Qty. Outbnd. (Base)")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies the quantity of the item reserved at the transfer-from location, expressed in the base unit of measure.';
                }
                field(QtyToReserveBase; QtyToReserveBase)
                {
                    ApplicationArea = Location;
                    Caption = 'Available Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of the item that is available.';
                }
                field(ReservedQuantity; GetReservedQtyInLine)
                {
                    ApplicationArea = Reservation;
                    Caption = 'Current Reserved Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item that is reserved for the document type.';

                    trigger OnDrillDown()
                    begin
                        ReservEntry2.Reset;
                        ReserveTransLine.FilterReservFor(ReservEntry2, Rec, Direction);
                        ReservEntry2.SetRange("Reservation Status", ReservEntry2."Reservation Status"::Reservation);
                        ReservMgt.MarkReservConnection(ReservEntry2, ReservEntry);
                        PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry2);
                        UpdateReservFrom;
                        CurrPage.Update;
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Reserve)
                {
                    ApplicationArea = Reservation;
                    Caption = '&Reserve';
                    Image = Reserve;
                    ToolTip = 'Reserve the quantity that is required on the document line that you opened this window for.';

                    trigger OnAction()
                    begin
                        ReservEntry.LockTable;
                        UpdateReservMgt;
                        ReservMgt.TransferLineUpdateValues(Rec, QtyToReserve, QtyToReserveBase, QtyReservedThisLine, QtyReservedThisLineBase, Direction);
                        ReservMgt.CalculateRemainingQty(NewQtyReservedThisLine, NewQtyReservedThisLineBase);
                        ReservMgt.CopySign(NewQtyReservedThisLine, QtyToReserve);
                        ReservMgt.CopySign(NewQtyReservedThisLineBase, QtyToReserveBase);
                        if NewQtyReservedThisLineBase <> 0 then
                            if NewQtyReservedThisLineBase > QtyToReserveBase then
                                CreateReservation(QtyToReserve, QtyToReserveBase)
                            else
                                CreateReservation(NewQtyReservedThisLine, NewQtyReservedThisLineBase)
                        else
                            Error(Text001);
                    end;
                }
                action(CancelReservation)
                {
                    AccessByPermission = TableData Item = R;
                    ApplicationArea = Reservation;
                    Caption = '&Cancel Reservation';
                    Image = Cancel;
                    ToolTip = 'Cancel the reservation that exists for the document line that you opened this window for.';

                    trigger OnAction()
                    begin
                        if not Confirm(Text002, false) then
                            exit;

                        ReservEntry2.Copy(ReservEntry);
                        ReserveTransLine.FilterReservFor(ReservEntry2, Rec, Direction);

                        if ReservEntry2.Find('-') then begin
                            UpdateReservMgt;
                            repeat
                                ReservEngineMgt.CancelReservation(ReservEntry2);
                            until ReservEntry2.Next = 0;

                            UpdateReservFrom;
                        end;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ReservMgt.TransferLineUpdateValues(Rec, QtyToReserve, QtyToReserveBase, QtyReservedThisLine, QtyReservedThisLineBase, Direction);
    end;

    trigger OnOpenPage()
    begin
        ReservEntry.TestField("Source Type");
        if not DirectionIsSet then
            Error(Text000);

        SetFilters;
    end;

    var
        Text000: Label 'Direction has not been set.';
        Text001: Label 'Fully reserved.';
        Text002: Label 'Do you want to cancel the reservation?';
        Text003: Label 'Available Quantity is %1.';
        AssemblyLine: Record "Assembly Line";
        AssemblyHeader: Record "Assembly Header";
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        SalesLine: Record "Sales Line";
        PurchLine: Record "Purchase Line";
        ReqLine: Record "Requisition Line";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        PlanningComponent: Record "Planning Component";
        TransLine: Record "Transfer Line";
        ServiceInvLine: Record "Service Line";
        JobPlanningLine: Record "Job Planning Line";
        ReservMgt: Codeunit "Reservation Management";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReserveSalesLine: Codeunit "Sales Line-Reserve";
        ReserveReqLine: Codeunit "Req. Line-Reserve";
        ReservePurchLine: Codeunit "Purch. Line-Reserve";
        ReserveProdOrderLine: Codeunit "Prod. Order Line-Reserve";
        ReserveProdOrderComp: Codeunit "Prod. Order Comp.-Reserve";
        ReservePlanningComponent: Codeunit "Plng. Component-Reserve";
        ReserveTransLine: Codeunit "Transfer Line-Reserve";
        ReserveServiceInvLine: Codeunit "Service Line-Reserve";
        JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
        AssemblyHeaderReserve: Codeunit "Assembly Header-Reserve";
        QtyToReserve: Decimal;
        QtyToReserveBase: Decimal;
        QtyReservedThisLine: Decimal;
        QtyReservedThisLineBase: Decimal;
        NewQtyReservedThisLine: Decimal;
        NewQtyReservedThisLineBase: Decimal;
        CaptionText: Text;
        Direction: Option Outbound,Inbound;
        DirectionIsSet: Boolean;

    procedure SetSalesLine(var CurrentSalesLine: Record "Sales Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        CurrentSalesLine.TestField(Type, CurrentSalesLine.Type::Item);
        SalesLine := CurrentSalesLine;
        ReservEntry := CurrentReservEntry;

        Clear(ReservMgt);
        ReservMgt.SetSalesLine(SalesLine);
        ReservEngineMgt.InitFilterAndSortingFor(ReservEntry, true);
        ReserveSalesLine.FilterReservFor(ReservEntry, SalesLine);
        CaptionText := ReserveSalesLine.Caption(SalesLine);
        SetInbound(ReservMgt.IsPositive);
    end;

    procedure SetReqLine(var CurrentReqLine: Record "Requisition Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        ReqLine := CurrentReqLine;
        ReservEntry := CurrentReservEntry;

        Clear(ReservMgt);
        ReservMgt.SetReqLine(ReqLine);
        ReservEngineMgt.InitFilterAndSortingFor(ReservEntry, true);
        ReserveReqLine.FilterReservFor(ReservEntry, ReqLine);
        CaptionText := ReserveReqLine.Caption(ReqLine);
        SetInbound(ReservMgt.IsPositive);
    end;

    procedure SetPurchLine(var CurrentPurchLine: Record "Purchase Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        CurrentPurchLine.TestField(Type, CurrentPurchLine.Type::Item);
        PurchLine := CurrentPurchLine;
        ReservEntry := CurrentReservEntry;

        Clear(ReservMgt);
        ReservMgt.SetPurchLine(PurchLine);
        ReservEngineMgt.InitFilterAndSortingFor(ReservEntry, true);
        ReservePurchLine.FilterReservFor(ReservEntry, PurchLine);
        CaptionText := ReservePurchLine.Caption(PurchLine);
        SetInbound(ReservMgt.IsPositive);
    end;

    procedure SetProdOrderLine(var CurrentProdOrderLine: Record "Prod. Order Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        ProdOrderLine := CurrentProdOrderLine;
        ReservEntry := CurrentReservEntry;

        Clear(ReservMgt);
        ReservMgt.SetProdOrderLine(ProdOrderLine);
        ReservEngineMgt.InitFilterAndSortingFor(ReservEntry, true);
        ReserveProdOrderLine.FilterReservFor(ReservEntry, ProdOrderLine);
        CaptionText := ReserveProdOrderLine.Caption(ProdOrderLine);
        SetInbound(ReservMgt.IsPositive);
    end;

    procedure SetProdOrderComponent(var CurrentProdOrderComp: Record "Prod. Order Component"; CurrentReservEntry: Record "Reservation Entry")
    begin
        ProdOrderComp := CurrentProdOrderComp;
        ReservEntry := CurrentReservEntry;

        Clear(ReservMgt);
        ReservMgt.SetProdOrderComponent(ProdOrderComp);
        ReservEngineMgt.InitFilterAndSortingFor(ReservEntry, true);
        ReserveProdOrderComp.FilterReservFor(ReservEntry, ProdOrderComp);
        CaptionText := ReserveProdOrderComp.Caption(ProdOrderComp);
        SetInbound(ReservMgt.IsPositive);
    end;

    procedure SetPlanningComponent(var CurrentPlanningComponent: Record "Planning Component"; CurrentReservEntry: Record "Reservation Entry")
    begin
        PlanningComponent := CurrentPlanningComponent;
        ReservEntry := CurrentReservEntry;

        Clear(ReservMgt);
        ReservMgt.SetPlanningComponent(PlanningComponent);
        ReservEngineMgt.InitFilterAndSortingFor(ReservEntry, true);
        ReservePlanningComponent.FilterReservFor(ReservEntry, PlanningComponent);
        CaptionText := ReservePlanningComponent.Caption(PlanningComponent);
        SetInbound(ReservMgt.IsPositive);
    end;

    procedure SetTransferLine(var CurrentTransLine: Record "Transfer Line"; CurrentReservEntry: Record "Reservation Entry"; Direction: Option Outbound,Inbound)
    begin
        TransLine := CurrentTransLine;
        ReservEntry := CurrentReservEntry;

        Clear(ReservMgt);
        ReservMgt.SetTransferLine(TransLine, Direction);
        ReservEngineMgt.InitFilterAndSortingFor(ReservEntry, true);
        ReserveTransLine.FilterReservFor(ReservEntry, TransLine, Direction);
        CaptionText := ReserveTransLine.Caption(TransLine);
        SetInbound(ReservMgt.IsPositive);
    end;

    procedure SetServiceInvLine(var CurrentServiceInvLine: Record "Service Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        CurrentServiceInvLine.TestField(Type, CurrentServiceInvLine.Type::Item);
        ServiceInvLine := CurrentServiceInvLine;
        ReservEntry := CurrentReservEntry;

        Clear(ReservMgt);
        ReservMgt.SetServLine(ServiceInvLine);
        ReservEngineMgt.InitFilterAndSortingFor(ReservEntry, true);
        ReserveServiceInvLine.FilterReservFor(ReservEntry, ServiceInvLine);
        CaptionText := ReserveServiceInvLine.Caption(ServiceInvLine);
        SetInbound(ReservMgt.IsPositive);
    end;

    procedure SetJobPlanningLine(var CurrentJobPlanningLine: Record "Job Planning Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        CurrentJobPlanningLine.TestField(Type, CurrentJobPlanningLine.Type::Item);
        JobPlanningLine := CurrentJobPlanningLine;
        ReservEntry := CurrentReservEntry;

        Clear(ReservMgt);
        ReservMgt.SetJobPlanningLine(JobPlanningLine);
        ReservEngineMgt.InitFilterAndSortingFor(ReservEntry, true);
        JobPlanningLineReserve.FilterReservFor(ReservEntry, JobPlanningLine);
        CaptionText := JobPlanningLineReserve.Caption(JobPlanningLine);
        SetInbound(ReservMgt.IsPositive);
    end;

    local procedure CreateReservation(ReserveQuantity: Decimal; ReserveQuantityBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        QtyThisLine: Decimal;
        ReservQty: Decimal;
        LocationCode: Code[10];
        EntryDate: Date;
    begin
        case Direction of
            Direction::Outbound:
                begin
                    CalcFields("Reserved Qty. Outbnd. (Base)");
                    QtyThisLine := "Outstanding Qty. (Base)";
                    ReservQty := "Reserved Qty. Outbnd. (Base)";
                    EntryDate := "Shipment Date";
                    TestField("Transfer-from Code", ReservEntry."Location Code");
                    LocationCode := "Transfer-from Code";
                end;
            Direction::Inbound:
                begin
                    CalcFields("Reserved Qty. Inbnd. (Base)");
                    QtyThisLine := "Outstanding Qty. (Base)";
                    ReservQty := "Reserved Qty. Inbnd. (Base)";
                    EntryDate := "Receipt Date";
                    TestField("Transfer-to Code", ReservEntry."Location Code");
                    LocationCode := "Transfer-to Code";
                end;
        end;

        if QtyThisLine - ReservQty < ReserveQuantityBase then
            Error(Text003, QtyThisLine + ReservQty);

        TestField("Item No.", ReservEntry."Item No.");
        TestField("Variant Code", ReservEntry."Variant Code");

        UpdateReservMgt;
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Transfer Line", Direction, "Document No.", '', "Derived From Line No.", "Line No.",
          "Variant Code", LocationCode, "Qty. per Unit of Measure");
        ReservMgt.CreateReservation(
          ReservEntry.Description, EntryDate, ReserveQuantity, ReserveQuantityBase, TrackingSpecification);
        UpdateReservFrom;
    end;

    local procedure UpdateReservFrom()
    begin
        case ReservEntry."Source Type" of
            DATABASE::"Sales Line":
                begin
                    SalesLine.Find;
                    SetSalesLine(SalesLine, ReservEntry);
                end;
            DATABASE::"Requisition Line":
                begin
                    ReqLine.Find;
                    SetReqLine(ReqLine, ReservEntry);
                end;
            DATABASE::"Purchase Line":
                begin
                    PurchLine.Find;
                    SetPurchLine(PurchLine, ReservEntry);
                end;
            DATABASE::"Prod. Order Line":
                begin
                    ProdOrderLine.Find;
                    SetProdOrderLine(ProdOrderLine, ReservEntry);
                end;
            DATABASE::"Prod. Order Component":
                begin
                    ProdOrderComp.Find;
                    SetProdOrderComponent(ProdOrderComp, ReservEntry);
                end;
            DATABASE::"Transfer Line":
                begin
                    TransLine.Find;
                    SetTransferLine(TransLine, ReservEntry, ReservEntry."Source Subtype");
                end;
            DATABASE::"Planning Component":
                begin
                    PlanningComponent.Find;
                    SetPlanningComponent(PlanningComponent, ReservEntry);
                end;
            DATABASE::"Job Planning Line":
                begin
                    JobPlanningLine.Find;
                    SetJobPlanningLine(JobPlanningLine, ReservEntry);
                end;
        end;

        OnAfterUpdateReservFrom(ReservEntry);
    end;

    local procedure UpdateReservMgt()
    begin
        Clear(ReservMgt);
        case ReservEntry."Source Type" of
            DATABASE::"Sales Line":
                ReservMgt.SetSalesLine(SalesLine);
            DATABASE::"Requisition Line":
                ReservMgt.SetReqLine(ReqLine);
            DATABASE::"Purchase Line":
                ReservMgt.SetPurchLine(PurchLine);
            DATABASE::"Prod. Order Line":
                ReservMgt.SetProdOrderLine(ProdOrderLine);
            DATABASE::"Prod. Order Component":
                ReservMgt.SetProdOrderComponent(ProdOrderComp);
            DATABASE::"Assembly Header":
                ReservMgt.SetAssemblyHeader(AssemblyHeader);
            DATABASE::"Assembly Line":
                ReservMgt.SetAssemblyLine(AssemblyLine);
            DATABASE::"Transfer Line":
                ReservMgt.SetTransferLine(TransLine, ReservEntry."Source Subtype");
            DATABASE::"Planning Component":
                ReservMgt.SetPlanningComponent(PlanningComponent);
            DATABASE::"Service Line":
                ReservMgt.SetServLine(ServiceInvLine);
            DATABASE::"Job Planning Line":
                ReservMgt.SetJobPlanningLine(JobPlanningLine);
        end;

        OnAfterUpdateReservMgt(ReservEntry);
    end;

    local procedure GetReservedQtyInLine(): Decimal
    begin
        ReservEntry2.Reset;
        ReserveTransLine.FilterReservFor(ReservEntry2, Rec, Direction);
        ReservEntry2.SetRange("Reservation Status", ReservEntry2."Reservation Status"::Reservation);
        exit(ReservMgt.MarkReservConnection(ReservEntry2, ReservEntry));
    end;

    procedure SetInbound(DirectionIsInbound: Boolean)
    begin
        if DirectionIsInbound then
            Direction := Direction::Inbound
        else
            Direction := Direction::Outbound;
        DirectionIsSet := true;
    end;

    procedure SetAssemblyLine(var CurrentAsmLine: Record "Assembly Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        CurrentAsmLine.TestField(Type, CurrentAsmLine.Type::Item);
        AssemblyLine := CurrentAsmLine;
        ReservEntry := CurrentReservEntry;

        Clear(ReservMgt);
        ReservMgt.SetAssemblyLine(AssemblyLine);
        ReservEngineMgt.InitFilterAndSortingFor(ReservEntry, true);
        AssemblyLineReserve.FilterReservFor(ReservEntry, AssemblyLine);
        CaptionText := AssemblyLineReserve.Caption(AssemblyLine);
        SetInbound(ReservMgt.IsPositive);
    end;

    procedure SetAssemblyHeader(var CurrentAsmHeader: Record "Assembly Header"; CurrentReservEntry: Record "Reservation Entry")
    begin
        AssemblyHeader := CurrentAsmHeader;
        ReservEntry := CurrentReservEntry;

        Clear(ReservMgt);
        ReservMgt.SetAssemblyHeader(AssemblyHeader);
        ReservEngineMgt.InitFilterAndSortingFor(ReservEntry, true);
        AssemblyHeaderReserve.FilterReservFor(ReservEntry, AssemblyHeader);
        CaptionText := AssemblyHeaderReserve.Caption(AssemblyHeader);
        SetInbound(ReservMgt.IsPositive);
    end;

    local procedure SetFilters()
    begin
        case Direction of
            Direction::Outbound:
                begin
                    SetFilter("Shipment Date", ReservMgt.GetAvailabilityFilter(ReservEntry."Shipment Date"));
                    SetRange("Transfer-from Code", ReservEntry."Location Code");
                end;
            Direction::Inbound:
                begin
                    SetFilter("Receipt Date", ReservMgt.GetAvailabilityFilter(ReservEntry."Shipment Date"));
                    SetRange("Transfer-to Code", ReservEntry."Location Code");
                end;
        end;

        SetRange("Item No.", ReservEntry."Item No.");
        SetRange("Variant Code", ReservEntry."Variant Code");
        SetFilter("Outstanding Qty. (Base)", '>0');

        OnAfterSetFilters(Rec, ReservEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilters(var TransferLine: Record "Transfer Line"; ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterUpdateReservFrom(var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterUpdateReservMgt(var ReservationEntry: Record "Reservation Entry")
    begin
    end;
}

