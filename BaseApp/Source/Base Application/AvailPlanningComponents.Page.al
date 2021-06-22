page 99000900 "Avail. - Planning Components"
{
    Caption = 'Avail. - Planning Components';
    DataCaptionExpression = CaptionText;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Planning Component";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code for the inventory location, where the item on the planning component line will be registered.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the date when this planning component must be finished.';
                }
                field("Quantity (Base)"; "Quantity (Base)")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the value in the Quantity field on the line.';
                }
                field("Reserved Qty. (Base)"; "Reserved Qty. (Base)")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies the reserved quantity of the item, in base units of measure.';
                }
                field(QtyToReserveBase; QtyToReserveBase)
                {
                    ApplicationArea = Planning;
                    Caption = 'Available Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of the components that is available for reservation.';
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
                        ReservePlanningComponent.FilterReservFor(ReservEntry2, Rec);
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
                action("&Reserve")
                {
                    ApplicationArea = Reservation;
                    Caption = '&Reserve';
                    Image = Reserve;
                    ToolTip = 'Reserve the quantity that is required on the document line that you opened this window for.';

                    trigger OnAction()
                    begin
                        ReservEntry.LockTable;
                        UpdateReservMgt;
                        ReservMgt.PlanningComponentUpdateValues(Rec, QtyToReserve, QtyToReserveBase, QtyReservedThisLine, QtyReservedThisLineBase);
                        ReservMgt.CalculateRemainingQty(NewQtyReservedThisLine, NewQtyReservedThisLineBase);
                        ReservMgt.CopySign(NewQtyReservedThisLine, QtyToReserve);
                        ReservMgt.CopySign(NewQtyReservedThisLineBase, QtyToReserveBase);
                        if NewQtyReservedThisLineBase <> 0 then
                            if NewQtyReservedThisLineBase > QtyToReserveBase then
                                CreateReservation(QtyToReserve, QtyToReserveBase)
                            else
                                CreateReservation(NewQtyReservedThisLine, NewQtyReservedThisLineBase)
                        else
                            Error(Text000);
                    end;
                }
                action("&Cancel Reservation")
                {
                    AccessByPermission = TableData Item = R;
                    ApplicationArea = Reservation;
                    Caption = '&Cancel Reservation';
                    Image = Cancel;
                    ToolTip = 'Cancel the reservation that exists for the document line that you opened this window for.';

                    trigger OnAction()
                    begin
                        if not Confirm(Text001, false) then
                            exit;

                        ReservEntry2.Copy(ReservEntry);
                        ReservePlanningComponent.FilterReservFor(ReservEntry2, Rec);

                        if ReservEntry2.Find('-') then begin
                            UpdateReservMgt;
                            repeat
                                if ReservEntry2."Quantity (Base)" < 0 then
                                    Error(Text002);
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
        ReservMgt.PlanningComponentUpdateValues(Rec, QtyToReserve, QtyToReserveBase, QtyReservedThisLine, QtyReservedThisLineBase);
    end;

    trigger OnOpenPage()
    begin
        ReservEntry.TestField("Source Type");

        SetRange("Item No.", ReservEntry."Item No.");
        SetRange("Variant Code", ReservEntry."Variant Code");
        SetRange("Location Code", ReservEntry."Location Code");
        SetFilter("Due Date", ReservMgt.GetAvailabilityFilter(ReservEntry."Shipment Date"));
        if ReservMgt.IsPositive then
            SetFilter("Quantity (Base)", '<0')
        else
            SetFilter("Quantity (Base)", '>0');
    end;

    var
        Text000: Label 'Fully reserved.';
        Text001: Label 'Do you want to cancel the reservation?';
        Text002: Label 'Do not close negative reservations manually.';
        Text003: Label 'Available Quantity is %1.';
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
        AssemblyLine: Record "Assembly Line";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
        AssemblyHeaderReserve: Codeunit "Assembly Header-Reserve";
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
        QtyToReserve: Decimal;
        QtyToReserveBase: Decimal;
        QtyReservedThisLine: Decimal;
        QtyReservedThisLineBase: Decimal;
        NewQtyReservedThisLine: Decimal;
        NewQtyReservedThisLineBase: Decimal;
        CaptionText: Text;

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
    end;

    local procedure CreateReservation(ReserveQuantity: Decimal; ReserveQuantityBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
    begin
        CalcFields("Reserved Qty. (Base)");
        if "Quantity (Base)" + "Reserved Qty. (Base)" < ReserveQuantityBase then
            Error(Text003, "Quantity (Base)" + "Reserved Qty. (Base)");

        TestField("Item No.", ReservEntry."Item No.");
        TestField("Variant Code", ReservEntry."Variant Code");
        TestField("Location Code", ReservEntry."Location Code");

        UpdateReservMgt;
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Planning Component", 0, "Worksheet Template Name",
          "Worksheet Batch Name", "Worksheet Line No.", "Line No.", "Variant Code", "Location Code", "Qty. per Unit of Measure");
        ReservMgt.CreateReservation(
          ReservEntry.Description, "Due Date", ReserveQuantity, ReserveQuantityBase, TrackingSpecification);
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
            DATABASE::"Planning Component":
                begin
                    PlanningComponent.Find;
                    SetPlanningComponent(PlanningComponent, ReservEntry);
                end;
            DATABASE::"Transfer Line":
                begin
                    TransLine.Find;
                    SetTransferLine(TransLine, ReservEntry, ReservEntry."Source Subtype");
                end;
            DATABASE::"Service Line":
                begin
                    ServiceInvLine.Find;
                    SetServiceInvLine(ServiceInvLine, ReservEntry);
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
            DATABASE::"Planning Component":
                ReservMgt.SetPlanningComponent(PlanningComponent);
            DATABASE::"Transfer Line":
                ReservMgt.SetTransferLine(TransLine, ReservEntry."Source Subtype");
            DATABASE::"Service Line":
                ReservMgt.SetServLine(ServiceInvLine);
        end;

        OnAfterUpdateReservMgt(ReservEntry);
    end;

    local procedure GetReservedQtyInLine(): Decimal
    begin
        ReservEntry2.Reset;
        ReservePlanningComponent.FilterReservFor(ReservEntry2, Rec);
        ReservEntry2.SetRange("Reservation Status", ReservEntry2."Reservation Status"::Reservation);
        exit(ReservMgt.MarkReservConnection(ReservEntry2, ReservEntry));
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

