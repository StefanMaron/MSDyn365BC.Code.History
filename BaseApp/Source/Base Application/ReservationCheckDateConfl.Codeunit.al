codeunit 99000815 "Reservation-Check Date Confl."
{

    trigger OnRun()
    begin
    end;

    var
        ReservEntry: Record "Reservation Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReservMgt: Codeunit "Reservation Management";
        DateConflictMsg: Label 'The change causes a date conflict with an existing reservation on %2 for %1 units.\ \The reservations have been canceled. The production order must be replanned.', Comment = '%1: Field(Reserved Quantity (Base)), %2: Field(Due Date)';
        DateConflictErr: Label 'The change leads to a date conflict with existing reservations.\Reserved quantity (Base): %1, Date %2\Cancel or change reservations and try again.', Comment = '%1 - reserved quantity, %2 - date';

    procedure SalesLineCheck(SalesLine: Record "Sales Line"; ForceRequest: Boolean)
    var
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        IsHandled: Boolean;
    begin
        if not SalesLineReserve.FindReservEntry(SalesLine, ReservEntry) then
            exit;

        IsHandled := false;
        OnSalesLineCheckOnBeforeIssueError(ReservEntry, SalesLine, IsHandled);
        if not IsHandled then
            if DateConflict(SalesLine."Shipment Date", ForceRequest, ReservEntry) then
                if ForceRequest then
                    IssueError(SalesLine."Shipment Date");

        IsHandled := false;
        OnSalesLineCheckOnBeforeUpdateDate(ReservEntry, SalesLine, IsHandled);
        if not IsHandled then
            UpdateDate(ReservEntry, SalesLine."Shipment Date");

        ReservMgt.SetReservSource(SalesLine);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(SalesLine."Outstanding Qty. (Base)");
    end;

    procedure PurchLineCheck(PurchLine: Record "Purchase Line"; ForceRequest: Boolean)
    var
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
        IsHandled: Boolean;
    begin
        if not PurchLineReserve.FindReservEntry(PurchLine, ReservEntry) then
            exit;

        if DateConflict(PurchLine."Expected Receipt Date", ForceRequest, ReservEntry) then
            if ForceRequest then
                IssueError(PurchLine."Expected Receipt Date");

        IsHandled := false;
        OnPurchLineCheckOnBeforeUpdateDate(ReservEntry, PurchLine, IsHandled);
        if not IsHandled then
            UpdateDate(ReservEntry, PurchLine."Expected Receipt Date");

        ReservMgt.SetReservSource(PurchLine);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(PurchLine."Outstanding Qty. (Base)");
    end;

    procedure ItemJnlLineCheck(ItemJnlLine: Record "Item Journal Line"; ForceRequest: Boolean)
    var
        ItemJnlLineReserve: Codeunit "Item Jnl. Line-Reserve";
        IsHandled: Boolean;
    begin
        if not ItemJnlLineReserve.FindReservEntry(ItemJnlLine, ReservEntry) then
            exit;

        if DateConflict(ItemJnlLine."Posting Date", ForceRequest, ReservEntry) then
            if ForceRequest then
                IssueError(ItemJnlLine."Posting Date");

        IsHandled := false;
        OnItemJnlLineCheckOnBeforeUpdateDate(ReservEntry, ItemJnlLine, IsHandled);
        if not IsHandled then
            UpdateDate(ReservEntry, ItemJnlLine."Posting Date");

        ReservMgt.SetReservSource(ItemJnlLine);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(ItemJnlLine."Quantity (Base)");
    end;

    procedure ReqLineCheck(ReqLine: Record "Requisition Line"; ForceRequest: Boolean)
    var
        ReqLineReserve: Codeunit "Req. Line-Reserve";
        IsHandled: Boolean;
    begin
        if not ReqLineReserve.FindReservEntry(ReqLine, ReservEntry) then
            exit;

        if DateConflict(ReqLine."Due Date", ForceRequest, ReservEntry) then
            if ForceRequest then
                IssueError(ReqLine."Due Date");

        IsHandled := false;
        OnReqLineCheckOnBeforeUpdateDate(ReservEntry, ReqLine, IsHandled);
        if not IsHandled then
            UpdateDate(ReservEntry, ReqLine."Due Date");

        ReservMgt.SetReservSource(ReqLine);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(ReqLine."Quantity (Base)");
    end;

    procedure ProdOrderLineCheck(ProdOrderLine: Record "Prod. Order Line"; ForceRequest: Boolean)
    var
        ProdOrderLineReserve: Codeunit "Prod. Order Line-Reserve";
        IsHandled: Boolean;
    begin
        if not ProdOrderLineReserve.FindReservEntry(ProdOrderLine, ReservEntry) then
            exit;

        CheckProdOrderLineDateConflict(ProdOrderLine, ForceRequest);

        IsHandled := false;
        OnProdOrderLineCheckOnBeforeUpdateDate(ReservEntry, ProdOrderLine, IsHandled);
        if not IsHandled then
            UpdateDate(ReservEntry, ProdOrderLine."Due Date");

        ReservMgt.SetReservSource(ProdOrderLine);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(ProdOrderLine."Remaining Qty. (Base)");
    end;

    local procedure CheckProdOrderLineDateConflict(ProdOrderLine: Record "Prod. Order Line"; ForceRequest: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckProdOrderLineDateConflict(ProdOrderLine."Due Date", ForceRequest, ReservEntry, IsHandled);
        if IsHandled then
            exit;

        if DateConflict(ProdOrderLine."Due Date", ForceRequest, ReservEntry) then
            if ForceRequest then
                IssueError(ProdOrderLine."Due Date");
    end;

    procedure ProdOrderComponentCheck(ProdOrderComp: Record "Prod. Order Component"; ForceRequest: Boolean; IsCritical: Boolean): Boolean
    var
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
        IsHandled: Boolean;
    begin
        if not ProdOrderCompReserve.FindReservEntry(ProdOrderComp, ReservEntry) then
            exit(false);

        if DateConflict(ProdOrderComp."Due Date", ForceRequest, ReservEntry) then
            if ForceRequest then
                if IsCritical then
                    IssueError(ProdOrderComp."Due Date")
                else
                    IssueWarning(ProdOrderComp."Due Date");

        IsHandled := false;
        OnProdOrderComponentCheckOnBeforeUpdateDate(ReservEntry, ProdOrderComp, IsHandled);
        if not IsHandled then
            UpdateDate(ReservEntry, ProdOrderComp."Due Date");

        ReservMgt.SetReservSource(ProdOrderComp);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(ProdOrderComp."Remaining Qty. (Base)");
        exit(ForceRequest);
    end;

    procedure AssemblyHeaderCheck(AssemblyHeader: Record "Assembly Header"; ForceRequest: Boolean)
    var
        AssemblyHeaderReserve: Codeunit "Assembly Header-Reserve";
        IsHandled: Boolean;
    begin
        if not AssemblyHeaderReserve.FindReservEntry(AssemblyHeader, ReservEntry) then
            exit;

        if DateConflict(AssemblyHeader."Due Date", ForceRequest, ReservEntry) then
            if ForceRequest then
                IssueError(AssemblyHeader."Due Date");

        IsHandled := false;
        OnAssemblyHeaderCheckOnBeforeUpdateDate(ReservEntry, AssemblyHeader, IsHandled);
        if not IsHandled then
            UpdateDate(ReservEntry, AssemblyHeader."Due Date");

        ReservMgt.SetReservSource(AssemblyHeader);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(AssemblyHeader."Remaining Quantity (Base)");
    end;

    procedure AssemblyLineCheck(AssemblyLine: Record "Assembly Line"; ForceRequest: Boolean)
    var
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
        IsHandled: Boolean;
    begin
        if not AssemblyLineReserve.FindReservEntry(AssemblyLine, ReservEntry) then
            exit;

        if DateConflict(AssemblyLine."Due Date", ForceRequest, ReservEntry) then
            if ForceRequest then
                IssueError(AssemblyLine."Due Date");

        IsHandled := false;
        OnAssemblyLineCheckOnBeforeUpdateDate(ReservEntry, AssemblyLine, IsHandled);
        if not IsHandled then
            UpdateDate(ReservEntry, AssemblyLine."Due Date");

        ReservMgt.SetReservSource(AssemblyLine);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(AssemblyLine."Remaining Quantity (Base)");
    end;

    procedure PlanningComponentCheck(PlanningComponent: Record "Planning Component"; ForceRequest: Boolean)
    var
        PlanningComponentReserve: Codeunit "Plng. Component-Reserve";
        IsHandled: Boolean;
    begin
        if not PlanningComponentReserve.FindReservEntry(PlanningComponent, ReservEntry) then
            exit;

        if DateConflict(PlanningComponent."Due Date", ForceRequest, ReservEntry) then
            if ForceRequest then
                IssueError(PlanningComponent."Due Date");

        IsHandled := false;
        OnPlanningComponentCheckOnBeforeUpdateDate(ReservEntry, PlanningComponent, IsHandled);
        if not IsHandled then
            UpdateDate(ReservEntry, PlanningComponent."Due Date");

        ReservMgt.SetReservSource(PlanningComponent);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(PlanningComponent."Net Quantity (Base)");
    end;

    procedure TransferLineCheck(TransLine: Record "Transfer Line")
    var
        ReserveTransLine: Codeunit "Transfer Line-Reserve";
        ResEntryFound: Boolean;
        ForceRequest: Boolean;
        Direction: Enum "Transfer Direction";
        IsHandled: Boolean;
    begin
        if ReserveTransLine.FindReservEntry(TransLine, ReservEntry, Direction::Outbound) then begin
            ResEntryFound := true;
            ForceRequest := true;
            if DateConflict(TransLine."Shipment Date", ForceRequest, ReservEntry) then
                if ForceRequest then
                    IssueError(TransLine."Shipment Date");

            IsHandled := false;
            OnTransLineCheckOnBeforeUpdateDate(ReservEntry, TransLine, Direction.AsInteger(), IsHandled);
            if not IsHandled then
                UpdateDate(ReservEntry, TransLine."Shipment Date");
        end;

        if ReserveTransLine.FindInboundReservEntry(TransLine, ReservEntry) then begin
            ResEntryFound := true;
            ForceRequest := true;
            if DateConflict(TransLine."Receipt Date", ForceRequest, ReservEntry) then
                if ForceRequest then
                    IssueError(TransLine."Receipt Date");

            IsHandled := false;
            OnTransLineCheckOnBeforeUpdateDate(ReservEntry, TransLine, Direction.AsInteger(), IsHandled);
            if not IsHandled then
                UpdateDate(ReservEntry, TransLine."Receipt Date");
        end;

        if not ResEntryFound then
            exit;

        ReservMgt.SetReservSource(TransLine, Direction);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(TransLine."Outstanding Qty. (Base)");
    end;

    procedure ServiceInvLineCheck(ServLine: Record "Service Line"; ForceRequest: Boolean)
    var
        ServLineReserve: Codeunit "Service Line-Reserve";
    begin
        if not ServLineReserve.FindReservEntry(ServLine, ReservEntry) then
            exit;
        if DateConflict(ServLine."Needed by Date", ForceRequest, ReservEntry) then
            if ForceRequest then
                IssueError(ServLine."Needed by Date");
        UpdateDate(ReservEntry, ServLine."Needed by Date");
        ReservMgt.SetReservSource(ServLine);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(ServLine."Outstanding Qty. (Base)");
    end;

    procedure JobPlanningLineCheck(JobPlanningLine: Record "Job Planning Line"; ForceRequest: Boolean)
    var
        JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
    begin
        if not JobPlanningLineReserve.FindReservEntry(JobPlanningLine, ReservEntry) then
            exit;
        if DateConflict(JobPlanningLine."Planning Date", ForceRequest, ReservEntry) then
            if ForceRequest then
                IssueError(JobPlanningLine."Planning Date");
        UpdateDate(ReservEntry, JobPlanningLine."Planning Date");
        ReservMgt.SetReservSource(JobPlanningLine);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(JobPlanningLine."Remaining Qty. (Base)");
    end;

    procedure InvtDocLineCheck(InvtDocLine: Record "Invt. Document Line"; ForceRequest: Boolean): Boolean
    var
        InvtDocLineReserve: Codeunit "Invt. Doc. Line-Reserve";
    begin
        if not InvtDocLineReserve.FindReservEntry(InvtDocLine, ReservEntry) then
            exit;

        if DateConflict(InvtDocLine."Document Date", ForceRequest, ReservEntry) then
            if ForceRequest then IssueError(InvtDocLine."Document Date");
        UpdateDate(ReservEntry, InvtDocLine."Document Date");
        ReservMgt.SetReservSource(InvtDocLine);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(InvtDocLine."Quantity (Base)");
    end;

    procedure UpdateDate(var FilterReservEntry: Record "Reservation Entry"; Date: Date)
    var
        ForceModifyShipmentDate: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateDate(FilterReservEntry, Date, IsHandled);
        if IsHandled then
            exit;

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
                       FilterReservEntry.TrackingExists()
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
                       FilterReservEntry.TrackingExists()
                    then
                        ReservEngineMgt.SplitTrackingConnection(FilterReservEntry, Date)
                    else
                        ReservEngineMgt.CloseReservEntry(FilterReservEntry, false, false)
                else
                    ReservEngineMgt.ModifyExpectedReceiptDate(FilterReservEntry, Date);
        until FilterReservEntry.Next() = 0;
    end;

    procedure DateConflict(Date: Date; var ForceRequest: Boolean; var ReservationEntry: Record "Reservation Entry") IsConflict: Boolean
    var
        ReservEntry2: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDateConflict(ReservationEntry, Date, IsConflict, IsHandled);
        if IsHandled then
            exit;

        ReservEntry2.Copy(ReservationEntry);

        if not ReservEntry2.FindFirst() then
            exit(false);

        if ReservEntry2."Quantity (Base)" < 0 then
            ReservEntry2.SetFilter("Expected Receipt Date", '>%1', Date)
        else
            if Date <> 0D then
                ReservEntry2.SetRange("Shipment Date", 00000101D, Date - 1);

        if ReservEntry2.IsEmpty() then
            exit(false);

        IsConflict := true;

        // Don't look at tracking and surplus:
        ReservEntry2.SetRange("Reservation Status", ReservEntry2."Reservation Status"::Reservation);

        ForceRequest := not ReservEntry2.IsEmpty() and ForceRequest;

        OnAfterDateConflict(ReservationEntry, Date, IsConflict, ForceRequest);
        exit(IsConflict);
    end;

    procedure IssueError(NewDate: Date)
    var
        ReservQty: Decimal;
    begin
        ReservQty := CalcReservQty(NewDate);
        Error(DateConflictErr, ReservQty, NewDate);
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
            end else
                if ReservEntry2."Shipment Date" <> 0D then          // Item ledger entries will be 0D.
                    if (ReservEntry2."Shipment Date" < ReservDueDate) and (ReservEntry2."Shipment Date" < ReservExpectDate) then
                        ReservDueDate := ReservEntry2."Shipment Date";
        until ReservEntry2.Next() = 0;

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
    local procedure OnBeforeCheckProdOrderLineDateConflict(DueDate: Date; var ForceRequest: Boolean; var ReservationEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDate(var ReservationEntry: Record "Reservation Entry"; NewDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesLineCheckOnBeforeUpdateDate(var ReservationEntry: Record "Reservation Entry"; SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPurchLineCheckOnBeforeUpdateDate(var ReservationEntry: Record "Reservation Entry"; PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReqLineCheckOnBeforeUpdateDate(var ReservationEntry: Record "Reservation Entry"; RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemJnlLineCheckOnBeforeUpdateDate(var ReservationEntry: Record "Reservation Entry"; ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProdOrderLineCheckOnBeforeUpdateDate(var ReservationEntry: Record "Reservation Entry"; ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProdOrderComponentCheckOnBeforeUpdateDate(var ReservationEntry: Record "Reservation Entry"; ProdOrderComp: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPlanningComponentCheckOnBeforeUpdateDate(var ReservationEntry: Record "Reservation Entry"; PlanningComponent: Record "Planning Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssemblyHeaderCheckOnBeforeUpdateDate(var ReservationEntry: Record "Reservation Entry"; AssemblyHeader: Record "Assembly Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssemblyLineCheckOnBeforeUpdateDate(var ReservationEntry: Record "Reservation Entry"; AssemblyLine: Record "Assembly Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDateConflict(var ReservationEntry: Record "Reservation Entry"; var Date: Date; var IsConflict: Boolean; var ForceRequest: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDateConflict(var ReservationEntry: Record "Reservation Entry"; var Date: Date; var IsConflict: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransLineCheckOnBeforeUpdateDate(var ReservationEntry: Record "Reservation Entry"; TransferLine: Record "Transfer Line"; Direction: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDateFilterReservEntryLoop(var ReservationEntry: Record "Reservation Entry"; var ForceModifyShipmentDate: Boolean; Date: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesLineCheckOnBeforeIssueError(ReservationEntry: Record "Reservation Entry"; SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;
}

