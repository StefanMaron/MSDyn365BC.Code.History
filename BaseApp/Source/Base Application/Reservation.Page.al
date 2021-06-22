page 498 Reservation
{
    Caption = 'Reservation';
    DataCaptionExpression = CaptionText;
    DeleteAllowed = false;
    PageType = Worksheet;
    PromotedActionCategories = 'New,Process,Report,Line';
    SourceTable = "Entry Summary";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ItemNo; ReservEntry."Item No.")
                {
                    ApplicationArea = Reservation;
                    Caption = 'Item No.';
                    Editable = false;
                    ToolTip = 'Specifies the item number of the item that the reservation is for.';
                }
                field("ReservEntry.""Shipment Date"""; ReservEntry."Shipment Date")
                {
                    ApplicationArea = Reservation;
                    Caption = 'Shipment Date';
                    Editable = false;
                    ToolTip = 'Specifies the shipment date, expected receipt date, or posting date for the reservation.';
                }
                field("ReservEntry.Description"; ReservEntry.Description)
                {
                    ApplicationArea = Reservation;
                    Caption = 'Description';
                    ToolTip = 'Specifies a description of the reservation in the window.';
                }
                field(QtyToReserveBase; QtyToReserveBase)
                {
                    ApplicationArea = Reservation;
                    Caption = 'Quantity to Reserve';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total quantity of the item that must be reserved for the line.';
                }
                field(QtyReservedBase; QtyReservedBase)
                {
                    ApplicationArea = Reservation;
                    Caption = 'Reserved Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of the item reserved for the line.';
                }
                field(UnreservedQuantity; QtyToReserveBase - QtyReservedBase)
                {
                    ApplicationArea = Reservation;
                    Caption = 'Unreserved Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the difference between the Quantity to Reserve field and the Reserved Quantity field.';
                }
            }
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Summary Type"; "Summary Type")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies which type of line or entry is summarized in the entry summary.';
                }
                field("Total Quantity"; ReservMgt.FormatQty("Total Quantity"))
                {
                    ApplicationArea = Reservation;
                    BlankZero = true;
                    Caption = 'Total Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total quantity of the item in inventory.';

                    trigger OnDrillDown()
                    begin
                        DrillDownTotalQuantity;
                    end;
                }
                field(TotalReservedQuantity; ReservMgt.FormatQty("Total Reserved Quantity"))
                {
                    ApplicationArea = Reservation;
                    BlankZero = true;
                    Caption = 'Total Reserved Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total quantity of the item that is reserved on documents or entries.';

                    trigger OnDrillDown()
                    begin
                        DrillDownReservedQuantity;
                    end;
                }
                field(QtyAllocatedInWarehouse; ReservMgt.FormatQty("Qty. Alloc. in Warehouse"))
                {
                    ApplicationArea = Warehouse;
                    BlankZero = true;
                    Caption = 'Qty. Allocated in Warehouse';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of the item that is allocated to activities in the warehouse.';
                }
                field("ReservMgt.FormatQty(""Res. Qty. on Picks & Shipmts."")"; ReservMgt.FormatQty("Res. Qty. on Picks & Shipmts."))
                {
                    ApplicationArea = Warehouse;
                    BlankZero = true;
                    Caption = 'Reserved Qty. on Picks and Shipments';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the sum of the overlap quantities.';
                    Visible = false;
                }
                field(TotalAvailableQuantity; ReservMgt.FormatQty("Total Available Quantity"))
                {
                    ApplicationArea = Reservation;
                    BlankZero = true;
                    Caption = 'Total Available Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity that is available for the user to reserve from entries of the type.';
                }
                field("Non-specific Reserved Qty."; "Non-specific Reserved Qty.")
                {
                    ApplicationArea = Reservation;
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item that is reserved but does not have specific item tracking numbers in the reservation.';
                    Visible = false;
                }
                field("Current Reserved Quantity"; ReservMgt.FormatQty(ReservedThisLine(Rec)))
                {
                    ApplicationArea = Reservation;
                    BlankZero = true;
                    Caption = 'Current Reserved Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many items in the entry are reserved for the line opened in the Reservation window.';

                    trigger OnDrillDown()
                    begin
                        DrillDownReservedThisLine;
                    end;
                }
            }
            label(NoteText)
            {
                ApplicationArea = Reservation;
                CaptionClass = Format(StrSubstNo(Text009, NonSpecificQty, FieldCaption("Total Reserved Quantity")));
                Editable = false;
                MultiLine = true;
                Visible = NoteTextVisible;
            }
            group(Filters)
            {
                Caption = 'Filters';
                field("ReservEntry.""Variant Code"""; ReservEntry."Variant Code")
                {
                    ApplicationArea = Reservation;
                    Caption = 'Variant Code';
                    Editable = false;
                    ToolTip = 'Specifies the variant code for the reservation.';
                }
                field("ReservEntry.""Location Code"""; ReservEntry."Location Code")
                {
                    ApplicationArea = Reservation;
                    Caption = 'Location Code';
                    Editable = false;
                    ToolTip = 'Specifies the location code for the reservation.';
                }
                field("ReservEntry.""Serial No."""; ReservEntry."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Serial No.';
                    Editable = false;
                    ToolTip = 'Specifies the serial number for an item in the reservation.';
                }
                field("ReservEntry.""Lot No."""; ReservEntry."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Lot No.';
                    Editable = false;
                    ToolTip = 'Specifies the lot number for the reservation.';
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
                action(AvailableToReserve)
                {
                    ApplicationArea = Reservation;
                    Caption = '&Available to Reserve';
                    Image = ItemReservation;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View all the quantities on documents or in inventory that are available to reserve for the item on the line. The two actions, Auto Reserve and Reserve from Current Line make reservations from the quantities in this view.';

                    trigger OnAction()
                    begin
                        DrillDownTotalQuantity;
                    end;
                }
                action("&Reservation Entries")
                {
                    AccessByPermission = TableData Item = R;
                    ApplicationArea = Reservation;
                    Caption = '&Reservation Entries';
                    Image = ReservationLedger;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ToolTip = 'View all reservations that are made for the item, either manually or automatically.';

                    trigger OnAction()
                    begin
                        DrillDownReservedThisLine;
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
                action("Auto Reserve")
                {
                    ApplicationArea = Reservation;
                    Caption = '&Auto Reserve';
                    Image = AutoReserve;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Automatically reserve the first available quantity for the item on the line. ';

                    trigger OnAction()
                    begin
                        AutoReserve;
                    end;
                }
                action("Reserve from Current Line")
                {
                    ApplicationArea = Reservation;
                    Caption = '&Reserve from Current Line';
                    Image = LineReserve;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Open the view of quantities available to reserve and select which to reserve.';

                    trigger OnAction()
                    var
                        RemainingQtyToReserveBase: Decimal;
                        QtyReservedBefore: Decimal;
                        RemainingQtyToReserve: Decimal;
                    begin
                        RemainingQtyToReserveBase := QtyToReserveBase - QtyReservedBase;
                        if RemainingQtyToReserveBase = 0 then
                            Error(Text000);
                        QtyReservedBefore := QtyReservedBase;
                        if HandleItemTracking then
                            ReservMgt.SetItemTrackingHandling(2);
                        RemainingQtyToReserve := QtyToReserve - QtyReserved;
                        ReservMgt.AutoReserveOneLine(
                          "Entry No.", RemainingQtyToReserve, RemainingQtyToReserveBase, ReservEntry.Description,
                          ReservEntry."Shipment Date");
                        UpdateReservFrom;
                        if QtyReservedBefore = QtyReservedBase then
                            Error(Text002);
                    end;
                }
                action(CancelReservationCurrentLine)
                {
                    AccessByPermission = TableData Item = R;
                    ApplicationArea = Reservation;
                    Caption = '&Cancel Reservation from Current Line';
                    Image = Cancel;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Cancel the selected reservation entry.';

                    trigger OnAction()
                    var
                        ReservEntry3: Record "Reservation Entry";
                        RecordsFound: Boolean;
                    begin
                        if not Confirm(Text003, false, "Summary Type") then
                            exit;
                        Clear(ReservEntry2);
                        ReservEntry2 := ReservEntry;
                        ReservEntry2.SetPointerFilter;
                        ReservEntry2.SetRange("Reservation Status", ReservEntry2."Reservation Status"::Reservation);
                        ReservEntry2.SetRange("Disallow Cancellation", false);
                        if ReservEntry2.FindSet then
                            repeat
                                ReservEntry3.Get(ReservEntry2."Entry No.", not ReservEntry2.Positive);
                                if RelatesToSummEntry(ReservEntry3, Rec) then begin
                                    ReservEngineMgt.CancelReservation(ReservEntry2);
                                    RecordsFound := true;
                                end;
                            until ReservEntry2.Next = 0;

                        if RecordsFound then
                            UpdateReservFrom
                        else
                            Error(Text005);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        FormIsOpen := true;
    end;

    var
        Text000: Label 'Fully reserved.';
        Text001: Label 'Full automatic Reservation is not possible.\Reserve manually.';
        Text002: Label 'There is nothing available to reserve.';
        Text003: Label 'Do you want to cancel all reservations in the %1?';
        Text005: Label 'There are no reservations to cancel.';
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        SalesLine: Record "Sales Line";
        PurchLine: Record "Purchase Line";
        ItemJnlLine: Record "Item Journal Line";
        ReqLine: Record "Requisition Line";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        PlanningComponent: Record "Planning Component";
        ServiceLine: Record "Service Line";
        TransLine: Record "Transfer Line";
        JobPlanningLine: Record "Job Planning Line";
        ReservMgt: Codeunit "Reservation Management";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReserveSalesLine: Codeunit "Sales Line-Reserve";
        ReserveReqLine: Codeunit "Req. Line-Reserve";
        ReservePurchLine: Codeunit "Purch. Line-Reserve";
        ReserveItemJnlLine: Codeunit "Item Jnl. Line-Reserve";
        ReserveProdOrderLine: Codeunit "Prod. Order Line-Reserve";
        ReserveProdOrderComp: Codeunit "Prod. Order Comp.-Reserve";
        AssemblyHeaderReserve: Codeunit "Assembly Header-Reserve";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
        ReservePlanningComponent: Codeunit "Plng. Component-Reserve";
        ReserveServiceLine: Codeunit "Service Line-Reserve";
        ReserveTransLine: Codeunit "Transfer Line-Reserve";
        JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        UOMMgt: Codeunit "Unit of Measure Management";
        AvailableSalesLines: Page "Available - Sales Lines";
        AvailablePurchLines: Page "Available - Purchase Lines";
        AvailableItemLedgEntries: Page "Available - Item Ledg. Entries";
        AvailableReqLines: Page "Available - Requisition Lines";
        AvailableProdOrderLines: Page "Available - Prod. Order Lines";
        AvailableProdOrderComps: Page "Available - Prod. Order Comp.";
        AvailablePlanningComponents: Page "Avail. - Planning Components";
        AvailableServiceLines: Page "Available - Service Lines";
        AvailableTransLines: Page "Available - Transfer Lines";
        AvailableItemTrackingLines: Page "Avail. - Item Tracking Lines";
        AvailableJobPlanningLines: Page "Available - Job Planning Lines";
        AvailableAssemblyHeaders: Page "Available - Assembly Headers";
        AvailableAssemblyLines: Page "Available - Assembly Lines";
        QtyToReserve: Decimal;
        QtyToReserveBase: Decimal;
        QtyReserved: Decimal;
        QtyReservedBase: Decimal;
        ItemTrackingQtyToReserve: Decimal;
        ItemTrackingQtyToReserveBase: Decimal;
        NonSpecificQty: Decimal;
        CaptionText: Text;
        FullAutoReservation: Boolean;
        FormIsOpen: Boolean;
        HandleItemTracking: Boolean;
        Text006: Label 'Do you want to reserve specific serial or lot numbers?';
        Text007: Label ', %1 %2', Comment = '%1 = Serial No.; %2 = Lot No.';
        Text008: Label 'Action canceled.';
        Text009: Label '%1 of the %2 are nonspecific and may be available.';
        [InDataSet]
        NoteTextVisible: Boolean;

    procedure SetSalesLine(var CurrentSalesLine: Record "Sales Line")
    begin
        CurrentSalesLine.TestField("Job No.", '');
        CurrentSalesLine.TestField("Drop Shipment", false);
        CurrentSalesLine.TestField(Type, CurrentSalesLine.Type::Item);
        CurrentSalesLine.TestField("Shipment Date");

        SalesLine := CurrentSalesLine;
        ReservEntry.SetSource(
          DATABASE::"Sales Line", SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.", '', 0);
        ReservEntry."Item No." := SalesLine."No.";
        ReservEntry."Variant Code" := SalesLine."Variant Code";
        ReservEntry."Location Code" := SalesLine."Location Code";
        ReservEntry."Shipment Date" := SalesLine."Shipment Date";

        CaptionText := ReserveSalesLine.Caption(SalesLine);
        UpdateReservFrom;

        OnAfterSetSalesLine(Rec, ReservEntry);
    end;

    procedure SetReqLine(var CurrentReqLine: Record "Requisition Line")
    begin
        CurrentReqLine.TestField("Sales Order No.", '');
        CurrentReqLine.TestField("Sales Order Line No.", 0);
        CurrentReqLine.TestField("Sell-to Customer No.", '');
        CurrentReqLine.TestField(Type, CurrentReqLine.Type::Item);
        CurrentReqLine.TestField("Due Date");

        ReqLine := CurrentReqLine;
        ReservEntry.SetSource(
          DATABASE::"Requisition Line", 0, ReqLine."Worksheet Template Name", ReqLine."Line No.", ReqLine."Journal Batch Name", 0);
        ReservEntry."Item No." := ReqLine."No.";
        ReservEntry."Variant Code" := ReqLine."Variant Code";
        ReservEntry."Location Code" := ReqLine."Location Code";
        ReservEntry."Shipment Date" := ReqLine."Due Date";

        CaptionText := ReserveReqLine.Caption(ReqLine);
        UpdateReservFrom;

        OnAfterSetReqLine(Rec, ReservEntry);
    end;

    procedure SetPurchLine(var CurrentPurchLine: Record "Purchase Line")
    begin
        CurrentPurchLine.TestField("Job No.", '');
        CurrentPurchLine.TestField("Drop Shipment", false);
        CurrentPurchLine.TestField(Type, CurrentPurchLine.Type::Item);
        CurrentPurchLine.TestField("Expected Receipt Date");

        PurchLine := CurrentPurchLine;
        ReservEntry.SetSource(
          DATABASE::"Purchase Line", PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.", '', 0);
        ReservEntry."Item No." := PurchLine."No.";
        ReservEntry."Variant Code" := PurchLine."Variant Code";
        ReservEntry."Location Code" := PurchLine."Location Code";
        ReservEntry."Shipment Date" := PurchLine."Expected Receipt Date";

        CaptionText := ReservePurchLine.Caption(PurchLine);
        UpdateReservFrom;

        OnAfterSetPurchLine(Rec, ReservEntry);
    end;

    procedure SetItemJnlLine(var CurrentItemJnlLine: Record "Item Journal Line")
    begin
        CurrentItemJnlLine.TestField("Drop Shipment", false);
        CurrentItemJnlLine.TestField("Posting Date");

        ItemJnlLine := CurrentItemJnlLine;
        ReservEntry.SetSource(
          DATABASE::"Item Journal Line", ItemJnlLine."Entry Type", ItemJnlLine."Journal Template Name", ItemJnlLine."Line No.",
          ItemJnlLine."Journal Batch Name", 0);
        ReservEntry."Item No." := ItemJnlLine."Item No.";
        ReservEntry."Variant Code" := ItemJnlLine."Variant Code";
        ReservEntry."Location Code" := ItemJnlLine."Location Code";
        ReservEntry."Shipment Date" := ItemJnlLine."Posting Date";

        CaptionText := ReserveItemJnlLine.Caption(ItemJnlLine);
        UpdateReservFrom;

        OnAfterSetItemJnlLine(Rec, ReservEntry);
    end;

    procedure SetProdOrderLine(var CurrentProdOrderLine: Record "Prod. Order Line")
    begin
        CurrentProdOrderLine.TestField("Due Date");

        ProdOrderLine := CurrentProdOrderLine;
        ReservEntry.SetSource(
          DATABASE::"Prod. Order Line", ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", 0, '', ProdOrderLine."Line No.");
        ReservEntry."Item No." := ProdOrderLine."Item No.";
        ReservEntry."Variant Code" := ProdOrderLine."Variant Code";
        ReservEntry."Location Code" := ProdOrderLine."Location Code";
        ReservEntry."Shipment Date" := ProdOrderLine."Due Date";

        CaptionText := ReserveProdOrderLine.Caption(ProdOrderLine);
        UpdateReservFrom;

        OnAfterSetProdOrderLine(Rec, ReservEntry);
    end;

    procedure SetProdOrderComponent(var CurrentProdOrderComp: Record "Prod. Order Component")
    begin
        CurrentProdOrderComp.TestField("Due Date");

        ProdOrderComp := CurrentProdOrderComp;
        ReservEntry.SetSource(
          DATABASE::"Prod. Order Component", ProdOrderComp.Status, ProdOrderComp."Prod. Order No.", ProdOrderComp."Line No.",
          '', ProdOrderComp."Prod. Order Line No.");
        ReservEntry."Item No." := ProdOrderComp."Item No.";
        ReservEntry."Variant Code" := ProdOrderComp."Variant Code";
        ReservEntry."Location Code" := ProdOrderComp."Location Code";
        ReservEntry."Shipment Date" := ProdOrderComp."Due Date";

        CaptionText := ReserveProdOrderComp.Caption(ProdOrderComp);
        UpdateReservFrom;

        OnAfterSetProdOrderComponent(Rec, ReservEntry);
    end;

    procedure SetAssemblyHeader(var CurrentAssemblyHeader: Record "Assembly Header")
    begin
        CurrentAssemblyHeader.TestField("Due Date");

        AssemblyHeader := CurrentAssemblyHeader;
        ReservEntry.SetSource(DATABASE::"Assembly Header", AssemblyHeader."Document Type", AssemblyHeader."No.", 0, '', 0);
        ReservEntry."Item No." := AssemblyHeader."Item No.";
        ReservEntry."Variant Code" := AssemblyHeader."Variant Code";
        ReservEntry."Location Code" := AssemblyHeader."Location Code";
        ReservEntry."Shipment Date" := AssemblyHeader."Due Date";

        CaptionText := AssemblyHeaderReserve.Caption(AssemblyHeader);
        UpdateReservFrom;

        OnAfterSetAssemblyHeader(Rec, ReservEntry);
    end;

    procedure SetAssemblyLine(var CurrentAssemblyLine: Record "Assembly Line")
    begin
        CurrentAssemblyLine.TestField(Type, CurrentAssemblyLine.Type::Item);
        CurrentAssemblyLine.TestField("Due Date");

        AssemblyLine := CurrentAssemblyLine;
        ReservEntry.SetSource(
          DATABASE::"Assembly Line", AssemblyLine."Document Type", AssemblyLine."Document No.", AssemblyLine."Line No.", '', 0);
        ReservEntry."Item No." := AssemblyLine."No.";
        ReservEntry."Variant Code" := AssemblyLine."Variant Code";
        ReservEntry."Location Code" := AssemblyLine."Location Code";
        ReservEntry."Shipment Date" := AssemblyLine."Due Date";

        CaptionText := AssemblyLineReserve.Caption(AssemblyLine);
        UpdateReservFrom;

        OnAfterSetAssemblyLine(Rec, ReservEntry);
    end;

    procedure SetPlanningComponent(var CurrentPlanningComponent: Record "Planning Component")
    begin
        CurrentPlanningComponent.TestField("Due Date");

        PlanningComponent := CurrentPlanningComponent;
        ReservEntry.SetSource(
          DATABASE::"Planning Component", 0, PlanningComponent."Worksheet Template Name", PlanningComponent."Line No.",
          PlanningComponent."Worksheet Batch Name", PlanningComponent."Worksheet Line No.");
        ReservEntry."Item No." := PlanningComponent."Item No.";
        ReservEntry."Variant Code" := PlanningComponent."Variant Code";
        ReservEntry."Location Code" := PlanningComponent."Location Code";
        ReservEntry."Shipment Date" := PlanningComponent."Due Date";

        CaptionText := ReservePlanningComponent.Caption(PlanningComponent);
        UpdateReservFrom;

        OnAfterSetPlanningComponent(Rec, ReservEntry);
    end;

    procedure SetTransLine(CurrentTransLine: Record "Transfer Line"; Direction: Option Outbound,Inbound)
    begin
        ClearAll;

        TransLine := CurrentTransLine;
        ReservEntry.SetSource(
          DATABASE::"Transfer Line", Direction, CurrentTransLine."Document No.", CurrentTransLine."Line No.",
          '', CurrentTransLine."Derived From Line No.");
        ReservEntry."Item No." := CurrentTransLine."Item No.";
        ReservEntry."Variant Code" := CurrentTransLine."Variant Code";
        case Direction of
            Direction::Outbound:
                begin
                    ReservEntry."Location Code" := CurrentTransLine."Transfer-from Code";
                    ReservEntry."Shipment Date" := CurrentTransLine."Shipment Date";
                end;
            Direction::Inbound:
                begin
                    ReservEntry."Location Code" := CurrentTransLine."Transfer-to Code";
                    ReservEntry."Shipment Date" := CurrentTransLine."Receipt Date";
                end;
        end;

        ReservEntry."Qty. per Unit of Measure" := CurrentTransLine."Qty. per Unit of Measure";

        CaptionText := ReserveTransLine.Caption(TransLine);
        UpdateReservFrom;

        OnAfterSetTransLine(Rec, ReservEntry);
    end;

    procedure SetServiceLine(var CurrentServiceLine: Record "Service Line")
    begin
        CurrentServiceLine.TestField(Type, CurrentServiceLine.Type::Item);
        CurrentServiceLine.TestField("Needed by Date");

        ServiceLine := CurrentServiceLine;
        ReservEntry.SetSource(
          DATABASE::"Service Line", ServiceLine."Document Type", ServiceLine."Document No.", ServiceLine."Line No.", '', 0);
        ReservEntry."Item No." := ServiceLine."No.";
        ReservEntry."Variant Code" := ServiceLine."Variant Code";
        ReservEntry."Location Code" := ServiceLine."Location Code";
        ReservEntry."Shipment Date" := ServiceLine."Needed by Date";

        CaptionText := ReserveServiceLine.Caption(ServiceLine);
        UpdateReservFrom;

        OnAfterSetServiceLine(Rec, ReservEntry);
    end;

    procedure SetJobPlanningLine(var CurrentJobPlanningLine: Record "Job Planning Line")
    begin
        CurrentJobPlanningLine.TestField(Type, CurrentJobPlanningLine.Type::Item);
        CurrentJobPlanningLine.TestField("Planning Date");

        JobPlanningLine := CurrentJobPlanningLine;
        ReservEntry.SetSource(
          DATABASE::"Job Planning Line", JobPlanningLine.Status, JobPlanningLine."Job No.",
          JobPlanningLine."Job Contract Entry No.", '', 0);
        ReservEntry."Item No." := JobPlanningLine."No.";
        ReservEntry."Variant Code" := JobPlanningLine."Variant Code";
        ReservEntry."Location Code" := JobPlanningLine."Location Code";
        ReservEntry."Shipment Date" := JobPlanningLine."Planning Date";

        CaptionText := JobPlanningLineReserve.Caption(JobPlanningLine);
        UpdateReservFrom;

        OnAfterSetJobPlanningLine(Rec, ReservEntry);
    end;

    procedure SetReservEntry(ReservEntry2: Record "Reservation Entry")
    begin
        ReservEntry := ReservEntry2;
        UpdateReservMgt;
    end;

    local procedure FilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; FromReservSummEntry: Record "Entry Summary")
    begin
        FilterReservEntry.SetRange("Item No.", ReservEntry."Item No.");

        case FromReservSummEntry."Entry No." of
            1:
                begin // Item Ledger Entry
                    FilterReservEntry.SetRange("Source Type", DATABASE::"Item Ledger Entry");
                    FilterReservEntry.SetRange("Source Subtype", 0);
                    FilterReservEntry.SetRange("Expected Receipt Date");
                end;
            11, 12, 13, 14, 15, 16:
                begin // Purchase Line
                    FilterReservEntry.SetRange("Source Type", DATABASE::"Purchase Line");
                    FilterReservEntry.SetRange("Source Subtype", FromReservSummEntry."Entry No." - 11);
                end;
            21:
                begin // Requisition Line
                    FilterReservEntry.SetRange("Source Type", DATABASE::"Requisition Line");
                    FilterReservEntry.SetRange("Source Subtype", 0);
                end;
            31, 32, 33, 34, 35, 36:
                begin // Sales Line
                    FilterReservEntry.SetRange("Source Type", DATABASE::"Sales Line");
                    FilterReservEntry.SetRange("Source Subtype", FromReservSummEntry."Entry No." - 31);
                end;
            41, 42, 43, 44, 45:
                begin // Item Journal Line
                    FilterReservEntry.SetRange("Source Type", DATABASE::"Item Journal Line");
                    FilterReservEntry.SetRange("Source Subtype", FromReservSummEntry."Entry No." - 41);
                end;
            61, 62, 63, 64:
                begin // prod. order
                    FilterReservEntry.SetRange("Source Type", DATABASE::"Prod. Order Line");
                    FilterReservEntry.SetRange("Source Subtype", FromReservSummEntry."Entry No." - 61);
                end;
            71, 72, 73, 74:
                begin // prod. order
                    FilterReservEntry.SetRange("Source Type", DATABASE::"Prod. Order Component");
                    FilterReservEntry.SetRange("Source Subtype", FromReservSummEntry."Entry No." - 71);
                end;
            91:
                begin // Planning Component
                    FilterReservEntry.SetRange("Source Type", DATABASE::"Planning Component");
                    FilterReservEntry.SetRange("Source Subtype", 0);
                end;
            101, 102:
                begin // Transfer Line
                    FilterReservEntry.SetRange("Source Type", DATABASE::"Transfer Line");
                    FilterReservEntry.SetRange("Source Subtype", FromReservSummEntry."Entry No." - 101);
                end;
            110:
                begin // Service Line
                    FilterReservEntry.SetRange("Source Type", DATABASE::"Service Line");
                    FilterReservEntry.SetRange("Source Subtype", FromReservSummEntry."Entry No." - 109);
                end;
            131, 132, 133, 134:
                begin // Job Planning Line
                    FilterReservEntry.SetRange("Source Type", DATABASE::"Job Planning Line");
                    FilterReservEntry.SetRange("Source Subtype", FromReservSummEntry."Entry No." - 131);
                end;
            141, 142, 143, 144, 145:
                begin // Assembly Header
                    FilterReservEntry.SetRange("Source Type", DATABASE::"Assembly Header");
                    FilterReservEntry.SetRange("Source Subtype", FromReservSummEntry."Entry No." - 141);
                end;
            151, 152, 153, 154, 155:
                begin // Assembly Line
                    FilterReservEntry.SetRange("Source Type", DATABASE::"Assembly Line");
                    FilterReservEntry.SetRange("Source Subtype", FromReservSummEntry."Entry No." - 151);
                end;
        end;

        OnFilterReservEntryOnAfterFilterSource(FilterReservEntry, FromReservSummEntry, ReservEntry);

        FilterReservEntry.SetRange(
          "Reservation Status", FilterReservEntry."Reservation Status"::Reservation);
        FilterReservEntry.SetRange("Location Code", ReservEntry."Location Code");
        FilterReservEntry.SetRange("Variant Code", ReservEntry."Variant Code");
        if ReservEntry.TrackingExists then begin
            FilterReservEntry.SetRange("Serial No.", ReservEntry."Serial No.");
            FilterReservEntry.SetRange("Lot No.", ReservEntry."Lot No.");
        end;
        FilterReservEntry.SetRange(Positive, ReservMgt.IsPositive);
    end;

    local procedure RelatesToSummEntry(var FilterReservEntry: Record "Reservation Entry"; FromReservSummEntry: Record "Entry Summary"): Boolean
    var
        IsHandled: Boolean;
    begin
        case FromReservSummEntry."Entry No." of
            1: // Item Ledger Entry
                exit((FilterReservEntry."Source Type" = DATABASE::"Item Ledger Entry") and
                  (FilterReservEntry."Source Subtype" = 0));
            11, 12, 13, 14, 15, 16: // Purchase Line
                exit((FilterReservEntry."Source Type" = DATABASE::"Purchase Line") and
                  (FilterReservEntry."Source Subtype" = FromReservSummEntry."Entry No." - 11));
            21: // Requisition Line
                exit((FilterReservEntry."Source Type" = DATABASE::"Requisition Line") and
                  (FilterReservEntry."Source Subtype" = 0));
            31, 32, 33, 34, 35, 36: // Sales Line
                exit((FilterReservEntry."Source Type" = DATABASE::"Sales Line") and
                  (FilterReservEntry."Source Subtype" = FromReservSummEntry."Entry No." - 31));
            41, 42, 43, 44, 45: // Item Journal Line
                exit((FilterReservEntry."Source Type" = DATABASE::"Item Journal Line") and
                  (FilterReservEntry."Source Subtype" = FromReservSummEntry."Entry No." - 41));
            61, 62, 63, 64: // Prod. Order
                exit((FilterReservEntry."Source Type" = DATABASE::"Prod. Order Line") and
                  (FilterReservEntry."Source Subtype" = FromReservSummEntry."Entry No." - 61));
            71, 72, 73, 74: // Prod. Order Component
                exit((FilterReservEntry."Source Type" = DATABASE::"Prod. Order Component") and
                  (FilterReservEntry."Source Subtype" = FromReservSummEntry."Entry No." - 71));
            91: // Planning Component
                exit((FilterReservEntry."Source Type" = DATABASE::"Planning Component") and
                  (FilterReservEntry."Source Subtype" = 0));
            101, 102: // Transfer Line
                exit((FilterReservEntry."Source Type" = DATABASE::"Transfer Line") and
                  (FilterReservEntry."Source Subtype" = FromReservSummEntry."Entry No." - 101));
            110: // Service Line
                exit((FilterReservEntry."Source Type" = DATABASE::"Service Line") and
                  (FilterReservEntry."Source Subtype" = FromReservSummEntry."Entry No." - 109));
            131, 132, 133, 134: // Job Planning Line
                exit((FilterReservEntry."Source Type" = DATABASE::"Job Planning Line") and
                  (FilterReservEntry."Source Subtype" = FromReservSummEntry."Entry No." - 131));
            141, 142, 143, 144, 145: // Assembly Header
                exit((FilterReservEntry."Source Type" = DATABASE::"Assembly Header") and
                  (FilterReservEntry."Source Subtype" = FromReservSummEntry."Entry No." - 141));
            151, 152, 153, 154, 155: // Assembly Line
                exit((FilterReservEntry."Source Type" = DATABASE::"Assembly Line") and
                  (FilterReservEntry."Source Subtype" = FromReservSummEntry."Entry No." - 151));
        end;

        IsHandled := false;
        OnAfterRelatesToSummEntry(FromReservSummEntry, FilterReservEntry, IsHandled);
        exit(IsHandled);
    end;

    local procedure UpdateReservFrom()
    var
        EntrySummary: Record "Entry Summary";
        QtyPerUOM: Decimal;
        QtyReservedIT: Decimal;
    begin
        if not FormIsOpen then
            GetSerialLotNo(ItemTrackingQtyToReserve, ItemTrackingQtyToReserveBase);

        QtyPerUOM := GetQtyPerUOMFromSource;

        UpdateReservMgt;
        ReservMgt.UpdateStatistics(
          Rec, ReservEntry."Shipment Date", HandleItemTracking);

        if HandleItemTracking then begin
            EntrySummary := Rec;
            QtyReservedBase := 0;
            if FindSet then
                repeat
                    QtyReservedBase += ReservedThisLine(Rec);
                until Next = 0;
            QtyReservedIT := Round(QtyReservedBase / QtyPerUOM, UOMMgt.QtyRndPrecision);
            if Abs(QtyReserved - QtyReservedIT) > UOMMgt.QtyRndPrecision then
                QtyReserved := QtyReservedIT;
            QtyToReserveBase := ItemTrackingQtyToReserveBase;
            if Abs(ItemTrackingQtyToReserve - QtyToReserve) > UOMMgt.QtyRndPrecision then
                QtyToReserve := ItemTrackingQtyToReserve;
            Rec := EntrySummary;
        end;

        UpdateNonSpecific; // Late Binding

        OnAfterUpdateReservFrom(Rec);

        if FormIsOpen then
            CurrPage.Update;
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
            DATABASE::"Item Journal Line":
                ReservMgt.SetItemJnlLine(ItemJnlLine);
            DATABASE::"Prod. Order Line":
                ReservMgt.SetProdOrderLine(ProdOrderLine);
            DATABASE::"Prod. Order Component":
                ReservMgt.SetProdOrderComponent(ProdOrderComp);
            DATABASE::"Assembly Header":
                ReservMgt.SetAssemblyHeader(AssemblyHeader);
            DATABASE::"Assembly Line":
                ReservMgt.SetAssemblyLine(AssemblyLine);
            DATABASE::"Planning Component":
                ReservMgt.SetPlanningComponent(PlanningComponent);
            DATABASE::"Transfer Line":
                ReservMgt.SetTransferLine(TransLine, ReservEntry."Source Subtype");
            DATABASE::"Service Line":
                ReservMgt.SetServLine(ServiceLine);
            DATABASE::"Job Planning Line":
                ReservMgt.SetJobPlanningLine(JobPlanningLine);
            else
                OnUpdateReservMgt(ReservEntry, ReservMgt);
        end;
        ReservMgt.SetSerialLotNo(ReservEntry."Serial No.", ReservEntry."Lot No.");
    end;

    local procedure DrillDownTotalQuantity()
    var
        Location: Record Location;
        CreatePick: Codeunit "Create Pick";
    begin
        if HandleItemTracking and ("Entry No." <> 1) then begin
            Clear(AvailableItemTrackingLines);
            AvailableItemTrackingLines.SetItemTrackingLine("Table ID", "Source Subtype", ReservEntry,
              ReservMgt.IsPositive, ReservEntry."Shipment Date");
            AvailableItemTrackingLines.RunModal;
            exit;
        end;

        ReservEntry2 := ReservEntry;
        if not Location.Get(ReservEntry2."Location Code") then
            Clear(Location);
        case "Entry No." of
            1:
                begin // Item Ledger Entry
                    Clear(AvailableItemLedgEntries);
                    case ReservEntry2."Source Type" of
                        DATABASE::"Sales Line":
                            begin
                                AvailableItemLedgEntries.SetSalesLine(SalesLine, ReservEntry2);
                                if Location."Bin Mandatory" or Location."Require Pick" then
                                    AvailableItemLedgEntries.SetTotalAvailQty(
                                      "Total Available Quantity" +
                                      CreatePick.CheckOutBound(
                                        ReservEntry2."Source Type", ReservEntry2."Source Subtype",
                                        ReservEntry2."Source ID", ReservEntry2."Source Ref. No.",
                                        ReservEntry2."Source Prod. Order Line"))
                                else
                                    AvailableItemLedgEntries.SetTotalAvailQty("Total Available Quantity");
                                AvailableItemLedgEntries.SetMaxQtyToReserve(QtyToReserveBase - QtyReservedBase);
                                AvailableItemLedgEntries.RunModal;
                            end;
                        DATABASE::"Requisition Line":
                            begin
                                AvailableItemLedgEntries.SetReqLine(ReqLine, ReservEntry2);
                                AvailableItemLedgEntries.RunModal;
                            end;
                        DATABASE::"Purchase Line":
                            begin
                                AvailableItemLedgEntries.SetPurchLine(PurchLine, ReservEntry2);
                                if Location."Bin Mandatory" or Location."Require Pick" and
                                   (PurchLine."Document Type" = PurchLine."Document Type"::"Return Order")
                                then
                                    AvailableItemLedgEntries.SetTotalAvailQty(
                                      "Total Available Quantity" +
                                      CreatePick.CheckOutBound(
                                        ReservEntry2."Source Type", ReservEntry2."Source Subtype",
                                        ReservEntry2."Source ID", ReservEntry2."Source Ref. No.",
                                        ReservEntry2."Source Prod. Order Line"))
                                else
                                    AvailableItemLedgEntries.SetTotalAvailQty("Total Available Quantity");
                                AvailableItemLedgEntries.RunModal;
                            end;
                        DATABASE::"Prod. Order Line":
                            begin
                                AvailableItemLedgEntries.SetProdOrderLine(ProdOrderLine, ReservEntry2);
                                AvailableItemLedgEntries.RunModal;
                            end;
                        DATABASE::"Prod. Order Component":
                            begin
                                AvailableItemLedgEntries.SetProdOrderComponent(ProdOrderComp, ReservEntry2);
                                if Location."Bin Mandatory" or Location."Require Pick" then
                                    AvailableItemLedgEntries.SetTotalAvailQty(
                                      "Total Available Quantity" +
                                      CreatePick.CheckOutBound(
                                        ReservEntry2."Source Type", ReservEntry2."Source Subtype",
                                        ReservEntry2."Source ID", ReservEntry2."Source Ref. No.",
                                        ReservEntry2."Source Prod. Order Line"))
                                else
                                    AvailableItemLedgEntries.SetTotalAvailQty("Total Available Quantity");
                                AvailableItemLedgEntries.RunModal;
                            end;
                        DATABASE::"Planning Component":
                            begin
                                AvailableItemLedgEntries.SetPlanningComponent(PlanningComponent, ReservEntry2);
                                AvailableItemLedgEntries.RunModal;
                            end;
                        DATABASE::"Transfer Line":
                            begin
                                AvailableItemLedgEntries.SetTransferLine(TransLine, ReservEntry2, ReservEntry."Source Subtype");
                                if Location."Bin Mandatory" or Location."Require Pick" then
                                    AvailableItemLedgEntries.SetTotalAvailQty(
                                      "Total Available Quantity" +
                                      CreatePick.CheckOutBound(
                                        ReservEntry2."Source Type", ReservEntry2."Source Subtype",
                                        ReservEntry2."Source ID", ReservEntry2."Source Ref. No.",
                                        ReservEntry2."Source Prod. Order Line"))
                                else
                                    AvailableItemLedgEntries.SetTotalAvailQty("Total Available Quantity");
                                AvailableItemLedgEntries.RunModal;
                            end;
                        DATABASE::"Service Line":
                            begin
                                AvailableItemLedgEntries.SetServiceLine(ServiceLine, ReservEntry2);
                                AvailableItemLedgEntries.SetTotalAvailQty("Total Available Quantity");
                                AvailableItemLedgEntries.SetMaxQtyToReserve(QtyToReserveBase - QtyReservedBase);
                                AvailableItemLedgEntries.RunModal;
                            end;
                        DATABASE::"Job Planning Line":
                            begin
                                AvailableItemLedgEntries.SetJobPlanningLine(JobPlanningLine, ReservEntry2);
                                AvailableItemLedgEntries.SetTotalAvailQty("Total Available Quantity");
                                AvailableItemLedgEntries.SetMaxQtyToReserve(QtyToReserveBase - QtyReservedBase);
                                AvailableItemLedgEntries.RunModal;
                            end;
                        DATABASE::"Assembly Header":
                            begin
                                AvailableItemLedgEntries.SetAssemblyHeader(AssemblyHeader, ReservEntry2);
                                AvailableItemLedgEntries.SetTotalAvailQty("Total Available Quantity");
                                AvailableItemLedgEntries.SetMaxQtyToReserve(QtyToReserveBase - QtyReservedBase);
                                AvailableItemLedgEntries.RunModal;
                            end;
                        DATABASE::"Assembly Line":
                            begin
                                AvailableItemLedgEntries.SetAssemblyLine(AssemblyLine, ReservEntry2);
                                AvailableItemLedgEntries.SetTotalAvailQty("Total Available Quantity");
                                AvailableItemLedgEntries.SetMaxQtyToReserve(QtyToReserveBase - QtyReservedBase);
                                AvailableItemLedgEntries.RunModal;
                            end;
                    end;
                end;
            11, 12, 13, 14, 15, 16:
                begin // Purchase Line
                    Clear(AvailablePurchLines);
                    AvailablePurchLines.SetCurrentSubType("Entry No." - 11);
                    case ReservEntry2."Source Type" of
                        DATABASE::"Sales Line":
                            begin
                                AvailablePurchLines.SetSalesLine(SalesLine, ReservEntry2);
                                AvailablePurchLines.RunModal;
                            end;
                        DATABASE::"Requisition Line":
                            begin
                                AvailablePurchLines.SetReqLine(ReqLine, ReservEntry2);
                                AvailablePurchLines.RunModal;
                            end;
                        DATABASE::"Purchase Line":
                            begin
                                AvailablePurchLines.SetPurchLine(PurchLine, ReservEntry2);
                                AvailablePurchLines.RunModal;
                            end;
                        DATABASE::"Prod. Order Line":
                            begin
                                AvailablePurchLines.SetProdOrderLine(ProdOrderLine, ReservEntry2);
                                AvailablePurchLines.RunModal;
                            end;
                        DATABASE::"Prod. Order Component":
                            begin
                                AvailablePurchLines.SetProdOrderComponent(ProdOrderComp, ReservEntry2);
                                AvailablePurchLines.RunModal;
                            end;
                        DATABASE::"Planning Component":
                            begin
                                AvailablePurchLines.SetPlanningComponent(PlanningComponent, ReservEntry2);
                                AvailablePurchLines.RunModal;
                            end;
                        DATABASE::"Transfer Line":
                            begin
                                AvailablePurchLines.SetTransferLine(TransLine, ReservEntry2, ReservEntry."Source Subtype");
                                AvailablePurchLines.RunModal;
                            end;
                        DATABASE::"Service Line":
                            begin
                                AvailablePurchLines.SetServiceInvLine(ServiceLine, ReservEntry2);
                                AvailablePurchLines.RunModal;
                            end;
                        DATABASE::"Job Planning Line":
                            begin
                                AvailablePurchLines.SetJobPlanningLine(JobPlanningLine, ReservEntry2);
                                AvailablePurchLines.RunModal;
                            end;
                        DATABASE::"Assembly Header":
                            begin
                                AvailablePurchLines.SetAssemblyHeader(AssemblyHeader, ReservEntry2);
                                AvailablePurchLines.RunModal;
                            end;
                        DATABASE::"Assembly Line":
                            begin
                                AvailablePurchLines.SetAssemblyLine(AssemblyLine, ReservEntry2);
                                AvailablePurchLines.RunModal;
                            end;
                    end;
                end;
            21:
                begin // Requisition Line
                    Clear(AvailableReqLines);
                    case ReservEntry2."Source Type" of
                        DATABASE::"Sales Line":
                            begin
                                AvailableReqLines.SetSalesLine(SalesLine, ReservEntry2);
                                AvailableReqLines.RunModal;
                            end;
                        DATABASE::"Requisition Line":
                            begin
                                AvailableReqLines.SetReqLine(ReqLine, ReservEntry2);
                                AvailableReqLines.RunModal;
                            end;
                        DATABASE::"Purchase Line":
                            begin
                                AvailableReqLines.SetPurchLine(PurchLine, ReservEntry2);
                                AvailableReqLines.RunModal;
                            end;
                        DATABASE::"Prod. Order Line":
                            begin
                                AvailableReqLines.SetProdOrderLine(ProdOrderLine, ReservEntry2);
                                AvailableReqLines.RunModal;
                            end;
                        DATABASE::"Prod. Order Component":
                            begin
                                AvailableReqLines.SetProdOrderComponent(ProdOrderComp, ReservEntry2);
                                AvailableReqLines.RunModal;
                            end;
                        DATABASE::"Planning Component":
                            begin
                                AvailableReqLines.SetPlanningComponent(PlanningComponent, ReservEntry2);
                                AvailableReqLines.RunModal;
                            end;
                        DATABASE::"Transfer Line":
                            begin
                                AvailableReqLines.SetTransferLine(TransLine, ReservEntry2, ReservEntry."Source Subtype");
                                AvailableReqLines.RunModal;
                            end;
                        DATABASE::"Service Line":
                            begin
                                AvailableReqLines.SetServiceInvLine(ServiceLine, ReservEntry2);
                                AvailableReqLines.RunModal;
                            end;
                        DATABASE::"Job Planning Line":
                            begin
                                AvailableJobPlanningLines.SetJobPlanningLine(JobPlanningLine, ReservEntry2);
                                AvailableJobPlanningLines.RunModal;
                            end;
                        DATABASE::"Assembly Header":
                            begin
                                AvailableJobPlanningLines.SetAssemblyHeader(AssemblyHeader, ReservEntry2);
                                AvailableJobPlanningLines.RunModal;
                            end;
                        DATABASE::"Assembly Line":
                            begin
                                AvailableJobPlanningLines.SetAssemblyLine(AssemblyLine, ReservEntry2);
                                AvailableJobPlanningLines.RunModal;
                            end;
                    end;
                end;
            31, 32, 33, 34, 35, 36:
                begin // Sales Line
                    Clear(AvailableSalesLines);
                    AvailableSalesLines.SetCurrentSubType("Entry No." - 31);
                    case ReservEntry2."Source Type" of
                        DATABASE::"Sales Line":
                            begin
                                AvailableSalesLines.SetSalesLine(SalesLine, ReservEntry2);
                                AvailableSalesLines.RunModal;
                            end;
                        DATABASE::"Requisition Line":
                            begin
                                AvailableSalesLines.SetReqLine(ReqLine, ReservEntry2);
                                AvailableSalesLines.RunModal;
                            end;
                        DATABASE::"Purchase Line":
                            begin
                                AvailableSalesLines.SetPurchLine(PurchLine, ReservEntry2);
                                AvailableSalesLines.RunModal;
                            end;
                        DATABASE::"Prod. Order Line":
                            begin
                                AvailableSalesLines.SetProdOrderLine(ProdOrderLine, ReservEntry2);
                                AvailableSalesLines.RunModal;
                            end;
                        DATABASE::"Prod. Order Component":
                            begin
                                AvailableSalesLines.SetProdOrderComponent(ProdOrderComp, ReservEntry2);
                                AvailableSalesLines.RunModal;
                            end;
                        DATABASE::"Planning Component":
                            begin
                                AvailableSalesLines.SetPlanningComponent(PlanningComponent, ReservEntry2);
                                AvailableSalesLines.RunModal;
                            end;
                        DATABASE::"Transfer Line":
                            begin
                                AvailableSalesLines.SetTransferLine(TransLine, ReservEntry2, ReservEntry."Source Subtype");
                                AvailableSalesLines.RunModal;
                            end;
                        DATABASE::"Service Line":
                            begin
                                AvailableSalesLines.SetServiceInvLine(ServiceLine, ReservEntry2);
                                AvailableSalesLines.RunModal;
                            end;
                        DATABASE::"Job Planning Line":
                            begin
                                AvailableSalesLines.SetJobPlanningLine(JobPlanningLine, ReservEntry2);
                                AvailableSalesLines.RunModal;
                            end;
                        DATABASE::"Assembly Header":
                            begin
                                AvailableSalesLines.SetAssemblyHeader(AssemblyHeader, ReservEntry2);
                                AvailableSalesLines.RunModal;
                            end;
                        DATABASE::"Assembly Line":
                            begin
                                AvailableSalesLines.SetAssemblyLine(AssemblyLine, ReservEntry2);
                                AvailableSalesLines.RunModal;
                            end;
                    end;
                end;
            61, 62, 63, 64:
                begin
                    Clear(AvailableProdOrderLines);
                    AvailableProdOrderLines.SetCurrentSubType("Entry No." - 61);
                    case ReservEntry2."Source Type" of
                        DATABASE::"Sales Line":
                            begin
                                AvailableProdOrderLines.SetSalesLine(SalesLine, ReservEntry2);
                                AvailableProdOrderLines.RunModal;
                            end;
                        DATABASE::"Requisition Line":
                            begin
                                AvailableProdOrderLines.SetReqLine(ReqLine, ReservEntry2);
                                AvailableProdOrderLines.RunModal;
                            end;
                        DATABASE::"Purchase Line":
                            begin
                                AvailableProdOrderLines.SetPurchLine(PurchLine, ReservEntry2);
                                AvailableProdOrderLines.RunModal;
                            end;
                        DATABASE::"Prod. Order Line":
                            begin
                                AvailableProdOrderLines.SetProdOrderLine(ProdOrderLine, ReservEntry2);
                                AvailableProdOrderLines.RunModal;
                            end;
                        DATABASE::"Prod. Order Component":
                            begin
                                AvailableProdOrderLines.SetProdOrderComponent(ProdOrderComp, ReservEntry2);
                                AvailableProdOrderLines.RunModal;
                            end;
                        DATABASE::"Planning Component":
                            begin
                                AvailableProdOrderLines.SetPlanningComponent(PlanningComponent, ReservEntry2);
                                AvailableProdOrderLines.RunModal;
                            end;
                        DATABASE::"Transfer Line":
                            begin
                                AvailableProdOrderLines.SetTransferLine(TransLine, ReservEntry2, ReservEntry."Source Subtype");
                                AvailableProdOrderLines.RunModal;
                            end;
                        DATABASE::"Service Line":
                            begin
                                AvailableProdOrderLines.SetServiceInvLine(ServiceLine, ReservEntry2);
                                AvailableProdOrderLines.RunModal;
                            end;
                        DATABASE::"Job Planning Line":
                            begin
                                AvailableProdOrderLines.SetJobPlanningLine(JobPlanningLine, ReservEntry2);
                                AvailableProdOrderLines.RunModal;
                            end;
                        DATABASE::"Assembly Header":
                            begin
                                AvailableProdOrderLines.SetAssemblyHeader(AssemblyHeader, ReservEntry2);
                                AvailableProdOrderLines.RunModal;
                            end;
                        DATABASE::"Assembly Line":
                            begin
                                AvailableProdOrderLines.SetAssemblyLine(AssemblyLine, ReservEntry2);
                                AvailableProdOrderLines.RunModal;
                            end;
                    end;
                end;
            71, 72, 73, 74:
                begin
                    Clear(AvailableProdOrderComps);
                    AvailableProdOrderComps.SetCurrentSubType("Entry No." - 71);
                    case ReservEntry2."Source Type" of
                        DATABASE::"Sales Line":
                            begin
                                AvailableProdOrderComps.SetSalesLine(SalesLine, ReservEntry2);
                                AvailableProdOrderComps.RunModal;
                            end;
                        DATABASE::"Requisition Line":
                            begin
                                AvailableProdOrderComps.SetReqLine(ReqLine, ReservEntry2);
                                AvailableProdOrderComps.RunModal;
                            end;
                        DATABASE::"Purchase Line":
                            begin
                                AvailableProdOrderComps.SetPurchLine(PurchLine, ReservEntry2);
                                AvailableProdOrderComps.RunModal;
                            end;
                        DATABASE::"Prod. Order Line":
                            begin
                                AvailableProdOrderComps.SetProdOrderLine(ProdOrderLine, ReservEntry2);
                                AvailableProdOrderComps.RunModal;
                            end;
                        DATABASE::"Prod. Order Component":
                            begin
                                AvailableProdOrderComps.SetProdOrderComponent(ProdOrderComp, ReservEntry2);
                                AvailableProdOrderComps.RunModal;
                            end;
                        DATABASE::"Planning Component":
                            begin
                                AvailableProdOrderComps.SetPlanningComponent(PlanningComponent, ReservEntry2);
                                AvailableProdOrderComps.RunModal;
                            end;
                        DATABASE::"Transfer Line":
                            begin
                                AvailableProdOrderComps.SetTransferLine(TransLine, ReservEntry2, ReservEntry."Source Subtype");
                                AvailableProdOrderComps.RunModal;
                            end;
                        DATABASE::"Service Line":
                            begin
                                AvailableProdOrderComps.SetServiceInvLine(ServiceLine, ReservEntry2);
                                AvailableProdOrderComps.RunModal;
                            end;
                        DATABASE::"Job Planning Line":
                            begin
                                AvailableProdOrderComps.SetJobPlanningLine(JobPlanningLine, ReservEntry2);
                                AvailableProdOrderComps.RunModal;
                            end;
                        DATABASE::"Assembly Header":
                            begin
                                AvailableProdOrderComps.SetAssemblyHeader(AssemblyHeader, ReservEntry2);
                                AvailableProdOrderComps.RunModal;
                            end;
                        DATABASE::"Assembly Line":
                            begin
                                AvailableProdOrderComps.SetAssemblyLine(AssemblyLine, ReservEntry2);
                                AvailableProdOrderComps.RunModal;
                            end;
                    end;
                end;
            91:
                begin
                    Clear(AvailablePlanningComponents);
                    case ReservEntry2."Source Type" of
                        DATABASE::"Sales Line":
                            begin
                                AvailablePlanningComponents.SetSalesLine(SalesLine, ReservEntry2);
                                AvailablePlanningComponents.RunModal;
                            end;
                        DATABASE::"Requisition Line":
                            begin
                                AvailablePlanningComponents.SetReqLine(ReqLine, ReservEntry2);
                                AvailablePlanningComponents.RunModal;
                            end;
                        DATABASE::"Purchase Line":
                            begin
                                AvailablePlanningComponents.SetPurchLine(PurchLine, ReservEntry2);
                                AvailablePlanningComponents.RunModal;
                            end;
                        DATABASE::"Prod. Order Line":
                            begin
                                AvailablePlanningComponents.SetProdOrderLine(ProdOrderLine, ReservEntry2);
                                AvailablePlanningComponents.RunModal;
                            end;
                        DATABASE::"Prod. Order Component":
                            begin
                                AvailablePlanningComponents.SetProdOrderComponent(ProdOrderComp, ReservEntry2);
                                AvailablePlanningComponents.RunModal;
                            end;
                        DATABASE::"Planning Component":
                            begin
                                AvailablePlanningComponents.SetPlanningComponent(PlanningComponent, ReservEntry2);
                                AvailablePlanningComponents.RunModal;
                            end;
                        DATABASE::"Transfer Line":
                            begin
                                AvailablePlanningComponents.SetTransferLine(TransLine, ReservEntry2, ReservEntry."Source Subtype");
                                AvailablePlanningComponents.RunModal;
                            end;
                        DATABASE::"Service Line":
                            begin
                                AvailablePlanningComponents.SetServiceInvLine(ServiceLine, ReservEntry2);
                                AvailablePlanningComponents.RunModal;
                            end;
                        DATABASE::"Job Planning Line":
                            begin
                                AvailablePlanningComponents.SetJobPlanningLine(JobPlanningLine, ReservEntry2);
                                AvailablePlanningComponents.RunModal;
                            end;
                        DATABASE::"Assembly Header":
                            begin
                                AvailablePlanningComponents.SetAssemblyHeader(AssemblyHeader, ReservEntry2);
                                AvailablePlanningComponents.RunModal;
                            end;
                        DATABASE::"Assembly Line":
                            begin
                                AvailablePlanningComponents.SetAssemblyLine(AssemblyLine, ReservEntry2);
                                AvailablePlanningComponents.RunModal;
                            end;
                    end;
                end;
            101, 102:
                begin
                    Clear(AvailableTransLines);
                    case ReservEntry2."Source Type" of
                        DATABASE::"Sales Line":
                            begin
                                AvailableTransLines.SetSalesLine(SalesLine, ReservEntry2);
                                AvailableTransLines.RunModal;
                            end;
                        DATABASE::"Requisition Line":
                            begin
                                AvailableTransLines.SetReqLine(ReqLine, ReservEntry2);
                                AvailableTransLines.RunModal;
                            end;
                        DATABASE::"Purchase Line":
                            begin
                                AvailableTransLines.SetPurchLine(PurchLine, ReservEntry2);
                                AvailableTransLines.RunModal;
                            end;
                        DATABASE::"Prod. Order Line":
                            begin
                                AvailableTransLines.SetProdOrderLine(ProdOrderLine, ReservEntry2);
                                AvailableTransLines.RunModal;
                            end;
                        DATABASE::"Prod. Order Component":
                            begin
                                AvailableTransLines.SetProdOrderComponent(ProdOrderComp, ReservEntry2);
                                AvailableTransLines.RunModal;
                            end;
                        DATABASE::"Planning Component":
                            begin
                                AvailableTransLines.SetPlanningComponent(PlanningComponent, ReservEntry2);
                                AvailableTransLines.RunModal;
                            end;
                        DATABASE::"Transfer Line":
                            begin
                                AvailableTransLines.SetTransferLine(TransLine, ReservEntry2, ReservEntry."Source Subtype");
                                AvailableTransLines.RunModal;
                            end;
                        DATABASE::"Service Line":
                            begin
                                AvailableTransLines.SetServiceInvLine(ServiceLine, ReservEntry2);
                                AvailableTransLines.RunModal;
                            end;
                        DATABASE::"Job Planning Line":
                            begin
                                AvailableTransLines.SetJobPlanningLine(JobPlanningLine, ReservEntry2);
                                AvailableTransLines.RunModal;
                            end;
                        DATABASE::"Assembly Header":
                            begin
                                AvailableTransLines.SetAssemblyHeader(AssemblyHeader, ReservEntry2);
                                AvailableTransLines.RunModal;
                            end;
                        DATABASE::"Assembly Line":
                            begin
                                AvailableTransLines.SetAssemblyLine(AssemblyLine, ReservEntry2);
                                AvailableTransLines.RunModal;
                            end;
                    end;
                end;
            110:
                begin // Service Line
                    Clear(AvailableServiceLines);
                    AvailableServiceLines.SetCurrentSubType("Entry No." - 109);
                    case ReservEntry2."Source Type" of
                        DATABASE::"Sales Line":
                            begin
                                AvailableServiceLines.SetSalesLine(SalesLine, ReservEntry2);
                                AvailableServiceLines.RunModal;
                            end;
                        DATABASE::"Requisition Line":
                            begin
                                AvailableServiceLines.SetReqLine(ReqLine, ReservEntry2);
                                AvailableServiceLines.RunModal;
                            end;
                        DATABASE::"Purchase Line":
                            begin
                                AvailableServiceLines.SetPurchLine(PurchLine, ReservEntry2);
                                AvailableServiceLines.RunModal;
                            end;
                        DATABASE::"Prod. Order Line":
                            begin
                                AvailableServiceLines.SetProdOrderLine(ProdOrderLine, ReservEntry2);
                                AvailableServiceLines.RunModal;
                            end;
                        DATABASE::"Prod. Order Component":
                            begin
                                AvailableServiceLines.SetProdOrderComponent(ProdOrderComp, ReservEntry2);
                                AvailableServiceLines.RunModal;
                            end;
                        DATABASE::"Planning Component":
                            begin
                                AvailableServiceLines.SetPlanningComponent(PlanningComponent, ReservEntry2);
                                AvailableServiceLines.RunModal;
                            end;
                        DATABASE::"Transfer Line":
                            begin
                                AvailableServiceLines.SetTransferLine(TransLine, ReservEntry2, ReservEntry."Source Subtype");
                                AvailableServiceLines.RunModal;
                            end;
                        DATABASE::"Service Line":
                            begin
                                AvailableServiceLines.SetServInvLine(ServiceLine, ReservEntry2);
                                AvailableServiceLines.RunModal;
                            end;
                        DATABASE::"Job Planning Line":
                            begin
                                AvailableServiceLines.SetJobPlanningLine(JobPlanningLine, ReservEntry2);
                                AvailableServiceLines.RunModal;
                            end;
                        DATABASE::"Assembly Header":
                            begin
                                AvailableServiceLines.SetAssemblyHeader(AssemblyHeader, ReservEntry2);
                                AvailableServiceLines.RunModal;
                            end;
                        DATABASE::"Assembly Line":
                            begin
                                AvailableServiceLines.SetAssemblyLine(AssemblyLine, ReservEntry2);
                                AvailableServiceLines.RunModal;
                            end;
                    end;
                end;
            131, 132, 133, 134:
                begin // Job Planning Line
                    Clear(AvailableJobPlanningLines);
                    AvailableJobPlanningLines.SetCurrentSubType("Entry No." - 131);
                    case ReservEntry2."Source Type" of
                        DATABASE::"Sales Line":
                            begin
                                AvailableJobPlanningLines.SetSalesLine(SalesLine, ReservEntry2);
                                AvailableJobPlanningLines.RunModal;
                            end;
                        DATABASE::"Requisition Line":
                            begin
                                AvailableJobPlanningLines.SetReqLine(ReqLine, ReservEntry2);
                                AvailableJobPlanningLines.RunModal;
                            end;
                        DATABASE::"Purchase Line":
                            begin
                                AvailableJobPlanningLines.SetPurchLine(PurchLine, ReservEntry2);
                                AvailableJobPlanningLines.RunModal;
                            end;
                        DATABASE::"Prod. Order Line":
                            begin
                                AvailableJobPlanningLines.SetProdOrderLine(ProdOrderLine, ReservEntry2);
                                AvailableJobPlanningLines.RunModal;
                            end;
                        DATABASE::"Prod. Order Component":
                            begin
                                AvailableJobPlanningLines.SetProdOrderComponent(ProdOrderComp, ReservEntry2);
                                AvailableJobPlanningLines.RunModal;
                            end;
                        DATABASE::"Planning Component":
                            begin
                                AvailableJobPlanningLines.SetPlanningComponent(PlanningComponent, ReservEntry2);
                                AvailableJobPlanningLines.RunModal;
                            end;
                        DATABASE::"Transfer Line":
                            begin
                                AvailableJobPlanningLines.SetTransferLine(TransLine, ReservEntry2, ReservEntry."Source Subtype");
                                AvailableJobPlanningLines.RunModal;
                            end;
                        DATABASE::"Service Line":
                            begin
                                AvailableJobPlanningLines.SetServLine(ServiceLine, ReservEntry2);
                                AvailableJobPlanningLines.RunModal;
                            end;
                        DATABASE::"Job Planning Line":
                            begin
                                AvailableJobPlanningLines.SetJobPlanningLine(JobPlanningLine, ReservEntry2);
                                AvailableJobPlanningLines.RunModal;
                            end;
                        DATABASE::"Assembly Header":
                            begin
                                AvailableJobPlanningLines.SetAssemblyHeader(AssemblyHeader, ReservEntry2);
                                AvailableJobPlanningLines.RunModal;
                            end;
                        DATABASE::"Assembly Line":
                            begin
                                AvailableJobPlanningLines.SetAssemblyLine(AssemblyLine, ReservEntry2);
                                AvailableJobPlanningLines.RunModal;
                            end;
                    end;
                end;
            141, 142:
                begin // Asm Header
                    Clear(AvailableAssemblyHeaders);
                    AvailableAssemblyHeaders.SetCurrentSubType("Entry No." - 141);
                    case ReservEntry2."Source Type" of
                        DATABASE::"Sales Line":
                            begin
                                AvailableAssemblyHeaders.SetSalesLine(SalesLine, ReservEntry2);
                                AvailableAssemblyHeaders.RunModal;
                            end;
                        DATABASE::"Requisition Line":
                            begin
                                AvailableAssemblyHeaders.SetReqLine(ReqLine, ReservEntry2);
                                AvailableAssemblyHeaders.RunModal;
                            end;
                        DATABASE::"Purchase Line":
                            begin
                                AvailableAssemblyHeaders.SetPurchLine(PurchLine, ReservEntry2);
                                AvailableAssemblyHeaders.RunModal;
                            end;
                        DATABASE::"Prod. Order Line":
                            begin
                                AvailableAssemblyHeaders.SetProdOrderLine(ProdOrderLine, ReservEntry2);
                                AvailableAssemblyHeaders.RunModal;
                            end;
                        DATABASE::"Prod. Order Component":
                            begin
                                AvailableAssemblyHeaders.SetProdOrderComponent(ProdOrderComp, ReservEntry2);
                                AvailableAssemblyHeaders.RunModal;
                            end;
                        DATABASE::"Planning Component":
                            begin
                                AvailableAssemblyHeaders.SetPlanningComponent(PlanningComponent, ReservEntry2);
                                AvailableAssemblyHeaders.RunModal;
                            end;
                        DATABASE::"Transfer Line":
                            begin
                                AvailableAssemblyHeaders.SetTransferLine(TransLine, ReservEntry2, ReservEntry."Source Subtype");
                                AvailableAssemblyHeaders.RunModal;
                            end;
                        DATABASE::"Service Line":
                            begin
                                AvailableAssemblyHeaders.SetServiceInvLine(ServiceLine, ReservEntry2);
                                AvailableAssemblyHeaders.RunModal;
                            end;
                        DATABASE::"Job Planning Line":
                            begin
                                AvailableAssemblyHeaders.SetJobPlanningLine(JobPlanningLine, ReservEntry2);
                                AvailableAssemblyHeaders.RunModal;
                            end;
                        DATABASE::"Assembly Header":
                            begin
                                AvailableAssemblyHeaders.SetAssemblyHeader(AssemblyHeader, ReservEntry2);
                                AvailableAssemblyHeaders.RunModal;
                            end;
                        DATABASE::"Assembly Line":
                            begin
                                AvailableAssemblyHeaders.SetAssemblyLine(AssemblyLine, ReservEntry2);
                                AvailableAssemblyHeaders.RunModal;
                            end;
                    end;
                end;
            151, 152:
                begin // Asm Line
                    Clear(AvailableAssemblyLines);
                    AvailableAssemblyLines.SetCurrentSubType("Entry No." - 151);
                    case ReservEntry2."Source Type" of
                        DATABASE::"Sales Line":
                            begin
                                AvailableAssemblyLines.SetSalesLine(SalesLine, ReservEntry2);
                                AvailableAssemblyLines.RunModal;
                            end;
                        DATABASE::"Requisition Line":
                            begin
                                AvailableAssemblyLines.SetReqLine(ReqLine, ReservEntry2);
                                AvailableAssemblyLines.RunModal;
                            end;
                        DATABASE::"Purchase Line":
                            begin
                                AvailableAssemblyLines.SetPurchLine(PurchLine, ReservEntry2);
                                AvailableAssemblyLines.RunModal;
                            end;
                        DATABASE::"Prod. Order Line":
                            begin
                                AvailableAssemblyLines.SetProdOrderLine(ProdOrderLine, ReservEntry2);
                                AvailableAssemblyLines.RunModal;
                            end;
                        DATABASE::"Prod. Order Component":
                            begin
                                AvailableAssemblyLines.SetProdOrderComponent(ProdOrderComp, ReservEntry2);
                                AvailableAssemblyLines.RunModal;
                            end;
                        DATABASE::"Planning Component":
                            begin
                                AvailableAssemblyLines.SetPlanningComponent(PlanningComponent, ReservEntry2);
                                AvailableAssemblyLines.RunModal;
                            end;
                        DATABASE::"Transfer Line":
                            begin
                                AvailableAssemblyLines.SetTransferLine(TransLine, ReservEntry2, ReservEntry."Source Subtype");
                                AvailableAssemblyLines.RunModal;
                            end;
                        DATABASE::"Service Line":
                            begin
                                AvailableAssemblyLines.SetServiceInvLine(ServiceLine, ReservEntry2);
                                AvailableAssemblyLines.RunModal;
                            end;
                        DATABASE::"Job Planning Line":
                            begin
                                AvailableAssemblyLines.SetJobPlanningLine(JobPlanningLine, ReservEntry2);
                                AvailableAssemblyLines.RunModal;
                            end;
                        DATABASE::"Assembly Header":
                            begin
                                AvailableAssemblyLines.SetAssemblyHeader(AssemblyHeader, ReservEntry2);
                                AvailableAssemblyLines.RunModal;
                            end;
                        DATABASE::"Assembly Line":
                            begin
                                AvailableAssemblyLines.SetAssemblyLine(AssemblyLine, ReservEntry2);
                                AvailableAssemblyLines.RunModal;
                            end;
                    end;
                end;
        end;

        UpdateReservFrom;
    end;

    local procedure DrillDownReservedQuantity()
    begin
        ReservEntry2.Reset;

        ReservEntry2.SetCurrentKey(
          "Item No.", "Source Type", "Source Subtype", "Reservation Status", "Location Code", "Variant Code",
          "Shipment Date", "Expected Receipt Date", "Serial No.", "Lot No.");

        FilterReservEntry(ReservEntry2, Rec);
        PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry2);

        UpdateReservFrom;
    end;

    local procedure DrillDownReservedThisLine()
    var
        ReservEntry3: Record "Reservation Entry";
        LotSNMatch: Boolean;
    begin
        Clear(ReservEntry2);

        ReservEntry2.SetCurrentKey(
          "Item No.", "Source Type", "Source Subtype", "Reservation Status", "Location Code", "Variant Code",
          "Shipment Date", "Expected Receipt Date", "Serial No.", "Lot No.");

        FilterReservEntry(ReservEntry2, Rec);
        if ReservEntry2.Find('-') then
            repeat
                ReservEntry3.Get(ReservEntry2."Entry No.", not ReservEntry2.Positive);

                if ReservEntry.TrackingExists then
                    LotSNMatch := (ReservEntry3."Serial No." = ReservEntry."Serial No.") and
                      (ReservEntry3."Lot No." = ReservEntry."Lot No.")
                else
                    LotSNMatch := true;

                ReservEntry2.Mark((ReservEntry3."Source Type" = ReservEntry."Source Type") and
                  (ReservEntry3."Source Subtype" = ReservEntry."Source Subtype") and
                  (ReservEntry3."Source ID" = ReservEntry."Source ID") and
                  (ReservEntry3."Source Batch Name" = ReservEntry."Source Batch Name") and
                  (ReservEntry3."Source Prod. Order Line" = ReservEntry."Source Prod. Order Line") and
                  (ReservEntry3."Source Ref. No." = ReservEntry."Source Ref. No.") and
                  ((LotSNMatch and HandleItemTracking) or
                   not HandleItemTracking));
            until ReservEntry2.Next = 0;

        ReservEntry2.MarkedOnly(true);
        PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry2);

        UpdateReservFrom;
    end;

    procedure ReservedThisLine(ReservSummEntry2: Record "Entry Summary" temporary) ReservedQuantity: Decimal
    var
        ReservEntry3: Record "Reservation Entry";
    begin
        Clear(ReservEntry2);

        ReservEntry2.SetCurrentKey(
          "Item No.", "Source Type", "Source Subtype", "Reservation Status", "Location Code", "Variant Code",
          "Shipment Date", "Expected Receipt Date", "Serial No.", "Lot No.");
        ReservedQuantity := 0;

        FilterReservEntry(ReservEntry2, ReservSummEntry2);
        if ReservEntry2.Find('-') then
            repeat
                ReservEntry3.Get(ReservEntry2."Entry No.", not ReservEntry2.Positive);
                if (ReservEntry3."Source Type" = ReservEntry."Source Type") and
                   (ReservEntry3."Source Subtype" = ReservEntry."Source Subtype") and
                   (ReservEntry3."Source ID" = ReservEntry."Source ID") and
                   (ReservEntry3."Source Batch Name" = ReservEntry."Source Batch Name") and
                   (ReservEntry3."Source Prod. Order Line" = ReservEntry."Source Prod. Order Line") and
                   (ReservEntry3."Source Ref. No." = ReservEntry."Source Ref. No.") and
                   (((ReservEntry3."Serial No." = ReservEntry."Serial No.") and
                     (ReservEntry3."Lot No." = ReservEntry."Lot No.") and
                     HandleItemTracking) or
                    not HandleItemTracking)
                then
                    ReservedQuantity += ReservEntry2."Quantity (Base)" * CreateReservEntry.SignFactor(ReservEntry2);
            until ReservEntry2.Next = 0;

        exit(ReservedQuantity);
    end;

    local procedure GetSerialLotNo(var ItemTrackingQtyToReserve: Decimal; var ItemTrackingQtyToReserveBase: Decimal)
    var
        Item: Record Item;
        ReservEntry2: Record "Reservation Entry";
        TempReservEntry: Record "Reservation Entry" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        SignFactor: Integer;
    begin
        Item.Get(ReservEntry."Item No.");
        if Item."Item Tracking Code" = '' then
            exit;
        ReservEntry2 := ReservEntry;
        ReservEntry2.SetPointerFilter;
        ItemTrackingMgt.SumUpItemTracking(ReservEntry2, TempTrackingSpecification, true, true);

        if TempTrackingSpecification.Find('-') then begin
            if not Confirm(StrSubstNo(Text006)) then
                exit;
            repeat
                TempReservEntry.TransferFields(TempTrackingSpecification);
                TempReservEntry.Insert;
            until TempTrackingSpecification.Next = 0;

            if PAGE.RunModal(PAGE::"Item Tracking List", TempReservEntry) = ACTION::LookupOK then begin
                ReservEntry."Serial No." := TempReservEntry."Serial No.";
                ReservEntry."Lot No." := TempReservEntry."Lot No.";
                OnGetSerialLotNoOnAfterSetTrackingFields(ReservEntry, TempReservEntry);
                CaptionText += StrSubstNo(Text007, ReservEntry."Serial No.", ReservEntry."Lot No.");
                SignFactor := CreateReservEntry.SignFactor(TempReservEntry);
                ItemTrackingQtyToReserveBase := TempReservEntry."Quantity (Base)" * SignFactor;
                ItemTrackingQtyToReserve :=
                  Round(ItemTrackingQtyToReserveBase / TempReservEntry."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
                HandleItemTracking := true;
            end else
                Error(Text008);
        end;
    end;

    local procedure UpdateNonSpecific()
    begin
        SetFilter("Non-specific Reserved Qty.", '>%1', 0);
        NoteTextVisible := not IsEmpty;
        NonSpecificQty := "Non-specific Reserved Qty.";
        SetRange("Non-specific Reserved Qty.");
    end;

    procedure AutoReserve()
    begin
        if Abs(QtyToReserveBase) - Abs(QtyReservedBase) = 0 then
            Error(Text000);

        ReservMgt.AutoReserve(
          FullAutoReservation, ReservEntry.Description,
          ReservEntry."Shipment Date", QtyToReserve - QtyReserved, QtyToReserveBase - QtyReservedBase);
        if not FullAutoReservation then
            Message(Text001);
        UpdateReservFrom;
    end;

    local procedure GetQtyPerUOMFromSource() QtyPerUOM: Decimal
    begin
        case ReservEntry."Source Type" of
            DATABASE::"Sales Line":
                QtyPerUOM := GetQtyPerUomFromSalesLine;
            DATABASE::"Requisition Line":
                QtyPerUOM := GetQtyPerUomFromReqLine;
            DATABASE::"Purchase Line":
                QtyPerUOM := GetQtyPerUomFromPurchLine;
            DATABASE::"Item Journal Line":
                QtyPerUOM := GetQtyPerUomFromItemJnlLine;
            DATABASE::"Prod. Order Line":
                QtyPerUOM := GetQtyPerUomFromProdOrderLine;
            DATABASE::"Prod. Order Component":
                QtyPerUOM := GetQtyPerUomFromProdOrderComponent;
            DATABASE::"Assembly Header":
                QtyPerUOM := GetQtyPerUomFromAssemblyHeader;
            DATABASE::"Assembly Line":
                QtyPerUOM := GetQtyPerUomFromAssemblyLine;
            DATABASE::"Planning Component":
                QtyPerUOM := GetQtyPerUomFromPlanningComponent;
            DATABASE::"Transfer Line":
                QtyPerUOM := GetQtyPerUomFromTransferLine;
            DATABASE::"Service Line":
                QtyPerUOM := GetQtyPerUomFromServiceLine;
            DATABASE::"Job Planning Line":
                QtyPerUOM := GetQtyPerUomFromJobPlanningLine;
        end;

        OnAfterGetQtyPerUOMFromSource(ReservEntry, QtyPerUOM);
    end;

    local procedure GetQtyPerUomFromSalesLine(): Decimal
    begin
        SalesLine.Find;
        SalesLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        if SalesLine."Document Type" = SalesLine."Document Type"::"Return Order" then begin
            SalesLine."Reserved Quantity" := -SalesLine."Reserved Quantity";
            SalesLine."Reserved Qty. (Base)" := -SalesLine."Reserved Qty. (Base)";
        end;
        QtyReserved := SalesLine."Reserved Quantity";
        QtyReservedBase := SalesLine."Reserved Qty. (Base)";
        QtyToReserve := SalesLine."Outstanding Quantity";
        QtyToReserveBase := SalesLine."Outstanding Qty. (Base)";
        exit(SalesLine."Qty. per Unit of Measure");
    end;

    local procedure GetQtyPerUomFromReqLine(): Decimal
    begin
        ReqLine.Find;
        ReqLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        QtyReserved := ReqLine."Reserved Quantity";
        QtyReservedBase := ReqLine."Reserved Qty. (Base)";
        QtyToReserve := ReqLine.Quantity;
        QtyToReserveBase := ReqLine."Quantity (Base)";
        exit(ReqLine."Qty. per Unit of Measure");
    end;

    local procedure GetQtyPerUomFromPurchLine(): Decimal
    begin
        PurchLine.Find;
        PurchLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        if PurchLine."Document Type" = PurchLine."Document Type"::"Return Order" then begin
            PurchLine."Reserved Quantity" := -PurchLine."Reserved Quantity";
            PurchLine."Reserved Qty. (Base)" := -PurchLine."Reserved Qty. (Base)";
        end;
        QtyReserved := PurchLine."Reserved Quantity";
        QtyReservedBase := PurchLine."Reserved Qty. (Base)";
        QtyToReserve := PurchLine."Outstanding Quantity";
        QtyToReserveBase := PurchLine."Outstanding Qty. (Base)";
        exit(PurchLine."Qty. per Unit of Measure");
    end;

    local procedure GetQtyPerUomFromItemJnlLine(): Decimal
    begin
        ItemJnlLine.Find;
        ItemJnlLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        QtyReserved := ItemJnlLine."Reserved Quantity";
        QtyReservedBase := ItemJnlLine."Reserved Qty. (Base)";
        QtyToReserve := ItemJnlLine.Quantity;
        QtyToReserveBase := ItemJnlLine."Quantity (Base)";
        exit(ItemJnlLine."Qty. per Unit of Measure");
    end;

    local procedure GetQtyPerUomFromProdOrderLine(): Decimal
    begin
        ProdOrderLine.Find;
        ProdOrderLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        QtyReserved := ProdOrderLine."Reserved Quantity";
        QtyReservedBase := ProdOrderLine."Reserved Qty. (Base)";
        QtyToReserve := ProdOrderLine."Remaining Quantity";
        QtyToReserveBase := ProdOrderLine."Remaining Qty. (Base)";
        exit(ProdOrderLine."Qty. per Unit of Measure");
    end;

    local procedure GetQtyPerUomFromProdOrderComponent(): Decimal
    begin
        ProdOrderComp.Find;
        ProdOrderComp.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        QtyReserved := ProdOrderComp."Reserved Quantity";
        QtyReservedBase := ProdOrderComp."Reserved Qty. (Base)";
        QtyToReserve := ProdOrderComp."Remaining Quantity";
        QtyToReserveBase := ProdOrderComp."Remaining Qty. (Base)";
        exit(ProdOrderComp."Qty. per Unit of Measure");
    end;

    local procedure GetQtyPerUomFromAssemblyHeader(): Decimal
    begin
        AssemblyHeader.Find;
        AssemblyHeader.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        QtyReserved := AssemblyHeader."Reserved Quantity";
        QtyReservedBase := AssemblyHeader."Reserved Qty. (Base)";
        QtyToReserve := AssemblyHeader."Remaining Quantity";
        QtyToReserveBase := AssemblyHeader."Remaining Quantity (Base)";
        exit(AssemblyHeader."Qty. per Unit of Measure");
    end;

    local procedure GetQtyPerUomFromAssemblyLine(): Decimal
    begin
        AssemblyLine.Find;
        AssemblyLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        QtyReserved := AssemblyLine."Reserved Quantity";
        QtyReservedBase := AssemblyLine."Reserved Qty. (Base)";
        QtyToReserve := AssemblyLine."Remaining Quantity";
        QtyToReserveBase := AssemblyLine."Remaining Quantity (Base)";
        exit(AssemblyLine."Qty. per Unit of Measure");
    end;

    local procedure GetQtyPerUomFromPlanningComponent(): Decimal
    begin
        PlanningComponent.Find;
        PlanningComponent.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        QtyReserved := PlanningComponent."Reserved Quantity";
        QtyReservedBase := PlanningComponent."Reserved Qty. (Base)";
        QtyToReserve := PlanningComponent."Expected Quantity";
        QtyToReserveBase := PlanningComponent."Expected Quantity (Base)";
        exit(PlanningComponent."Qty. per Unit of Measure");
    end;

    local procedure GetQtyPerUomFromTransferLine(): Decimal
    begin
        TransLine.Find;
        if ReservEntry."Source Subtype" = 0 then begin // Outbound
            TransLine.CalcFields("Reserved Quantity Outbnd.", "Reserved Qty. Outbnd. (Base)");
            QtyReserved := TransLine."Reserved Quantity Outbnd.";
            QtyReservedBase := TransLine."Reserved Qty. Outbnd. (Base)";
            QtyToReserve := TransLine."Outstanding Quantity";
            QtyToReserveBase := TransLine."Outstanding Qty. (Base)";
        end else begin // Inbound
            TransLine.CalcFields("Reserved Quantity Inbnd.", "Reserved Qty. Inbnd. (Base)");
            QtyReserved := TransLine."Reserved Quantity Inbnd.";
            QtyReservedBase := TransLine."Reserved Qty. Inbnd. (Base)";
            QtyToReserve := TransLine."Outstanding Quantity";
            QtyToReserveBase := TransLine."Outstanding Qty. (Base)";
        end;
        exit(TransLine."Qty. per Unit of Measure");
    end;

    local procedure GetQtyPerUomFromServiceLine(): Decimal
    begin
        ServiceLine.Find;
        ServiceLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        QtyReserved := ServiceLine."Reserved Quantity";
        QtyReservedBase := ServiceLine."Reserved Qty. (Base)";
        QtyToReserve := ServiceLine."Outstanding Quantity";
        QtyToReserveBase := ServiceLine."Outstanding Qty. (Base)";
        exit(ServiceLine."Qty. per Unit of Measure");
    end;

    local procedure GetQtyPerUomFromJobPlanningLine(): Decimal
    begin
        JobPlanningLine.Find;
        if JobPlanningLine.UpdatePlanned then begin
            JobPlanningLine.Modify(true);
            Commit;
        end;
        JobPlanningLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        QtyReserved := JobPlanningLine."Reserved Quantity";
        QtyReservedBase := JobPlanningLine."Reserved Qty. (Base)";
        QtyToReserve := JobPlanningLine."Remaining Qty.";
        QtyToReserveBase := JobPlanningLine."Remaining Qty. (Base)";
        exit(JobPlanningLine."Qty. per Unit of Measure");
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterGetQtyPerUOMFromSource(ReservationEntry: Record "Reservation Entry"; var QtyPerUOM: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRelatesToSummEntry(FromEntrySummary: Record "Entry Summary"; var FilterReservEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterUpdateReservFrom(var EntrySummary: Record "Entry Summary")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSalesLine(var EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReqLine(var EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPurchLine(var EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTransLine(var EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetServiceLine(var EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetProdOrderLine(var EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetProdOrderComponent(var EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetItemJnlLine(var EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetJobPlanningLine(var EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetAssemblyHeader(var EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetAssemblyLine(var EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPlanningComponent(var EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFilterReservEntryOnAfterFilterSource(var ReservationEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSerialLotNoOnAfterSetTrackingFields(var ReservationEntry: Record "Reservation Entry"; TempReservationEntry: Record "Reservation Entry" temporary)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnUpdateReservMgt(var ReservationEntry: Record "Reservation Entry"; var ReservationManagement: Codeunit "Reservation Management")
    begin
    end;
}

