namespace Microsoft.Inventory.Tracking;

using Microsoft.Assembly.Document;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Document;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

codeunit 99000815 "Reservation-Check Date Confl."
{

    trigger OnRun()
    begin
    end;

    var
        ReservationEntry: Record "Reservation Entry";
        ReservationEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReservMgt: Codeunit "Reservation Management";
        DateConflictMsg: Label 'The change causes a date conflict with an existing reservation on %2 for %1 units.\ \The reservations have been canceled. The production order must be replanned.', Comment = '%1: Field(Reserved Quantity (Base)), %2: Field(Due Date)';
        DateConflictErr: Label 'The change leads to a date conflict with existing reservations.\Reserved quantity (Base): %1, Date %2\Cancel or change reservations and try again.', Comment = '%1 - reserved quantity, %2 - date';

    procedure SalesLineCheck(SalesLine: Record "Sales Line"; ForceRequest: Boolean)
    var
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        IsHandled: Boolean;
    begin
        if not SalesLineReserve.FindReservEntry(SalesLine, ReservationEntry) then
            exit;

        IsHandled := false;
        OnSalesLineCheckOnBeforeIssueError(ReservationEntry, SalesLine, IsHandled, ForceRequest);
        if not IsHandled then
            if DateConflict(SalesLine."Shipment Date", ForceRequest, ReservationEntry) then
                if ForceRequest then
                    IssueError(SalesLine."Shipment Date");

        IsHandled := false;
        OnSalesLineCheckOnBeforeUpdateDate(ReservationEntry, SalesLine, IsHandled);
        if not IsHandled then
            UpdateDate(ReservationEntry, SalesLine."Shipment Date");

        ReservMgt.SetReservSource(SalesLine);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(SalesLine."Outstanding Qty. (Base)");
    end;

    procedure PurchLineCheck(PurchaseLine: Record "Purchase Line"; ForceRequest: Boolean)
    var
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
        IsHandled: Boolean;
    begin
        if not PurchLineReserve.FindReservEntry(PurchaseLine, ReservationEntry) then
            exit;

        IsHandled := false;
        OnPurchLineCheckOnBeforeIssueError(ReservationEntry, PurchaseLine, ForceRequest, IsHandled);
        if not IsHandled then
            if DateConflict(PurchaseLine."Expected Receipt Date", ForceRequest, ReservationEntry) then
                if ForceRequest then
                    IssueError(PurchaseLine."Expected Receipt Date");

        IsHandled := false;
        OnPurchLineCheckOnBeforeUpdateDate(ReservationEntry, PurchaseLine, IsHandled);
        if not IsHandled then
            UpdateDate(ReservationEntry, PurchaseLine."Expected Receipt Date");

        ReservMgt.SetReservSource(PurchaseLine);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(PurchaseLine."Outstanding Qty. (Base)");
    end;

    procedure ItemJnlLineCheck(ItemJournalLine: Record "Item Journal Line"; ForceRequest: Boolean)
    var
        ItemJnlLineReserve: Codeunit "Item Jnl. Line-Reserve";
        IsHandled: Boolean;
    begin
        if not ItemJnlLineReserve.FindReservEntry(ItemJournalLine, ReservationEntry) then
            exit;

        IsHandled := false;
        OnItemJnlLineCheckOnBeforeIssueError(ReservationEntry, ItemJournalLine, ForceRequest, IsHandled);
        if not IsHandled then
            if DateConflict(ItemJournalLine."Posting Date", ForceRequest, ReservationEntry) then
                if ForceRequest then
                    IssueError(ItemJournalLine."Posting Date");

        IsHandled := false;
        OnItemJnlLineCheckOnBeforeUpdateDate(ReservationEntry, ItemJournalLine, IsHandled);
        if not IsHandled then
            UpdateDate(ReservationEntry, ItemJournalLine."Posting Date");

        ReservMgt.SetReservSource(ItemJournalLine);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(ItemJournalLine."Quantity (Base)");
    end;

    procedure ReqLineCheck(RequisitionLine: Record "Requisition Line"; ForceRequest: Boolean)
    var
        ReqLineReserve: Codeunit "Req. Line-Reserve";
        IsHandled: Boolean;
    begin
        if not ReqLineReserve.FindReservEntry(RequisitionLine, ReservationEntry) then
            exit;

        IsHandled := false;
        OnReqLineCheckOnBeforeIssueError(ReservationEntry, RequisitionLine, ForceRequest, IsHandled);
        if not IsHandled then
            if DateConflict(RequisitionLine."Due Date", ForceRequest, ReservationEntry) then
                if ForceRequest then
                    IssueError(RequisitionLine."Due Date");

        IsHandled := false;
        OnReqLineCheckOnBeforeUpdateDate(ReservationEntry, RequisitionLine, IsHandled);
        if not IsHandled then
            UpdateDate(ReservationEntry, RequisitionLine."Due Date");

        ReservMgt.SetReservSource(RequisitionLine);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(RequisitionLine."Quantity (Base)");
    end;

    procedure ProdOrderLineCheck(ProdOrderLine: Record "Prod. Order Line"; ForceRequest: Boolean)
    var
        ProdOrderLineReserve: Codeunit "Prod. Order Line-Reserve";
        IsHandled: Boolean;
    begin
        if not ProdOrderLineReserve.FindReservEntry(ProdOrderLine, ReservationEntry) then
            exit;

        CheckProdOrderLineDateConflict(ProdOrderLine, ForceRequest);

        IsHandled := false;
        OnProdOrderLineCheckOnBeforeUpdateDate(ReservationEntry, ProdOrderLine, IsHandled);
        if not IsHandled then
            UpdateDate(ReservationEntry, ProdOrderLine."Due Date");

        ReservMgt.SetReservSource(ProdOrderLine);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(ProdOrderLine."Remaining Qty. (Base)");
    end;

    local procedure CheckProdOrderLineDateConflict(ProdOrderLine: Record "Prod. Order Line"; ForceRequest: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckProdOrderLineDateConflict(ProdOrderLine."Due Date", ForceRequest, ReservationEntry, IsHandled);
        if IsHandled then
            exit;

        if DateConflict(ProdOrderLine."Due Date", ForceRequest, ReservationEntry) then
            if ForceRequest then
                IssueError(ProdOrderLine."Due Date");
    end;

    procedure ProdOrderComponentCheck(ProdOrderComponent: Record "Prod. Order Component"; ForceRequest: Boolean; IsCritical: Boolean): Boolean
    var
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
        IsHandled: Boolean;
    begin
        if not ProdOrderCompReserve.FindReservEntry(ProdOrderComponent, ReservationEntry) then
            exit(false);

        IsHandled := false;
        OnProdOrderComponentCheckOnBeforeIssueError(ReservationEntry, ProdOrderComponent, ForceRequest, IsHandled);
        if not IsHandled then
            if DateConflict(ProdOrderComponent."Due Date", ForceRequest, ReservationEntry) then
                if ForceRequest then
                    if IsCritical then
                        IssueError(ProdOrderComponent."Due Date")
                    else
                        IssueWarning(ProdOrderComponent."Due Date");

        IsHandled := false;
        OnProdOrderComponentCheckOnBeforeUpdateDate(ReservationEntry, ProdOrderComponent, IsHandled);
        if not IsHandled then
            UpdateDate(ReservationEntry, ProdOrderComponent."Due Date");

        ReservMgt.SetReservSource(ProdOrderComponent);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(ProdOrderComponent."Remaining Qty. (Base)");
        exit(ForceRequest);
    end;

    procedure AssemblyHeaderCheck(AssemblyHeader: Record "Assembly Header"; ForceRequest: Boolean)
    var
        AssemblyHeaderReserve: Codeunit "Assembly Header-Reserve";
        IsHandled: Boolean;
    begin
        if not AssemblyHeaderReserve.FindReservEntry(AssemblyHeader, ReservationEntry) then
            exit;

        IsHandled := false;
        OnAssemblyHeaderCheckOnBeforeIssueError(ReservationEntry, AssemblyHeader, ForceRequest, IsHandled);
        if not IsHandled then
            if DateConflict(AssemblyHeader."Due Date", ForceRequest, ReservationEntry) then
                if ForceRequest then
                    IssueError(AssemblyHeader."Due Date");

        IsHandled := false;
        OnAssemblyHeaderCheckOnBeforeUpdateDate(ReservationEntry, AssemblyHeader, IsHandled);
        if not IsHandled then
            UpdateDate(ReservationEntry, AssemblyHeader."Due Date");

        ReservMgt.SetReservSource(AssemblyHeader);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(AssemblyHeader."Remaining Quantity (Base)");
    end;

    procedure AssemblyLineCheck(AssemblyLine: Record "Assembly Line"; ForceRequest: Boolean)
    var
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
        IsHandled: Boolean;
    begin
        if not AssemblyLineReserve.FindReservEntry(AssemblyLine, ReservationEntry) then
            exit;

        if DateConflict(AssemblyLine."Due Date", ForceRequest, ReservationEntry) then
            if ForceRequest then
                IssueError(AssemblyLine."Due Date");

        IsHandled := false;
        OnAssemblyLineCheckOnBeforeUpdateDate(ReservationEntry, AssemblyLine, IsHandled);
        if not IsHandled then
            UpdateDate(ReservationEntry, AssemblyLine."Due Date");

        ReservMgt.SetReservSource(AssemblyLine);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(AssemblyLine."Remaining Quantity (Base)");
    end;

    procedure PlanningComponentCheck(PlanningComponent: Record "Planning Component"; ForceRequest: Boolean)
    var
        PlngComponentReserve: Codeunit "Plng. Component-Reserve";
        IsHandled: Boolean;
    begin
        if not PlngComponentReserve.FindReservEntry(PlanningComponent, ReservationEntry) then
            exit;

        IsHandled := false;
        OnPlanningComponentCheckOnBeforeIssueError(ReservationEntry, PlanningComponent, ForceRequest, IsHandled);
        if not IsHandled then
            if DateConflict(PlanningComponent."Due Date", ForceRequest, ReservationEntry) then
                if ForceRequest then
                    IssueError(PlanningComponent."Due Date");

        IsHandled := false;
        OnPlanningComponentCheckOnBeforeUpdateDate(ReservationEntry, PlanningComponent, IsHandled);
        if not IsHandled then
            UpdateDate(ReservationEntry, PlanningComponent."Due Date");

        ReservMgt.SetReservSource(PlanningComponent);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(PlanningComponent."Net Quantity (Base)");
    end;

    procedure TransferLineCheck(TransferLine: Record "Transfer Line")
    var
        TransferLineReserve: Codeunit "Transfer Line-Reserve";
        ResEntryFound: Boolean;
        ForceRequest: Boolean;
        Direction: Enum "Transfer Direction";
        IsHandled: Boolean;
    begin
        if TransferLineReserve.FindReservEntry(TransferLine, ReservationEntry, Direction::Outbound) then begin
            ResEntryFound := true;
            ForceRequest := true;

            IsHandled := false;
            OnTransferLineCheckOutboundOnBeforeIssueError(ReservationEntry, TransferLine, ForceRequest, IsHandled);
            if not IsHandled then
                if DateConflict(TransferLine."Shipment Date", ForceRequest, ReservationEntry) then
                    if ForceRequest then
                        IssueError(TransferLine."Shipment Date");

            IsHandled := false;
            OnTransLineCheckOnBeforeUpdateDate(ReservationEntry, TransferLine, Direction.AsInteger(), IsHandled);
            if not IsHandled then
                UpdateDate(ReservationEntry, TransferLine."Shipment Date");
        end;

        if TransferLineReserve.FindInboundReservEntry(TransferLine, ReservationEntry) then begin
            ResEntryFound := true;
            ForceRequest := true;

            IsHandled := false;
            OnTransferLineCheckInboundOnBeforeIssueError(ReservationEntry, TransferLine, ForceRequest, IsHandled);
            if not IsHandled then
                if DateConflict(TransferLine."Receipt Date", ForceRequest, ReservationEntry) then
                    if ForceRequest then
                        IssueError(TransferLine."Receipt Date");

            IsHandled := false;
            OnTransLineCheckOnBeforeUpdateDate(ReservationEntry, TransferLine, Direction.AsInteger(), IsHandled);
            if not IsHandled then
                UpdateDate(ReservationEntry, TransferLine."Receipt Date");
        end;

        if not ResEntryFound then
            exit;

        ReservMgt.SetReservSource(TransferLine, Direction);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(TransferLine."Outstanding Qty. (Base)");
    end;

#if not CLEAN25
    [Obsolete('Moved to codeunit ServiceLineReserve', '25.0')]
    procedure ServiceInvLineCheck(ServiceLine: Record Microsoft.Service.Document."Service Line"; ForceRequest: Boolean)
        ServiceLineReserve: Codeunit Microsoft.Service.Document."Service Line-Reserve";
    begin
        ServiceLineReserve.ServiceInvLineCheck(ServiceLine, ForceRequest)
    end;
#endif

    procedure JobPlanningLineCheck(JobPlanningLine: Record "Job Planning Line"; ForceRequest: Boolean)
    var
        JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
    begin
        if not JobPlanningLineReserve.FindReservEntry(JobPlanningLine, ReservationEntry) then
            exit;
        if DateConflict(JobPlanningLine."Planning Date", ForceRequest, ReservationEntry) then
            if ForceRequest then
                IssueError(JobPlanningLine."Planning Date");
        UpdateDate(ReservationEntry, JobPlanningLine."Planning Date");
        ReservMgt.SetReservSource(JobPlanningLine);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(JobPlanningLine."Remaining Qty. (Base)");
    end;

    procedure InvtDocLineCheck(InvtDocumentLine: Record "Invt. Document Line"; ForceRequest: Boolean): Boolean
    var
        InvtDocLineReserve: Codeunit "Invt. Doc. Line-Reserve";
    begin
        if not InvtDocLineReserve.FindReservEntry(InvtDocumentLine, ReservationEntry) then
            exit;

        if DateConflict(InvtDocumentLine."Document Date", ForceRequest, ReservationEntry) then
            if ForceRequest then IssueError(InvtDocumentLine."Document Date");
        UpdateDate(ReservationEntry, InvtDocumentLine."Document Date");
        ReservMgt.SetReservSource(InvtDocumentLine);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(InvtDocumentLine."Quantity (Base)");
    end;

    procedure UpdateDate(var FilterReservationEntry: Record "Reservation Entry"; Date: Date)
    var
        ForceModifyShipmentDate: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateDate(FilterReservationEntry, Date, IsHandled);
        if IsHandled then
            exit;

        FilterReservationEntry.SetRange("Reservation Status");
        if not FilterReservationEntry.Find('-') then
            exit;

        repeat
            OnUpdateDateFilterReservEntryLoop(FilterReservationEntry, ForceModifyShipmentDate, Date);
            if FilterReservationEntry."Quantity (Base)" < 0 then
                if (FilterReservationEntry."Expected Receipt Date" <> 0D) and
                   (Date < FilterReservationEntry."Expected Receipt Date") and not ForceModifyShipmentDate
                then
                    if (FilterReservationEntry.Binding <> FilterReservationEntry.Binding::"Order-to-Order") and
                       FilterReservationEntry.TrackingExists()
                    then
                        ReservationEngineMgt.SplitTrackingConnection(FilterReservationEntry, Date)
                    else
                        if SameProdOrderAutoReserve(FilterReservationEntry) then
                            ReservationEngineMgt.ModifyExpectedReceiptDate(FilterReservationEntry, Date)
                        else
                            ReservationEngineMgt.CloseReservEntry(FilterReservationEntry, false, false)
                else
                    ReservationEngineMgt.ModifyShipmentDate(FilterReservationEntry, Date)
            else
                if ((FilterReservationEntry."Shipment Date" <> 0D) and
                    (FilterReservationEntry."Shipment Date" < Date))
                then
                    if (FilterReservationEntry.Binding <> FilterReservationEntry.Binding::"Order-to-Order") and
                       FilterReservationEntry.TrackingExists()
                    then
                        ReservationEngineMgt.SplitTrackingConnection(FilterReservationEntry, Date)
                    else
                        ReservationEngineMgt.CloseReservEntry(FilterReservationEntry, false, false)
                else
                    ReservationEngineMgt.ModifyExpectedReceiptDate(FilterReservationEntry, Date);
        until FilterReservationEntry.Next() = 0;
    end;

    procedure DateConflict(Date: Date; var ForceRequest: Boolean; var ReservationEntry1: Record "Reservation Entry") IsConflict: Boolean
    var
        ReservationEntry2: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDateConflict(ReservationEntry1, Date, IsConflict, IsHandled);
        if IsHandled then
            exit;

        ReservationEntry2.Copy(ReservationEntry1);

        if not ReservationEntry2.FindFirst() then
            exit(false);

        if ReservationEntry2."Quantity (Base)" < 0 then
            ReservationEntry2.SetFilter("Expected Receipt Date", '>%1', Date)
        else
            if Date <> 0D then
                ReservationEntry2.SetRange("Shipment Date", 00000101D, Date - 1);

        if ReservationEntry2.IsEmpty() then
            exit(false);

        IsConflict := true;

        // Don't look at tracking and surplus:
        ReservationEntry2.SetRange("Reservation Status", ReservationEntry2."Reservation Status"::Reservation);

        ForceRequest := not ReservationEntry2.IsEmpty() and ForceRequest;

        OnAfterDateConflict(ReservationEntry1, Date, IsConflict, ForceRequest);
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
        ReservationEntry2: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservDueDate: Date;
        ReservExpectDate: Date;
        SumValue: Decimal;
    begin
        ReservationEntry2.Copy(ReservationEntry);
        ReservDueDate := NewDate;
        ReservExpectDate := NewDate;

        if not ReservationEntry2.Find('-') then
            exit(0);
        if ReservationEntry2."Quantity (Base)" < 0 then
            ReservExpectDate := 0D
        else
            ReservDueDate := DMY2Date(31, 12, 9999);

        repeat
            SumValue += ReservationEntry2."Quantity (Base)";
            if ReservationEntry2."Quantity (Base)" < 0 then begin
                if ReservationEntry2."Expected Receipt Date" <> 0D then  // Item ledger entries will be 0D.
                    if (ReservationEntry2."Expected Receipt Date" > ReservExpectDate) and
                       (ReservationEntry2."Expected Receipt Date" > ReservDueDate)
                    then
                        ReservExpectDate := ReservationEntry2."Expected Receipt Date";
            end else
                if ReservationEntry2."Shipment Date" <> 0D then          // Item ledger entries will be 0D.
                    if (ReservationEntry2."Shipment Date" < ReservDueDate) and (ReservationEntry2."Shipment Date" < ReservExpectDate) then
                        ReservDueDate := ReservationEntry2."Shipment Date";
        until ReservationEntry2.Next() = 0;

        exit(CreateReservEntry.SignFactor(ReservationEntry2) * SumValue);
    end;

    local procedure SameProdOrderAutoReserve(FilterReservationEntry: Record "Reservation Entry"): Boolean
    var
        ProdOrderLineReservationEntry: Record "Reservation Entry";
    begin
        if FilterReservationEntry."Source Type" = Database::"Prod. Order Component" then
            if ProdOrderLineReservationEntry.Get(FilterReservationEntry."Entry No.", not FilterReservationEntry.Positive) then
                if ProdOrderLineReservationEntry."Source Type" = Database::"Prod. Order Line" then
                    if FilterReservationEntry."Source ID" = ProdOrderLineReservationEntry."Source ID" then
                        exit(ProdOrderLineReservationEntry."Source Prod. Order Line" = GetSuppliedByLineNoByReservationEntry(FilterReservationEntry));
        exit(false);
    end;

    local procedure GetSuppliedByLineNoByReservationEntry(ReservationEntry2: Record "Reservation Entry"): Integer
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.Get(
            ReservationEntry2."Source Subtype", ReservationEntry2."Source ID", ReservationEntry2."Source Prod. Order Line", ReservationEntry2."Source Ref. No.");
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
    local procedure OnSalesLineCheckOnBeforeIssueError(ReservationEntry: Record "Reservation Entry"; SalesLine: Record "Sales Line"; var IsHandled: Boolean; var ForceRequest: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchLineCheckOnBeforeIssueError(var ReservationEntry: Record "Reservation Entry"; PurchaseLine: Record "Purchase Line"; var ForceRequest: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReqLineCheckOnBeforeIssueError(var ReservationEntry: Record "Reservation Entry"; RequisitionLine: Record "Requisition Line"; var ForceRequest: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProdOrderComponentCheckOnBeforeIssueError(var ReservationEntry: Record "Reservation Entry"; ProdOrderComponent: Record "Prod. Order Component"; var ForceRequest: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemJnlLineCheckOnBeforeIssueError(var ReservationEntry: Record "Reservation Entry"; ItemJournalLine: Record "Item Journal Line"; var ForceRequest: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssemblyHeaderCheckOnBeforeIssueError(var ReservationEntry: Record "Reservation Entry"; AssemblyHeader: Record "Assembly Header"; var ForceRequest: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferLineCheckOutboundOnBeforeIssueError(var ReservationEntry: Record "Reservation Entry"; TransferLine: Record "Transfer Line"; var ForceRequest: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferLineCheckInboundOnBeforeIssueError(var ReservationEntry: Record "Reservation Entry"; TransferLine: Record "Transfer Line"; var ForceRequest: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPlanningComponentCheckOnBeforeIssueError(var ReservationEntry: Record "Reservation Entry"; PlanningComponent: Record "Planning Component"; var ForceRequest: Boolean; var IsHandled: Boolean)
    begin
    end;

}

