codeunit 99000815 "Reservation-Check Date Confl."
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'The change leads to a date conflict with existing reservations.\';
        Text001: Label 'Reserved quantity (Base): %1, Date %2\';
        Text002: Label 'Cancel or change reservations and try again.';
        ReservEntry: Record "Reservation Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReserveSalesLine: Codeunit "Sales Line-Reserve";
        ReservePurchLine: Codeunit "Purch. Line-Reserve";
        ReserveReqLine: Codeunit "Req. Line-Reserve";
        ReserveItemJnlLine: Codeunit "Item Jnl. Line-Reserve";
        ReserveProdOrderLine: Codeunit "Prod. Order Line-Reserve";
        ReserveProdOrderComp: Codeunit "Prod. Order Comp.-Reserve";
        AssemblyHeaderReserve: Codeunit "Assembly Header-Reserve";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
        ReservePlanningComponent: Codeunit "Plng. Component-Reserve";
        ReserveTransLine: Codeunit "Transfer Line-Reserve";
        ServLineReserve: Codeunit "Service Line-Reserve";
        JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
        ReservMgt: Codeunit "Reservation Management";
        DateConflictMsg: Label 'The change causes a date conflict with an existing reservation on %2 for %1 units.\ \The reservations have been canceled. The production order must be replanned.', Comment = '%1: Field(Reserved Quantity (Base)), %2: Field(Due Date)';

    procedure SalesLineCheck(SalesLine: Record "Sales Line"; ForceRequest: Boolean)
    begin
        if not ReserveSalesLine.FindReservEntry(SalesLine, ReservEntry) then
            exit;
        if DateConflict(SalesLine."Shipment Date", ForceRequest, ReservEntry) then
            if ForceRequest then
                IssueError(SalesLine."Shipment Date");
        UpdateDate(ReservEntry, SalesLine."Shipment Date");
        ReservMgt.SetSalesLine(SalesLine);
        ReservMgt.ClearSurplus;
        ReservMgt.AutoTrack(SalesLine."Outstanding Qty. (Base)");
    end;

    procedure PurchLineCheck(PurchLine: Record "Purchase Line"; ForceRequest: Boolean)
    begin
        if not ReservePurchLine.FindReservEntry(PurchLine, ReservEntry) then
            exit;
        if DateConflict(PurchLine."Expected Receipt Date", ForceRequest, ReservEntry) then
            if ForceRequest then
                IssueError(PurchLine."Expected Receipt Date");
        UpdateDate(ReservEntry, PurchLine."Expected Receipt Date");
        ReservMgt.SetPurchLine(PurchLine);
        ReservMgt.ClearSurplus;
        ReservMgt.AutoTrack(PurchLine."Outstanding Qty. (Base)");
    end;

    procedure ItemJnlLineCheck(ItemJnlLine: Record "Item Journal Line"; ForceRequest: Boolean)
    begin
        if not ReserveItemJnlLine.FindReservEntry(ItemJnlLine, ReservEntry) then
            exit;
        if DateConflict(ItemJnlLine."Posting Date", ForceRequest, ReservEntry) then
            if ForceRequest then
                IssueError(ItemJnlLine."Posting Date");
        UpdateDate(ReservEntry, ItemJnlLine."Posting Date");
        ReservMgt.SetItemJnlLine(ItemJnlLine);
        ReservMgt.ClearSurplus;
        ReservMgt.AutoTrack(ItemJnlLine."Quantity (Base)");
    end;

    procedure ReqLineCheck(ReqLine: Record "Requisition Line"; ForceRequest: Boolean)
    begin
        if not ReserveReqLine.FindReservEntry(ReqLine, ReservEntry) then
            exit;
        if DateConflict(ReqLine."Due Date", ForceRequest, ReservEntry) then
            if ForceRequest then
                IssueError(ReqLine."Due Date");
        UpdateDate(ReservEntry, ReqLine."Due Date");
        ReservMgt.SetReqLine(ReqLine);
        ReservMgt.ClearSurplus;
        ReservMgt.AutoTrack(ReqLine."Quantity (Base)");
    end;

    procedure ProdOrderLineCheck(ProdOrderLine: Record "Prod. Order Line"; ForceRequest: Boolean)
    begin
        if not ReserveProdOrderLine.FindReservEntry(ProdOrderLine, ReservEntry) then
            exit;
        if DateConflict(ProdOrderLine."Due Date", ForceRequest, ReservEntry) then
            if ForceRequest then
                IssueError(ProdOrderLine."Due Date");
        UpdateDate(ReservEntry, ProdOrderLine."Due Date");
        ReservMgt.SetProdOrderLine(ProdOrderLine);
        ReservMgt.ClearSurplus;
        ReservMgt.AutoTrack(ProdOrderLine."Remaining Qty. (Base)");
    end;

    procedure ProdOrderComponentCheck(ProdOrderComp: Record "Prod. Order Component"; ForceRequest: Boolean; IsCritical: Boolean): Boolean
    begin
        if not ReserveProdOrderComp.FindReservEntry(ProdOrderComp, ReservEntry) then
            exit(false);
        if DateConflict(ProdOrderComp."Due Date", ForceRequest, ReservEntry) then
            if ForceRequest then
                if IsCritical then
                    IssueError(ProdOrderComp."Due Date")
                else
                    IssueWarning(ProdOrderComp."Due Date");
        UpdateDate(ReservEntry, ProdOrderComp."Due Date");
        ReservMgt.SetProdOrderComponent(ProdOrderComp);
        ReservMgt.ClearSurplus;
        ReservMgt.AutoTrack(ProdOrderComp."Remaining Qty. (Base)");
        exit(ForceRequest);
    end;

    procedure AssemblyHeaderCheck(AssemblyHeader: Record "Assembly Header"; ForceRequest: Boolean)
    begin
        if not AssemblyHeaderReserve.FindReservEntry(AssemblyHeader, ReservEntry) then
            exit;
        if DateConflict(AssemblyHeader."Due Date", ForceRequest, ReservEntry) then
            if ForceRequest then
                IssueError(AssemblyHeader."Due Date");
        UpdateDate(ReservEntry, AssemblyHeader."Due Date");
        ReservMgt.SetAssemblyHeader(AssemblyHeader);
        ReservMgt.ClearSurplus;
        ReservMgt.AutoTrack(AssemblyHeader."Remaining Quantity (Base)");
    end;

    procedure AssemblyLineCheck(AssemblyLine: Record "Assembly Line"; ForceRequest: Boolean)
    begin
        if not AssemblyLineReserve.FindReservEntry(AssemblyLine, ReservEntry) then
            exit;
        if DateConflict(AssemblyLine."Due Date", ForceRequest, ReservEntry) then
            if ForceRequest then
                IssueError(AssemblyLine."Due Date");
        UpdateDate(ReservEntry, AssemblyLine."Due Date");
        ReservMgt.SetAssemblyLine(AssemblyLine);
        ReservMgt.ClearSurplus;
        ReservMgt.AutoTrack(AssemblyLine."Remaining Quantity (Base)");
    end;

    procedure PlanningComponentCheck(PlanningComponent: Record "Planning Component"; ForceRequest: Boolean)
    begin
        if not ReservePlanningComponent.FindReservEntry(PlanningComponent, ReservEntry) then
            exit;
        if DateConflict(PlanningComponent."Due Date", ForceRequest, ReservEntry) then
            if ForceRequest then
                IssueError(PlanningComponent."Due Date");
        UpdateDate(ReservEntry, PlanningComponent."Due Date");
        ReservMgt.SetPlanningComponent(PlanningComponent);
        ReservMgt.ClearSurplus;
        ReservMgt.AutoTrack(PlanningComponent."Net Quantity (Base)");
    end;

    procedure TransferLineCheck(TransLine: Record "Transfer Line")
    var
        ResEntryFound: Boolean;
        ForceRequest: Boolean;
        Direction: Option Outbound,Inbound;
    begin
        if ReserveTransLine.FindReservEntry(TransLine, ReservEntry, Direction::Outbound) then begin
            ResEntryFound := true;
            ForceRequest := true;
            if DateConflict(TransLine."Shipment Date", ForceRequest, ReservEntry) then
                if ForceRequest then
                    IssueError(TransLine."Shipment Date");
            UpdateDate(ReservEntry, TransLine."Shipment Date");
        end;

        if ReserveTransLine.FindInboundReservEntry(TransLine, ReservEntry) then begin
            ResEntryFound := true;
            ForceRequest := true;
            if DateConflict(TransLine."Receipt Date", ForceRequest, ReservEntry) then
                if ForceRequest then
                    IssueError(TransLine."Receipt Date");
            UpdateDate(ReservEntry, TransLine."Receipt Date");
        end;
        if not ResEntryFound then
            exit;
        ReservMgt.SetTransferLine(TransLine, Direction);
        ReservMgt.ClearSurplus;
        ReservMgt.AutoTrack(TransLine."Outstanding Qty. (Base)");
    end;

    procedure ServiceInvLineCheck(ServLine: Record "Service Line"; ForceRequest: Boolean)
    begin
        if not ServLineReserve.FindReservEntry(ServLine, ReservEntry) then
            exit;
        if DateConflict(ServLine."Needed by Date", ForceRequest, ReservEntry) then
            if ForceRequest then
                IssueError(ServLine."Needed by Date");
        UpdateDate(ReservEntry, ServLine."Needed by Date");
        ReservMgt.SetServLine(ServLine);
        ReservMgt.ClearSurplus;
        ReservMgt.AutoTrack(ServLine."Outstanding Qty. (Base)");
    end;

    procedure JobPlanningLineCheck(JobPlanningLine: Record "Job Planning Line"; ForceRequest: Boolean)
    begin
        if not JobPlanningLineReserve.FindReservEntry(JobPlanningLine, ReservEntry) then
            exit;
        if DateConflict(JobPlanningLine."Planning Date", ForceRequest, ReservEntry) then
            if ForceRequest then
                IssueError(JobPlanningLine."Planning Date");
        UpdateDate(ReservEntry, JobPlanningLine."Planning Date");
        ReservMgt.SetJobPlanningLine(JobPlanningLine);
        ReservMgt.ClearSurplus;
        ReservMgt.AutoTrack(JobPlanningLine."Remaining Qty. (Base)");
    end;

    procedure UpdateDate(var FilterReservEntry: Record "Reservation Entry"; Date: Date)
    var
        ForceModifyShipmentDate: Boolean;
    begin
        FilterReservEntry.SetRange("Reservation Status");
        if not FilterReservEntry.Find('-') then
            exit;

        repeat
            OnUpdateDateFilterReservEntryLoop(FilterReservEntry, ForceModifyShipmentDate, Date);
            if FilterReservEntry."Quantity (Base)" < 0 then
                if (FilterReservEntry."Expected Receipt Date" <> 0D) and
                   (Date < FilterReservEntry."Expected Receipt Date") and not ForceModifyShipmentDate
                then
                    if (FilterReservEntry.Binding <> FilterReservEntry.Binding::"Order-to-Order") and
                       FilterReservEntry.TrackingExists
                    then
                        ReservEngineMgt.SplitTrackingConnection(FilterReservEntry, Date)
                    else
                        if SameProdOrderAutoReserve(FilterReservEntry) then
                            ReservEngineMgt.ModifyExpectedReceiptDate(FilterReservEntry, Date)
                        else
                            ReservEngineMgt.CloseReservEntry(FilterReservEntry, false, false)
                else
                    ReservEngineMgt.ModifyShipmentDate(FilterReservEntry, Date)
            else
                if ((FilterReservEntry."Shipment Date" <> 0D) and
                    (FilterReservEntry."Shipment Date" < Date))
                then
                    if (FilterReservEntry.Binding <> FilterReservEntry.Binding::"Order-to-Order") and
                       FilterReservEntry.TrackingExists
                    then
                        ReservEngineMgt.SplitTrackingConnection(FilterReservEntry, Date)
                    else
                        ReservEngineMgt.CloseReservEntry(FilterReservEntry, false, false)
                else
                    ReservEngineMgt.ModifyExpectedReceiptDate(FilterReservEntry, Date);
        until FilterReservEntry.Next = 0;
    end;

    procedure DateConflict(Date: Date; var ForceRequest: Boolean; var ReservationEntry: Record "Reservation Entry") IsConflict: Boolean
    var
        ReservEntry2: Record "Reservation Entry";
    begin
        ReservEntry2.Copy(ReservationEntry);

        if not ReservEntry2.FindFirst then
            exit(false);

        if ReservEntry2."Quantity (Base)" < 0 then
            ReservEntry2.SetFilter("Expected Receipt Date", '>%1', Date)
        else
            if Date <> 0D then
                ReservEntry2.SetRange("Shipment Date", 00000101D, Date - 1);

        if ReservEntry2.IsEmpty then
            exit(false);

        IsConflict := true;

        // Don't look at tracking and surplus:
        ReservEntry2.SetRange("Reservation Status", ReservEntry2."Reservation Status"::Reservation);

        ForceRequest := not ReservEntry2.IsEmpty and ForceRequest;

        exit(IsConflict);
    end;

    procedure IssueError(NewDate: Date)
    var
        ReservQty: Decimal;
    begin
        ReservQty := CalcReservQty(NewDate);
        Error(Text000 + Text001 + Text002, ReservQty, NewDate);
    end;

    procedure IssueWarning(NewDate: Date)
    var
        ReservQty: Decimal;
    begin
        ReservQty := CalcReservQty(NewDate);
        Message(DateConflictMsg, ReservQty, NewDate);
    end;

    local procedure CalcReservQty(NewDate: Date): Decimal
    var
        ReservEntry2: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservDueDate: Date;
        ReservExpectDate: Date;
        SumValue: Decimal;
    begin
        ReservEntry2.Copy(ReservEntry);
        ReservDueDate := NewDate;
        ReservExpectDate := NewDate;

        if not ReservEntry2.Find('-') then
            exit(0);
        if ReservEntry2."Quantity (Base)" < 0 then
            ReservExpectDate := 0D
        else
            ReservDueDate := DMY2Date(31, 12, 9999);

        repeat
            SumValue += ReservEntry2."Quantity (Base)";
            if ReservEntry2."Quantity (Base)" < 0 then begin
                if ReservEntry2."Expected Receipt Date" <> 0D then  // Item ledger entries will be 0D.
                    if (ReservEntry2."Expected Receipt Date" > ReservExpectDate) and
                       (ReservEntry2."Expected Receipt Date" > ReservDueDate)
                    then
                        ReservExpectDate := ReservEntry2."Expected Receipt Date";
            end else begin
                if ReservEntry2."Shipment Date" <> 0D then          // Item ledger entries will be 0D.
                    if (ReservEntry2."Shipment Date" < ReservDueDate) and (ReservEntry2."Shipment Date" < ReservExpectDate) then
                        ReservDueDate := ReservEntry2."Shipment Date";
            end;
        until ReservEntry2.Next = 0;

        exit(CreateReservEntry.SignFactor(ReservEntry2) * SumValue);
    end;

    local procedure SameProdOrderAutoReserve(FilterReservEntry: Record "Reservation Entry"): Boolean
    var
        ProdOrderLineReservationEntry: Record "Reservation Entry";
    begin
        if FilterReservEntry."Source Type" = DATABASE::"Prod. Order Component" then
            if ProdOrderLineReservationEntry.Get(FilterReservEntry."Entry No.", not FilterReservEntry.Positive) then
                if ProdOrderLineReservationEntry."Source Type" = DATABASE::"Prod. Order Line" then
                    if FilterReservEntry."Source ID" = ProdOrderLineReservationEntry."Source ID" then
                        exit(ProdOrderLineReservationEntry."Source Prod. Order Line" = GetSuppliedByLineNoByReservationEntry(FilterReservEntry));
        exit(false);
    end;

    local procedure GetSuppliedByLineNoByReservationEntry(ReservationEntry: Record "Reservation Entry"): Integer
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        with ReservationEntry do
            ProdOrderComponent.Get("Source Subtype", "Source ID", "Source Prod. Order Line", "Source Ref. No.");
        exit(ProdOrderComponent."Supplied-by Line No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDateFilterReservEntryLoop(var ReservationEntry: Record "Reservation Entry"; var ForceModifyShipmentDate: Boolean; Date: Date)
    begin
    end;
}

