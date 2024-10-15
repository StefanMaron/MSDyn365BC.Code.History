page 12466 "Available - Item Doc. Lines"
{
    Caption = 'Available - Item Doc. Lines';
    DataCaptionExpression = CaptionText;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Item Document Line";
    SourceTableView = SORTING("Document Type", "Document No.", "Line No.");

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the warehouse or other place where the involved items are handled or stored.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Quantity (Base)"; "Quantity (Base)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity on the line expressed in base units of measure.';
                }
                field("Reserved Qty. Inbnd. (Base)"; "Reserved Qty. Inbnd. (Base)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item base quantity that is reserved at the warehouse of the receiver.';
                }
                field("Reserved Qty. Outbnd. (Base)"; "Reserved Qty. Outbnd. (Base)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item base quantity that is reserved at the warehouse of the receiver.';
                }
                field(QtyToReserveBase; QtyToReserveBase)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Available Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                }
                field(ReservedThisLine; ReservedThisLine)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Current Reserved Quantity';
                    DecimalPlaces = 0 : 5;

                    trigger OnDrillDown()
                    begin
                        ReservEntry2.Reset;
                        ReserveItemDocLine.FilterReservFor(ReservEntry2, Rec);
                        ReservEntry2.SetRange("Reservation Status", ReservEntry2."Reservation Status"::Reservation);
                        ReservMgt.MarkReservConnection(ReservEntry2, ReservEntry);
                        PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry2);
                        UpdateReservFrom;
                        CurrPage.Update;
                    end;
                }
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
                    ApplicationArea = Basic, Suite;
                    Caption = '&Reserve';
                    Image = Reserve;
                    ToolTip = 'Reserve the quantity that is required on the document line that you opened this window for.';

                    trigger OnAction()
                    begin
                        ReservEntry.LockTable;
                        UpdateReservMgt;
                        ReservMgt.ItemDocLineUpdateValues(Rec, QtyToReserve, QtyToReserveBase, QtyReservedThisLine, QtyReservedThisLineBase);
                        ReservMgt.CalculateRemainingQty(NewQtyReservedThisLine, NewQtyReservedThisLineBase);
                        ReservMgt.CopySign(NewQtyReservedThisLineBase, QtyToReserveBase);
                        ReservMgt.CopySign(NewQtyReservedThisLine, QtyToReserve);
                        if NewQtyReservedThisLineBase <> 0 then
                            if Abs(NewQtyReservedThisLineBase) > Abs(QtyToReserveBase) then
                                CreateReservation(QtyToReserve, QtyToReserveBase)
                            else
                                CreateReservation(NewQtyReservedThisLine, NewQtyReservedThisLineBase)
                        else
                            Error(Text001);
                    end;
                }
                action("&Cancel Reservation")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Cancel Reservation';
                    Image = Cancel;
                    ToolTip = 'Cancel the reservation that exists for the document line that you opened this window for.';

                    trigger OnAction()
                    begin
                        if not Confirm(Text002, false) then
                            exit;

                        ReservEntry2.Copy(ReservEntry);
                        ReserveItemDocLine.FilterReservFor(ReservEntry2, Rec);

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
        ReservMgt.ItemDocLineUpdateValues(Rec, QtyToReserve, QtyToReserveBase, QtyReservedThisLine, QtyReservedThisLineBase);
    end;

    trigger OnOpenPage()
    begin
        ReservEntry.TestField("Source Type");

        SetFilter("Document Date", ReservMgt.GetAvailabilityFilter(ReservEntry."Shipment Date"));
        SetRange("Location Code", ReservEntry."Location Code");
        SetRange("Item No.", ReservEntry."Item No.");
        SetRange("Variant Code", ReservEntry."Variant Code");
        SetFilter(Quantity, '>0');
    end;

    var
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
        ItemDocLine: Record "Item Document Line";
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
        ReserveItemDocLine: Codeunit "Item Doc. Line-Reserve";
        QtyToReserve: Decimal;
        QtyToReserveBase: Decimal;
        QtyReservedThisLine: Decimal;
        QtyReservedThisLineBase: Decimal;
        NewQtyReservedThisLine: Decimal;
        NewQtyReservedThisLineBase: Decimal;
        CaptionText: Text;
        Direction: Option Outbound,Inbound;

    [Scope('OnPrem')]
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

    [Scope('OnPrem')]
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

    [Scope('OnPrem')]
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

    [Scope('OnPrem')]
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

    [Scope('OnPrem')]
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

    [Scope('OnPrem')]
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

    [Scope('OnPrem')]
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

    [Scope('OnPrem')]
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

    [Scope('OnPrem')]
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

    [Scope('OnPrem')]
    procedure SetItemDocLine(var CurrentItemDocLine: Record "Item Document Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        ItemDocLine := CurrentItemDocLine;
        ReservEntry := CurrentReservEntry;

        Clear(ReservMgt);
        ReservMgt.SetItemDocLine(ItemDocLine);
        ReservEngineMgt.InitFilterAndSortingFor(ReservEntry, true);
        ReserveItemDocLine.FilterReservFor(ReservEntry, ItemDocLine);
        CaptionText := ReserveItemDocLine.Caption(ItemDocLine);
        SetInbound(ReservMgt.IsPositive);
    end;

    [Scope('OnPrem')]
    procedure CreateReservation(ReserveQuantity: Decimal; ReserveQuantityBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        QtyThisLine: Decimal;
        ReservQty: Decimal;
        LocationCode: Code[10];
        EntryDate: Date;
    begin
        case "Document Type" of
            1: // Shipment
                begin
                    CalcFields("Reserved Qty. Outbnd. (Base)");
                    QtyThisLine := "Quantity (Base)";
                    ReservQty := "Reserved Qty. Outbnd. (Base)";
                    EntryDate := "Document Date";
                    TestField("Location Code", ReservEntry."Location Code");
                    LocationCode := "Location Code";
                end;
            0: // Receipt
                begin
                    CalcFields("Reserved Qty. Inbnd. (Base)");
                    QtyThisLine := "Quantity (Base)";
                    ReservQty := "Reserved Qty. Inbnd. (Base)";
                    EntryDate := "Document Date";
                    TestField("Location Code", ReservEntry."Location Code");
                    LocationCode := "Location Code";
                end;
        end;

        if QtyThisLine - ReservQty < ReserveQuantityBase then
            Error(Text003, QtyThisLine + ReservQty);

        TestField("Item No.", ReservEntry."Item No.");
        TestField("Variant Code", ReservEntry."Variant Code");

        UpdateReservMgt;
        ReservMgt.CreateTrackingSpecification(TrackingSpecification,
          DATABASE::"Item Document Line", "Document Type",
          "Document No.", '', 0, "Line No.",
          "Variant Code", LocationCode, '', '', '', "Qty. per Unit of Measure");
        ReservMgt.CreateReservation(
          ReservEntry.Description, EntryDate, ReserveQuantity, ReserveQuantityBase, TrackingSpecification);
        UpdateReservFrom;
    end;

    [Scope('OnPrem')]
    procedure UpdateReservFrom()
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
            DATABASE::"Item Document Line":
                begin
                    ItemDocLine.Find;
                    SetItemDocLine(ItemDocLine, ReservEntry);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateReservMgt()
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
            DATABASE::"Transfer Line":
                ReservMgt.SetTransferLine(TransLine, ReservEntry."Source Subtype");
            DATABASE::"Planning Component":
                ReservMgt.SetPlanningComponent(PlanningComponent);
            DATABASE::"Job Planning Line":
                ReservMgt.SetJobPlanningLine(JobPlanningLine);
            DATABASE::"Item Document Line":
                ReservMgt.SetItemDocLine(ItemDocLine);
        end;
    end;

    [Scope('OnPrem')]
    procedure ReservedThisLine(): Decimal
    begin
        ReservEntry2.Reset;
        ReserveItemDocLine.FilterReservFor(ReservEntry2, Rec);
        ReservEntry2.SetRange("Reservation Status", ReservEntry2."Reservation Status"::Reservation);
        exit(ReservMgt.MarkReservConnection(ReservEntry2, ReservEntry));
    end;

    [Scope('OnPrem')]
    procedure SetInbound(DirectionIsInbound: Boolean)
    begin
        if DirectionIsInbound then
            Direction := Direction::Inbound
        else
            Direction := Direction::Outbound;
    end;

    [Scope('OnPrem')]
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

    [Scope('OnPrem')]
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
}

