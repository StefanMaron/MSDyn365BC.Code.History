page 1032 "Available - Job Planning Lines"
{
    Caption = 'Available - Job Planning Lines';
    DataCaptionExpression = CaptionText;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    Permissions = TableData "Job Planning Line" = rm;
    SourceTable = "Job Planning Line";
    SourceTableView = SORTING(Status, Type, "No.", "Variant Code", "Location Code", "Planning Date");

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Status; Status)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the status of a job order.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a document number for the planning line.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location code for the item on the job planning line.';
                }
                field("Planning Date"; "Planning Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the date of the planning line. You can use the planning date for filtering the totals of the job, for example, if you want to see the budgeted usage for a specific month of the year.';
                }
                field("Remaining Qty. (Base)"; "Remaining Qty. (Base)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the remaining quantity of the resource, item, or general ledger account that remains to complete a job, expressed in base units of measure. The quantity is calculated as the difference between Quantity and Qty. Posted.';
                }
                field("Reserved Quantity"; "Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of the item that is reserved for the job planning line.';
                }
                field(QtyToReserveBase; QtyToReserveBase)
                {
                    ApplicationArea = Reservation;
                    Caption = 'Available Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the item on the line are available for reservation.';
                }
                field(ReservedQuantity; GetReservedQtyInLine)
                {
                    ApplicationArea = Reservation;
                    Caption = 'Current Reserved Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item on the document that is currently reserved.';

                    trigger OnDrillDown()
                    begin
                        ReservEntry2.Reset();
                        SetReservationFilters(ReservEntry2);
                        ReservEntry2.SetRange("Reservation Status", ReservEntry2."Reservation Status"::Reservation);
                        ReservMgt.MarkReservConnection(ReservEntry2, ReservEntry);
                        PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry2);
                        UpdateReservFrom;
                        CurrPage.Update;
                    end;
                }
                field("Work Type Code"; "Work Type Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies which work type the resource applies to. Prices are updated based on this entry.';
                    Visible = false;
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
                    ApplicationArea = Reservation;
                    Caption = '&Reserve';
                    Image = Reserve;
                    ToolTip = 'Reserve one or more units of the item on the job planning line, either from inventory or from incoming supply.';

                    trigger OnAction()
                    begin
                        ReservEntry.LockTable();
                        UpdateReservMgt;
                        GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
                        ReservMgt.CalculateRemainingQty(NewQtyReserved, NewQtyReservedBase);
                        ReservMgt.CopySign(NewQtyReserved, QtyToReserve);
                        ReservMgt.CopySign(NewQtyReservedBase, QtyToReserveBase);
                        if NewQtyReservedBase <> 0 then
                            if Abs(NewQtyReservedBase) > Abs(QtyToReserveBase) then
                                CreateReservation(QtyToReserve, QtyToReserveBase)
                            else
                                CreateReservation(NewQtyReserved, NewQtyReservedBase)
                        else
                            Error(Text000);
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
                        if not Confirm(Text001, false) then
                            exit;

                        ReservEntry2.Copy(ReservEntry);
                        SetReservationFilters(ReservEntry2);
                        if ReservEntry2.Find('-') then begin
                            UpdateReservMgt;
                            repeat
                                ReservEngineMgt.CancelReservation(ReservEntry2);
                            until ReservEntry2.Next = 0;

                            UpdateReservFrom;
                        end;
                    end;
                }
                action(ShowDocument)
                {
                    ApplicationArea = Jobs;
                    Caption = '&Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the information on the line comes from.';

                    trigger OnAction()
                    var
                        Job: Record Job;
                    begin
                        Job.Get("Job No.");
                        PAGE.Run(PAGE::"Job Card", Job);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
    end;

    trigger OnOpenPage()
    begin
        ReservEntry.TestField("Source Type");

        SetFilters;
    end;

    var
        Text000: Label 'Fully reserved.';
        Text001: Label 'Do you want to cancel the reservation?';
        Text003: Label 'Available Quantity is %1.';
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        ReservMgt: Codeunit "Reservation Management";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        SourceRecRef: RecordRef;
        QtyToReserve: Decimal;
        QtyToReserveBase: Decimal;
        QtyReserved: Decimal;
        QtyReservedBase: Decimal;
        NewQtyReserved: Decimal;
        NewQtyReservedBase: Decimal;
        CaptionText: Text;
        CurrentSubType: Option;

    procedure SetSource(CurrentSourceRecRef: RecordRef; CurrentReservEntry: Record "Reservation Entry"; Direction: Enum "Transfer Direction")
    begin
        Clear(ReservMgt);

        SourceRecRef := CurrentSourceRecRef;
        ReservEntry := CurrentReservEntry;

        ReservMgt.TestItemType(SourceRecRef);
        ReservMgt.SetReservSource(SourceRecRef, Direction);
        CaptionText := ReservMgt.FilterReservFor(SourceRecRef, ReservEntry, Direction);
    end;

    [Obsolete('Replaced by SetSource procedure.','16.0')]
    procedure SetSalesLine(var CurrentSalesLine: Record "Sales Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentSalesLine);
        SetSource(SourceRecRef, CurrentReservEntry, 0);
    end;

    [Obsolete('Replaced by SetSource procedure.','16.0')]
    procedure SetReqLine(var CurrentReqLine: Record "Requisition Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentReqLine);
        SetSource(SourceRecRef, CurrentReservEntry, 0);
    end;

    [Obsolete('Replaced by SetSource procedure.','16.0')]
    procedure SetPurchLine(var CurrentPurchLine: Record "Purchase Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentPurchLine);
        SetSource(SourceRecRef, CurrentReservEntry, 0);
    end;

    [Obsolete('Replaced by SetSource procedure.','16.0')]
    procedure SetProdOrderLine(var CurrentProdOrderLine: Record "Prod. Order Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentProdOrderLine);
        SetSource(SourceRecRef, CurrentReservEntry, 0);
    end;

    [Obsolete('Replaced by SetSource procedure.','16.0')]
    procedure SetProdOrderComponent(var CurrentProdOrderComp: Record "Prod. Order Component"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentProdOrderComp);
        SetSource(SourceRecRef, CurrentReservEntry, 0);
    end;

    [Obsolete('Replaced by SetSource procedure.','16.0')]
    procedure SetPlanningComponent(var CurrentPlanningComponent: Record "Planning Component"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentPlanningComponent);
        SetSource(SourceRecRef, CurrentReservEntry, 0);
    end;

    [Obsolete('Replaced by SetSource procedure.','16.0')]
    procedure SetTransferLine(var CurrentTransLine: Record "Transfer Line"; CurrentReservEntry: Record "Reservation Entry"; Direction: Option Outbound,Inbound)
    begin
        SourceRecRef.GetTable(CurrentTransLine);
        SetSource(SourceRecRef, CurrentReservEntry, Direction);
    end;

    [Obsolete('Replaced by SetSource procedure.','16.0')]
    procedure SetServLine(var CurrentServiceLine: Record "Service Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentServiceLine);
        SetSource(SourceRecRef, CurrentReservEntry, 0);
    end;

    [Obsolete('Replaced by SetSource procedure.','16.0')]
    procedure SetJobPlanningLine(var CurrentJobPlanningLine: Record "Job Planning Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentJobPlanningLine);
        SetSource(SourceRecRef, CurrentReservEntry, 0);
    end;

    local procedure CreateReservation(ReserveQuantity: Decimal; ReserveQuantityBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
    begin
        CalcFields("Reserved Qty. (Base)");
        if Abs("Remaining Qty. (Base)") + "Reserved Qty. (Base)" < ReserveQuantityBase then
            Error(Text003, Abs("Remaining Qty. (Base)") + "Reserved Quantity");

        TestField("No.", ReservEntry."Item No.");
        TestField("Variant Code", ReservEntry."Variant Code");
        TestField("Location Code", ReservEntry."Location Code");

        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Job Planning Line", Status, "Job No.", '', 0, "Job Contract Entry No.",
          "Variant Code", "Location Code", "Qty. per Unit of Measure");
        ReservMgt.CreateReservation(
          ReservEntry.Description, "Planning Date", ReserveQuantity, ReserveQuantityBase, TrackingSpecification);
        UpdateReservFrom;
    end;

    local procedure UpdateReservFrom()
    begin
        SetSource(SourceRecRef, ReservEntry, ReservEntry."Source Subtype");

        OnAfterUpdateReservFrom(ReservEntry);
    end;

    local procedure UpdateReservMgt()
    begin
        Clear(ReservMgt);
        ReservMgt.SetReservSource(SourceRecRef, ReservEntry."Source Subtype");

        OnAfterUpdateReservMgt(ReservEntry);
    end;

    local procedure GetReservedQtyInLine(): Decimal
    begin
        ReservEntry2.Reset();
        SetReservationFilters(ReservEntry2);
        ReservEntry2.SetRange("Reservation Status", ReservEntry2."Reservation Status"::Reservation);
        exit(ReservMgt.MarkReservConnection(ReservEntry2, ReservEntry));
    end;

    procedure SetCurrentSubType(SubType: Option)
    begin
        CurrentSubType := SubType;
    end;

    [Obsolete('Replaced by SetSource procedure.','16.0')]
    procedure SetAssemblyLine(var CurrentAssemblyLine: Record "Assembly Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentAssemblyLine);
        SetSource(SourceRecRef, CurrentReservEntry, 0);
    end;

    [Obsolete('Replaced by SetSource procedure.','16.0')]
    procedure SetAssemblyHeader(var CurrentAssemblyHeader: Record "Assembly Header"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentAssemblyHeader);
        SetSource(SourceRecRef, CurrentReservEntry, 0);
    end;

    local procedure SetFilters()
    begin
        SetRange(Status, CurrentSubType);
        SetRange(Type, Type::Item);
        SetRange("No.", ReservEntry."Item No.");
        SetRange("Variant Code", ReservEntry."Variant Code");
        SetRange("Location Code", ReservEntry."Location Code");

        SetFilter("Planning Date", ReservMgt.GetAvailabilityFilter(ReservEntry."Shipment Date"));

        case CurrentSubType of
            0, 1, 2, 4:
                if ReservMgt.IsPositive then
                    SetFilter("Quantity (Base)", '<0')
                else
                    SetFilter("Quantity (Base)", '>0');
            3, 5:
                if not ReservMgt.IsPositive then
                    SetFilter("Quantity (Base)", '<0')
                else
                    SetFilter("Quantity (Base)", '>0');
        end;

        OnAfterSetFilters(Rec, ReservEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilters(var JobPlanningLine: Record "Job Planning Line"; ReservationEntry: Record "Reservation Entry")
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

