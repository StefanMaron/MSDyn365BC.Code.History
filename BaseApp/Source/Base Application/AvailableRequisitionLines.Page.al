page 500 "Available - Requisition Lines"
{
    Caption = 'Available - Requisition Lines';
    DataCaptionExpression = CaptionText;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    Permissions = TableData "Requisition Line" = rm;
    SourceTable = "Requisition Line";
    SourceTableView = SORTING(Type, "No.", "Variant Code", "Location Code", "Sales Order No.", "Planning Line Origin", "Due Date");

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
                    ToolTip = 'Specifies a code for an inventory location where the items that are being ordered will be registered.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when you can expect to receive the items.';
                }
                field("Quantity (Base)"; "Quantity (Base)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that when the quantity field is updated, this field is updated.';
                }
                field("Reserved Qty. (Base)"; "Reserved Qty. (Base)")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies that when the reserved quantity field is updated, this field is updated.';
                }
                field(QtyToReserveBase; QtyToReserveBase)
                {
                    ApplicationArea = Reservation;
                    Caption = 'Available Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of the item that is available for reservation.';
                }
                field(ReservedQuantity; GetReservedQtyInLine)
                {
                    ApplicationArea = Reservation;
                    Caption = 'Current Reserved Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item that is reserved from the requisition line, for the current line or entry.';

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
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions();
                        CurrPage.SaveRecord;
                    end;
                }
            }
        }
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
                action("&Cancel Reservation")
                {
                    AccessByPermission = TableData Item = R;
                    ApplicationArea = Reservation;
                    Caption = '&Cancel Reservation';
                    Image = Cancel;
                    ToolTip = 'Cancel the reservation that exists for the document line that you opened this window for.';

                    trigger OnAction()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if not ConfirmManagement.GetResponseOrDefault(Text001, true) then
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
                action("&Show Entire Worksheet")
                {
                    ApplicationArea = Planning;
                    Caption = '&Show Entire Worksheet';
                    Image = Worksheet;
                    ToolTip = 'Open the requisition worksheet that the view is based on.';

                    trigger OnAction()
                    var
                        ReqWkshTemplate: Record "Req. Wksh. Template";
                        ReqLine2: Record "Requisition Line";
                    begin
                        ReqWkshTemplate.Get("Worksheet Template Name");
                        ReqLine2 := Rec;
                        ReqLine2.FilterGroup(2);
                        ReqLine2.SetRange("Worksheet Template Name", "Worksheet Template Name");
                        ReqLine2.SetRange("Journal Batch Name", "Journal Batch Name");
                        ReqLine2.FilterGroup(0);
                        PAGE.Run(ReqWkshTemplate."Page ID", ReqLine2);
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

    procedure SetSource(CurrentSourceRecRef: RecordRef; CurrentReservEntry: Record "Reservation Entry")
    var
        TransferDirection: Enum "Transfer Direction";
    begin
        SetSource(CurrentSourceRecRef, CurrentReservEntry, TransferDirection::Outbound);
    end;

    procedure SetSource(CurrentSourceRecRef: RecordRef; CurrentReservEntry: Record "Reservation Entry"; Direction: Enum "Transfer Direction")
    begin
        Clear(ReservMgt);

        SourceRecRef := CurrentSourceRecRef;
        ReservEntry := CurrentReservEntry;

        ReservMgt.TestItemType(SourceRecRef);
        ReservMgt.SetReservSource(SourceRecRef, Direction);
        CaptionText := ReservMgt.FilterReservFor(SourceRecRef, ReservEntry, Direction);
    end;

    procedure SetSalesLine(var CurrentSalesLine: Record "Sales Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentSalesLine);
        SetSource(SourceRecRef, CurrentReservEntry);
    end;

    procedure SetReqLine(var CurrentReqLine: Record "Requisition Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentReqLine);
        SetSource(SourceRecRef, CurrentReservEntry);
    end;

    procedure SetPurchLine(var CurrentPurchLine: Record "Purchase Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentPurchLine);
        SetSource(SourceRecRef, CurrentReservEntry);
    end;

    procedure SetProdOrderLine(var CurrentProdOrderLine: Record "Prod. Order Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentProdOrderLine);
        SetSource(SourceRecRef, CurrentReservEntry);
    end;

    procedure SetProdOrderComponent(var CurrentProdOrderComp: Record "Prod. Order Component"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentProdOrderComp);
        SetSource(SourceRecRef, CurrentReservEntry);
    end;

    procedure SetPlanningComponent(var CurrentPlanningComponent: Record "Planning Component"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentPlanningComponent);
        SetSource(SourceRecRef, CurrentReservEntry);
    end;

    procedure SetTransferLine(var CurrentTransLine: Record "Transfer Line"; CurrentReservEntry: Record "Reservation Entry"; Direction: Enum "Transfer Direction")
    begin
        SourceRecRef.GetTable(CurrentTransLine);
        SetSource(SourceRecRef, CurrentReservEntry, Direction);
    end;

    procedure SetServiceInvLine(var CurrentServiceLine: Record "Service Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentServiceLine);
        SetSource(SourceRecRef, CurrentReservEntry);
    end;

    procedure SetJobPlanningLine(var CurrentJobPlanningLine: Record "Job Planning Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentJobPlanningLine);
        SetSource(SourceRecRef, CurrentReservEntry);
    end;

    [Obsolete('Replaced by SetSource procedure.', '16.0')]
    procedure SetItemDocLine(var CurrentItemDocLine: Record "Item Document Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentItemDocLine);
        SetSource(SourceRecRef, CurrentReservEntry, "Transfer Direction"::Outbound);
    end;

    local procedure CreateReservation(ReserveQuantity: Decimal; ReserveQuantityBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
    begin
        CalcFields("Reserved Qty. (Base)");
        if "Quantity (Base)" - "Reserved Qty. (Base)" < ReserveQuantityBase then
            Error(Text003, "Quantity (Base)" + "Reserved Qty. (Base)");

        TestField("No.", ReservEntry."Item No.");
        TestField("Variant Code", ReservEntry."Variant Code");
        TestField("Location Code", ReservEntry."Location Code");

        UpdateReservMgt;
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Requisition Line", 0, "Worksheet Template Name", "Journal Batch Name", 0, "Line No.",
          "Variant Code", "Location Code", "Qty. per Unit of Measure");
        ReservMgt.CreateReservation(
          ReservEntry.Description, "Due Date", ReserveQuantity, ReserveQuantityBase, TrackingSpecification);
        UpdateReservFrom;
    end;

    local procedure UpdateReservFrom()
    begin
        SetSource(SourceRecRef, ReservEntry, ReservEntry.GetTransferDirection());

        OnAfterUpdateReservFrom(ReservEntry);
    end;

    local procedure UpdateReservMgt()
    begin
        Clear(ReservMgt);
        ReservMgt.SetReservSource(SourceRecRef, ReservEntry.GetTransferDirection());

        OnAfterUpdateReservMgt(ReservEntry);
    end;

    local procedure GetReservedQtyInLine(): Decimal
    begin
        ReservEntry2.Reset();
        SetReservationFilters(ReservEntry2);
        ReservEntry2.SetRange("Reservation Status", ReservEntry2."Reservation Status"::Reservation);
        exit(ReservMgt.MarkReservConnection(ReservEntry2, ReservEntry));
    end;

    procedure SetAssemblyLine(var CurrentAssemblyLine: Record "Assembly Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentAssemblyLine);
        SetSource(SourceRecRef, CurrentReservEntry);
    end;

    procedure SetAssemblyHeader(var CurrentAssemblyHeader: Record "Assembly Header"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentAssemblyHeader);
        SetSource(SourceRecRef, CurrentReservEntry);
    end;

    local procedure SetFilters()
    begin
        SetRange(Type, Type::Item);
        SetRange("No.", ReservEntry."Item No.");
        SetRange("Variant Code", ReservEntry."Variant Code");
        SetRange("Location Code", ReservEntry."Location Code");

        SetFilter("Due Date", ReservMgt.GetAvailabilityFilter(ReservEntry."Shipment Date"));
        if ReservMgt.IsPositive then
            SetFilter("Quantity (Base)", '>0')
        else
            SetFilter("Quantity (Base)", '<0');

        SetRange("Sales Order No.", '');

        OnAfterSetFilters(Rec, ReservEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilters(var RequisitionLine: Record "Requisition Line"; ReservationEntry: Record "Reservation Entry")
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

