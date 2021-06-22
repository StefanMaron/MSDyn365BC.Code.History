page 6503 "Avail. - Item Tracking Lines"
{
    Caption = 'Avail. - Item Tracking Lines';
    DataCaptionExpression = CaptionText;
    DataCaptionFields = "Lot No.", "Serial No.";
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    Permissions = TableData "Reservation Entry" = rm;
    SourceTable = "Reservation Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Reservation Status"; "Reservation Status")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies the status of the reservation.';
                    Visible = false;
                }
                field(TextCaption; TextCaption)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Document Type';
                    ToolTip = 'Specifies the type of document.';
                }
                field("Source Type"; "Source Type")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies for which source type the reservation entry is related to.';
                    Visible = false;
                }
                field("Source ID"; "Source ID")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies which source ID the reservation entry is related to.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the Location of the items that have been reserved in the entry.';
                }
                field("Serial No."; "Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number of the item that is being handled on the document line.';
                }
                field("Lot No."; "Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the lot number of the item that is being handled with the associated document line.';
                }
                field("Expected Receipt Date"; "Expected Receipt Date")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies the date on which the reserved items are expected to enter inventory.';
                }
                field("Quantity (Base)"; "Quantity (Base)")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies the quantity of the item that has been reserved in the entry.';
                }
                field(ReservedQtyBase; GetReservedQtyBase)
                {
                    ApplicationArea = Reservation;
                    Caption = 'Reserved Qty. (Base)';
                    Editable = false;
                    ToolTip = 'Specifies the quantity that has been reserved for the item.';
                }
                field(QtyToReserve; QtyToReserve)
                {
                    ApplicationArea = Reservation;
                    Caption = 'Available Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of the item that is available for reservation.';
                }
                field(ReservedThisLine; GetReservedQty)
                {
                    ApplicationArea = Reservation;
                    Caption = 'Current Reserved Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item that is reserved for the document type.';
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
            group(FunctionButton2)
            {
                Caption = 'F&unctions';
                Image = "Action";
                Visible = FunctionButton2Visible;
                action("&Show Document")
                {
                    ApplicationArea = ItemTracking;
                    Caption = '&Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the information on the line comes from.';

                    trigger OnAction()
                    begin
                        ReservMgt.LookupDocument("Source Type", "Source Subtype", "Source ID",
                          "Source Batch Name", "Source Prod. Order Line", "Source Ref. No.");
                    end;
                }
            }
            group(FunctionButton1)
            {
                Caption = 'F&unctions';
                Image = "Action";
                Visible = FunctionButton1Visible;
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
                        if not EnableReservations then
                            exit;
                        if not ConfirmManagement.GetResponseOrDefault(Text001, true) then
                            exit;
                        ReservEngineMgt.CancelReservation(Rec);
                        UpdateReservFrom;
                    end;
                }
                action(Action36)
                {
                    ApplicationArea = ItemTracking;
                    Caption = '&Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the information on the line comes from.';

                    trigger OnAction()
                    begin
                        ReservMgt.LookupDocument("Source Type", "Source Subtype", "Source ID",
                          "Source Batch Name", "Source Prod. Order Line", "Source Ref. No.");
                    end;
                }
            }
        }
    }

    trigger OnInit()
    begin
        FunctionButton2Visible := true;
        FunctionButton1Visible := true;
    end;

    trigger OnOpenPage()
    begin
        FunctionButton1Visible := EnableReservations;
        FunctionButton2Visible := not EnableReservations;
    end;

    var
        Text001: Label 'Cancel reservation?';
        ReservEntry: Record "Reservation Entry";
        SalesLine: Record "Sales Line";
        PurchLine: Record "Purchase Line";
        ItemJnlLine: Record "Item Journal Line";
        ReqLine: Record "Requisition Line";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        PlanningComponent: Record "Planning Component";
        TransLine: Record "Transfer Line";
        ServiceInvLine: Record "Service Line";
        JobPlanningLine: Record "Job Planning Line";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
        AssemblyHeaderReserve: Codeunit "Assembly Header-Reserve";
        ReservMgt: Codeunit "Reservation Management";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReserveSalesLine: Codeunit "Sales Line-Reserve";
        ReserveReqLine: Codeunit "Req. Line-Reserve";
        ReservePurchLine: Codeunit "Purch. Line-Reserve";
        ReserveItemJnlLine: Codeunit "Item Jnl. Line-Reserve";
        ReserveProdOrderLine: Codeunit "Prod. Order Line-Reserve";
        ReserveProdOrderComp: Codeunit "Prod. Order Comp.-Reserve";
        ReservePlanningComponent: Codeunit "Plng. Component-Reserve";
        ReserveTransLine: Codeunit "Transfer Line-Reserve";
        ReserveServiceInvLine: Codeunit "Service Line-Reserve";
        JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
        QtyToReserve: Decimal;
        CaptionText: Text;
        EnableReservations: Boolean;
        [InDataSet]
        FunctionButton1Visible: Boolean;
        [InDataSet]
        FunctionButton2Visible: Boolean;

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

    procedure SetItemJnlLine(var CurrentItemJnlLine: Record "Item Journal Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        ItemJnlLine := CurrentItemJnlLine;
        ReservEntry := CurrentReservEntry;

        Clear(ReservMgt);
        ReservMgt.SetItemJnlLine(ItemJnlLine);
        ReservEngineMgt.InitFilterAndSortingFor(ReservEntry, true);
        ReserveItemJnlLine.FilterReservFor(ReservEntry, ItemJnlLine);
        CaptionText := ReserveItemJnlLine.Caption(ItemJnlLine);
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

    procedure SetItemTrackingLine(LookupType: Integer; LookupSubtype: Integer; CurrentReservEntry: Record "Reservation Entry"; SearchForSupply: Boolean; AvailabilityDate: Date)
    begin
        ReservMgt.SetMatchFilter(CurrentReservEntry, Rec, SearchForSupply, AvailabilityDate);
        SetRange("Source Type", LookupType);
        SetRange("Source Subtype", LookupSubtype);
        EnableReservations := true;
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
            DATABASE::"Item Journal Line":
                begin
                    ItemJnlLine.Find;
                    SetItemJnlLine(ItemJnlLine, ReservEntry);
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
    end;

    local procedure GetReservedQty(): Decimal
    begin
        // This procedure is intentionally left blank.
    end;

    local procedure GetReservedQtyBase(): Decimal
    begin
        // This procedure is intentionally left blank.
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
}

