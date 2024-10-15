page 12466 "Available - Item Doc. Lines"
{
    Caption = 'Available - Item Doc. Lines';
    DataCaptionExpression = CaptionText;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
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
                        ReservEntry2.Reset();
                        SetReservationFilters(ReservEntry2);
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
                        ReservEntry.LockTable();
                        UpdateReservMgt;
                        GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase, "Document Type");
                        ReservMgt.CalculateRemainingQty(NewQtyReserved, NewQtyReservedBase);
                        ReservMgt.CopySign(NewQtyReservedBase, QtyToReserveBase);
                        ReservMgt.CopySign(NewQtyReserved, QtyToReserve);
                        if NewQtyReservedBase <> 0 then
                            if Abs(NewQtyReservedBase) > Abs(QtyToReserveBase) then
                                CreateReservation(QtyToReserve, QtyToReserveBase)
                            else
                                CreateReservation(NewQtyReserved, NewQtyReservedBase)
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
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase, "Document Type");
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
        Direction: Option Outbound,Inbound;

    procedure SetSource(CurrentSourceRecRef: RecordRef; CurrentReservEntry: Record "Reservation Entry"; Direction: Option)
    begin
        Clear(ReservMgt);

        SourceRecRef := CurrentSourceRecRef;
        ReservEntry := CurrentReservEntry;

        ReservMgt.TestItemType(SourceRecRef);
        ReservMgt.SetReservSource(SourceRecRef, "Transfer Direction".FromInteger(Direction));
        CaptionText := ReservMgt.FilterReservFor(SourceRecRef, ReservEntry, "Transfer Direction".FromInteger(Direction));

        SetInbound(ReservMgt.IsPositive);
    end;

    [Obsolete('Replaced by SetSource procedure.', '16.0')]
    procedure SetSalesLine(var CurrentSalesLine: Record "Sales Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentSalesLine);
        SetSource(SourceRecRef, CurrentReservEntry, 0);
    end;

    [Obsolete('Replaced by SetSource procedure.', '16.0')]
    procedure SetReqLine(var CurrentReqLine: Record "Requisition Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentReqLine);
        SetSource(SourceRecRef, CurrentReservEntry, 0);
    end;

    [Obsolete('Replaced by SetSource procedure.', '16.0')]
    procedure SetPurchLine(var CurrentPurchLine: Record "Purchase Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentPurchLine);
        SetSource(SourceRecRef, CurrentReservEntry, 0);
    end;

    [Obsolete('Replaced by SetSource procedure.', '16.0')]
    procedure SetProdOrderLine(var CurrentProdOrderLine: Record "Prod. Order Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentProdOrderLine);
        SetSource(SourceRecRef, CurrentReservEntry, 0);
    end;

    [Obsolete('Replaced by SetSource procedure.', '16.0')]
    procedure SetProdOrderComponent(var CurrentProdOrderComp: Record "Prod. Order Component"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentProdOrderComp);
        SetSource(SourceRecRef, CurrentReservEntry, 0);
    end;

    [Obsolete('Replaced by SetSource procedure.', '16.0')]
    procedure SetPlanningComponent(var CurrentPlanningComponent: Record "Planning Component"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentPlanningComponent);
        SetSource(SourceRecRef, CurrentReservEntry, 0);
    end;

    [Obsolete('Replaced by SetSource procedure.', '16.0')]
    procedure SetTransferLine(var CurrentTransLine: Record "Transfer Line"; CurrentReservEntry: Record "Reservation Entry"; Direction: Option Outbound,Inbound)
    begin
        SourceRecRef.GetTable(CurrentTransLine);
        SetSource(SourceRecRef, CurrentReservEntry, Direction);
    end;

    [Obsolete('Replaced by SetSource procedure.', '16.0')]
    procedure SetServiceInvLine(var CurrentServiceLine: Record "Service Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentServiceLine);
        SetSource(SourceRecRef, CurrentReservEntry, 0);
    end;

    [Obsolete('Replaced by SetSource procedure.', '16.0')]
    procedure SetJobPlanningLine(var CurrentJobPlanningLine: Record "Job Planning Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentJobPlanningLine);
        SetSource(SourceRecRef, CurrentReservEntry, 0);
    end;

    [Obsolete('Replaced by SetSource procedure.', '16.0')]
    procedure SetItemDocLine(var CurrentItemDocLine: Record "Item Document Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentItemDocLine);
        SetSource(SourceRecRef, CurrentReservEntry, 0);
    end;

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

    local procedure UpdateReservFrom()
    begin
        SetSource(SourceRecRef, ReservEntry, ReservEntry."Source Subtype");
    end;

    local procedure UpdateReservMgt()
    begin
        Clear(ReservMgt);
        ReservMgt.SetReservSource(SourceRecRef, "Transfer Direction".FromInteger(ReservEntry."Source Subtype"));
    end;

    local procedure GetReservedQtyInLine(): Decimal
    begin
        ReservEntry2.Reset();
        SetReservationFilters(ReservEntry2);
        ReservEntry2.SetRange("Reservation Status", ReservEntry2."Reservation Status"::Reservation);
        exit(ReservMgt.MarkReservConnection(ReservEntry2, ReservEntry));
    end;

    procedure SetInbound(DirectionIsInbound: Boolean)
    begin
        if DirectionIsInbound then
            Direction := Direction::Inbound
        else
            Direction := Direction::Outbound;
    end;

    procedure SetAssemblyLine(var CurrentAssemblyLine: Record "Assembly Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentAssemblyLine);
        SetSource(SourceRecRef, CurrentReservEntry, 0);
    end;

    procedure SetAssemblyHeader(var CurrentAssemblyHeader: Record "Assembly Header"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentAssemblyHeader);
        SetSource(SourceRecRef, CurrentReservEntry, 0);
    end;
}

