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
                        UpdateReservFrom();
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
                        ReservEntry2.SetPointerFilter();
                        ReservEntry2.SetRange("Reservation Status", ReservEntry2."Reservation Status"::Reservation);
                        ReservEntry2.SetRange("Disallow Cancellation", false);
                        if ReservEntry2.FindSet then
                            repeat
                                ReservEntry3.Get(ReservEntry2."Entry No.", not ReservEntry2.Positive);
                                if RelatesToSummEntry(ReservEntry3, Rec) then begin
                                    ReservEngineMgt.CancelReservation(ReservEntry2);
                                    RecordsFound := true;
                                end;
                            until ReservEntry2.Next() = 0;

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
        ReservMgt: Codeunit "Reservation Management";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        UOMMgt: Codeunit "Unit of Measure Management";
        SourceRecRef: RecordRef;
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
        ReservConfirmQst: Label 'Do you want to reserve specific tracking numbers?';
        Text008: Label 'Action canceled.';
        Text009: Label '%1 of the %2 are nonspecific and may be available.';
        [InDataSet]
        NoteTextVisible: Boolean;

    procedure SetReservSource(CurrentRecordVar: Variant)
    begin
        SourceRecRef.GetTable(CurrentRecordVar);
        SetReservSource(SourceRecRef, 0);
    end;

    procedure SetReservSource(CurrentRecordVar: Variant; Direction: Enum "Transfer Direction")
    begin
        SourceRecRef.GetTable(CurrentRecordVar);
        SetReservSource(SourceRecRef, Direction);
    end;

    procedure SetReservSource(CurrentSourceRecRef: RecordRef; Direction: Enum "Transfer Direction")
    begin
        SourceRecRef := CurrentSourceRecRef;

        OnSetReservSource(SourceRecRef, ReservEntry, CaptionText, Direction);

        UpdateReservFrom();

        // Invoke events for compatibility with 15.X, to be removed after obsoleting events below
        case SourceRecRef.Number of
            DATABASE::"Sales Line":
                OnAfterSetSalesLine(Rec, ReservEntry);
            DATABASE::"Requisition Line":
                OnAfterSetReqLine(Rec, ReservEntry);
            DATABASE::"Purchase Line":
                OnAfterSetPurchLine(Rec, ReservEntry);
            DATABASE::"Item Journal Line":
                OnAfterSetItemJnlLine(Rec, ReservEntry);
            DATABASE::"Prod. Order Line":
                OnAfterSetProdOrderLine(Rec, ReservEntry);
            DATABASE::"Prod. Order Component":
                OnAfterSetProdOrderComponent(Rec, ReservEntry);
            DATABASE::"Assembly Header":
                OnAfterSetAssemblyHeader(Rec, ReservEntry);
            DATABASE::"Assembly Line":
                OnAfterSetAssemblyLine(Rec, ReservEntry);
            DATABASE::"Planning Component":
                OnAfterSetPlanningComponent(Rec, ReservEntry);
            DATABASE::"Service Line":
                OnAfterSetServiceLine(Rec, ReservEntry);
            DATABASE::"Job Planning Line":
                OnAfterSetJobPlanningLine(Rec, ReservEntry);
            DATABASE::"Transfer Line":
                OnAfterSetTransLine(Rec, ReservEntry);
        end;
    end;

    [Obsolete('Replaced by SetReservSource procedure.','16.0')]
    procedure SetSalesLine(var CurrentSalesLine: Record "Sales Line")
    begin
        SourceRecRef.GetTable(CurrentSalesLine);
        SetReservSource(SourceRecRef, 0);
    end;

    [Obsolete('Replaced by SetReservSource procedure.','16.0')]
    procedure SetReqLine(var CurrentReqLine: Record "Requisition Line")
    begin
        SourceRecRef.GetTable(CurrentReqLine);
        SetReservSource(SourceRecRef, 0);
    end;

    [Obsolete('Replaced by SetReservSource procedure.','16.0')]
    procedure SetPurchLine(var CurrentPurchLine: Record "Purchase Line")
    begin
        SourceRecRef.GetTable(CurrentPurchLine);
        SetReservSource(SourceRecRef, 0);
    end;

    [Obsolete('Replaced by SetReservSource procedure.','16.0')]
    procedure SetItemJnlLine(var CurrentItemJnlLine: Record "Item Journal Line")
    begin
        SourceRecRef.GetTable(CurrentItemJnlLine);
        SetReservSource(SourceRecRef, 0);
    end;

    [Obsolete('Replaced by SetReservSource procedure.','16.0')]
    procedure SetProdOrderLine(var CurrentProdOrderLine: Record "Prod. Order Line")
    begin
        SourceRecRef.GetTable(CurrentProdOrderLine);
        SetReservSource(SourceRecRef, 0);
    end;

    [Obsolete('Replaced by SetReservSource procedure.','16.0')]
    procedure SetProdOrderComponent(var CurrentProdOrderComp: Record "Prod. Order Component")
    begin
        SourceRecRef.GetTable(CurrentProdOrderComp);
        SetReservSource(SourceRecRef, 0);
    end;

    [Obsolete('Replaced by SetReservSource procedure.','16.0')]
    procedure SetAssemblyHeader(var CurrentAssemblyHeader: Record "Assembly Header")
    begin
        SourceRecRef.GetTable(CurrentAssemblyHeader);
        SetReservSource(SourceRecRef, 0);
    end;

    [Obsolete('Replaced by SetReservSource procedure.','16.0')]
    procedure SetAssemblyLine(var CurrentAssemblyLine: Record "Assembly Line")
    begin
        SourceRecRef.GetTable(CurrentAssemblyLine);
        SetReservSource(SourceRecRef, 0);
    end;

    [Obsolete('Replaced by SetReservSource procedure.','16.0')]
    procedure SetPlanningComponent(var CurrentPlanningComponent: Record "Planning Component")
    begin
        SourceRecRef.GetTable(CurrentPlanningComponent);
        SetReservSource(SourceRecRef, 0);
    end;

    [Obsolete('Replaced by SetReservSource procedure.','16.0')]
    procedure SetTransLine(CurrentTransLine: Record "Transfer Line"; Direction: Option Outbound,Inbound)
    begin
        SourceRecRef.GetTable(CurrentTransLine);
        SetReservSource(SourceRecRef, Direction);
    end;

    [Obsolete('Replaced by SetReservSource procedure.','16.0')]
    procedure SetServiceLine(var CurrentServiceLine: Record "Service Line")
    begin
        SourceRecRef.GetTable(CurrentServiceLine);
        SetReservSource(SourceRecRef, 0);
    end;

    [Obsolete('Replaced by SetReservSource procedure.','16.0')]
    procedure SetJobPlanningLine(var CurrentJobPlanningLine: Record "Job Planning Line")
    begin
        SourceRecRef.GetTable(CurrentJobPlanningLine);
        SetReservSource(SourceRecRef, 0);
    end;

    procedure SetReservEntry(ReservEntry2: Record "Reservation Entry")
    begin
        ReservEntry := ReservEntry2;
        UpdateReservMgt();
    end;

    local procedure FilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        FilterReservEntry.SetRange("Item No.", ReservEntry."Item No.");

        OnFilterReservEntry(FilterReservEntry, ReservEntrySummary);

        OnFilterReservEntryOnAfterFilterSource(FilterReservEntry, ReservEntrySummary, ReservEntry);

        FilterReservEntry.SetRange("Reservation Status", FilterReservEntry."Reservation Status"::Reservation);
        FilterReservEntry.SetRange("Location Code", ReservEntry."Location Code");
        FilterReservEntry.SetRange("Variant Code", ReservEntry."Variant Code");
        if ReservEntry.TrackingExists then
            FilterReservEntry.SetTrackingFilterFromReservEntry(ReservEntry);
        FilterReservEntry.SetRange(Positive, ReservMgt.IsPositive);
    end;

    local procedure RelatesToSummEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary"): Boolean
    var
        IsHandled: Boolean;
        IsRelated: Boolean;
    begin
        IsHandled := false;
        OnAfterRelatesToSummEntry(ReservEntrySummary, FilterReservEntry, IsHandled);
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

        OnGetQtyPerUOMFromSourceRecRef(
            SourceRecRef, QtyPerUOM, QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase, ReservEntry);

        OnAfterGetQtyPerUOMFromSource(ReservEntry, QtyPerUOM);

        UpdateReservMgt();
        ReservMgt.UpdateStatistics(Rec, ReservEntry."Shipment Date", HandleItemTracking);

        if HandleItemTracking then begin
            EntrySummary := Rec;
            QtyReservedBase := 0;
            if FindSet then
                repeat
                    QtyReservedBase += ReservedThisLine(Rec);
                until Next() = 0;
            QtyReservedIT := Round(QtyReservedBase / QtyPerUOM, UOMMgt.QtyRndPrecision);
            if Abs(QtyReserved - QtyReservedIT) > UOMMgt.QtyRndPrecision then
                QtyReserved := QtyReservedIT;
            QtyToReserveBase := ItemTrackingQtyToReserveBase;
            if Abs(ItemTrackingQtyToReserve - QtyToReserve) > UOMMgt.QtyRndPrecision then
                QtyToReserve := ItemTrackingQtyToReserve;
            Rec := EntrySummary;
        end;

        UpdateNonSpecific(); // Late Binding

        OnAfterUpdateReservFrom(Rec);

        if FormIsOpen then
            CurrPage.Update();
    end;

    local procedure UpdateReservMgt()
    begin
        Clear(ReservMgt);
        ReservMgt.SetReservSource(SourceRecRef, ReservEntry."Source Subtype");
        OnUpdateReservMgt(ReservEntry, ReservMgt);
        ReservMgt.SetTrackingFromReservEntry(ReservEntry);
    end;

    local procedure DrillDownTotalQuantity()
    var
        Location: Record Location;
        AvailableItemTrackingLines: Page "Avail. - Item Tracking Lines";
    begin
        if HandleItemTracking and ("Entry No." <> 1) then begin
            Clear(AvailableItemTrackingLines);
            AvailableItemTrackingLines.SetItemTrackingLine(
                "Table ID", "Source Subtype", ReservEntry, ReservMgt.IsPositive, ReservEntry."Shipment Date");
            AvailableItemTrackingLines.RunModal;
            exit;
        end;

        ReservEntry2 := ReservEntry;
        if not Location.Get(ReservEntry2."Location Code") then
            Clear(Location);

        OnDrillDownTotalQuantity(SourceRecRef, Rec, ReservEntry2, Location, QtyToReserveBase - QtyReservedBase);

        UpdateReservFrom();
    end;

    local procedure DrillDownReservedQuantity()
    begin
        ReservEntry2.Reset();

        ReservEntry2.SetCurrentKey(
          "Item No.", "Source Type", "Source Subtype", "Reservation Status", "Location Code", "Variant Code",
          "Shipment Date", "Expected Receipt Date", "Serial No.", "Lot No.");

        FilterReservEntry(ReservEntry2, Rec);
        PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry2);

        UpdateReservFrom();
    end;

    local procedure DrillDownReservedThisLine()
    var
        ReservEntry3: Record "Reservation Entry";
        TrackingMatch: Boolean;
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
                    TrackingMatch := ReservEntry3.HasSameTracking(ReservEntry)
                else
                    TrackingMatch := true;

                ReservEntry2.Mark(
                  ReservEntry3.HasSamePointer(ReservEntry) and
                  ((TrackingMatch and HandleItemTracking) or not HandleItemTracking));
            until ReservEntry2.Next() = 0;

        ReservEntry2.MarkedOnly(true);
        PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry2);

        UpdateReservFrom();
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
                if ReservEntry3.HasSamePointer(ReservEntry) and
                   ((ReservEntry3.HasSameTracking(ReservEntry) and HandleItemTracking) or not HandleItemTracking)
                then
                    ReservedQuantity += ReservEntry2."Quantity (Base)" * CreateReservEntry.SignFactor(ReservEntry2);
            until ReservEntry2.Next() = 0;

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
        ReservEntry2.SetPointerFilter();
        ItemTrackingMgt.SumUpItemTracking(ReservEntry2, TempTrackingSpecification, true, true);

        if TempTrackingSpecification.Find('-') then begin
            if not Confirm(StrSubstNo(ReservConfirmQst, true)) then
                exit;
            repeat
                TempReservEntry.TransferFields(TempTrackingSpecification);
                TempReservEntry.Insert();
            until TempTrackingSpecification.Next() = 0;

            if PAGE.RunModal(PAGE::"Item Tracking List", TempReservEntry) = ACTION::LookupOK then begin
                ReservEntry.CopyTrackingFromReservEntry(TempReservEntry);
                OnGetSerialLotNoOnAfterSetTrackingFields(ReservEntry, TempReservEntry);
                CaptionText += StrSubstNo(ReservConfirmQst, ReservEntry.GetTrackingText());
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
        NoteTextVisible := not IsEmpty();
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
        UpdateReservFrom();
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
    local procedure OnDrillDownTotalQuantity(SourceRecRef: RecordRef; EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry"; Location: Record Location; MaxQtyToReserve: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; ReservEntry: Record "Reservation Entry")
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

    [IntegrationEvent(false, false)]
    local procedure OnSetReservSource(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text; Direction: Integer)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnUpdateReservMgt(var ReservationEntry: Record "Reservation Entry"; var ReservationManagement: Codeunit "Reservation Management")
    begin
    end;
}

