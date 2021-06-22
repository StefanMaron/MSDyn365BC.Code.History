page 504 "Available - Item Ledg. Entries"
{
    Caption = 'Available - Item Ledg. Entries';
    DataCaptionExpression = CaptionText;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    Permissions = TableData "Item Ledger Entry" = rm;
    SourceTable = "Item Ledger Entry";
    SourceTableView = SORTING("Item No.", Open);

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Entry Type"; "Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which type of transaction that the entry is created from.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number on the entry. The document is the voucher that the entry was based on, for example, a receipt.';
                }
                field("Serial No."; "Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a serial number if the posted item carries such a number.';
                    Visible = false;
                }
                field("Lot No."; "Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a lot number if the posted item carries such a number.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code for the location that the entry is linked to.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Remaining Quantity"; "Remaining Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity in the Quantity field that remains to be processed.';
                }
                field("Reserved Quantity"; "Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the item on the line have been reserved.';
                }
                field(QtyToReserve; QtyToReserve)
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
                    ToolTip = 'Specifies the quantity of the item that is reserved from the item ledger entry, for the current line or entry.';

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
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
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
                        ShowDimensions;
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
                action(Reserve)
                {
                    ApplicationArea = Reservation;
                    Caption = '&Reserve';
                    Image = Reserve;
                    ToolTip = 'Reserve the quantity that is required on the document line that you opened this window for.';

                    trigger OnAction()
                    var
                        NewQtyReserved2: Decimal;
                    begin
                        ReservEntry.LockTable();
                        UpdateReservMgt;
                        GetReservationQty(QtyReserved, QtyToReserve);
                        ReservMgt.CalculateRemainingQty(NewQtyReserved2, NewQtyReserved);
                        if MaxQtyDefined and (Abs(MaxQtyToReserve) < Abs(NewQtyReserved)) then
                            NewQtyReserved := MaxQtyToReserve;

                        ReservMgt.CopySign(NewQtyReserved, QtyToReserve);
                        if NewQtyReserved <> 0 then begin
                            OnBeforeCreateReservation(ReservEntry, "Lot No.", "Serial No.");
                            if Abs(NewQtyReserved) > Abs(QtyToReserve) then begin
                                CreateReservation(QtyToReserve);
                                MaxQtyToReserve := MaxQtyToReserve - QtyToReserve;
                            end else begin
                                CreateReservation(NewQtyReserved);
                                MaxQtyToReserve := MaxQtyToReserve - NewQtyReserved;
                            end;
                            if MaxQtyToReserve < 0 then
                                MaxQtyToReserve := 0;
                        end else
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

                        GetReservationQty(QtyReserved, QtyToReserve);

                        ReservEntry2.Copy(ReservEntry);
                        if ReservMgt.IsPositive then
                            SetReservationFilters(ReservEntry2)
                        else
                            Error(Text99000000);
                        ReservEntry2.SetRange("Expected Receipt Date");
                        if ReservEntry2.Find('-') then begin
                            UpdateReservMgt;
                            repeat
                                ReservEngineMgt.CancelReservation(ReservEntry2);
                            until ReservEntry2.Next = 0;

                            TotalAvailQty := TotalAvailQty + QtyReserved;
                            MaxQtyToReserve := MaxQtyToReserve + QtyReserved;
                            UpdateReservFrom;
                        end;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        GetReservationQty(QtyReserved, QtyToReserve);
    end;

    trigger OnOpenPage()
    begin
        ReservEntry.TestField("Source Type");

        SetFilters;
    end;

    var
        Text000: Label 'Fully reserved.';
        Text001: Label 'Do you want to cancel the reservation?';
        Text002: Label 'Reservation cannot be carried out because the available quantity is already allocated in a warehouse.';
        Text99000000: Label 'You can only cancel reservations to inventory.';
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        ReservMgt: Codeunit "Reservation Management";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        SourceRecRef: RecordRef;
        QtyToReserve: Decimal;
        QtyReserved: Decimal;
        NewQtyReserved: Decimal;
        TotalAvailQty: Decimal;
        MaxQtyToReserve: Decimal;
        MaxQtyDefined: Boolean;
        CaptionText: Text;

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
    procedure SetServiceLine(var CurrentServiceLine: Record "Service Line"; CurrentReservEntry: Record "Reservation Entry")
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

    procedure SetTotalAvailQty(TotalAvailQty2: Decimal)
    begin
        TotalAvailQty := TotalAvailQty2;
    end;

    procedure SetMaxQtyToReserve(NewMaxQtyToReserve: Decimal)
    begin
        MaxQtyToReserve := NewMaxQtyToReserve;
        MaxQtyDefined := true;
    end;

    [Obsolete('Replaced by SetSource procedure.','16.0')]
    procedure SetAssemblyLine(var CurrentAsmLine: Record "Assembly Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentAsmLine);
        SetSource(SourceRecRef, CurrentReservEntry, 0);
    end;

    [Obsolete('Replaced by SetSource procedure.','16.0')]
    procedure SetAssemblyHeader(var CurrentAsmHeader: Record "Assembly Header"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentAsmHeader);
        SetSource(SourceRecRef, CurrentReservEntry, 0);
    end;

    local procedure CreateReservation(var ReserveQuantity: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
    begin
        TestField("Drop Shipment", false);
        TestField("Item No.", ReservEntry."Item No.");
        TestField("Variant Code", ReservEntry."Variant Code");
        TestField("Location Code", ReservEntry."Location Code");

        if TotalAvailQty < 0 then begin
            ReserveQuantity := 0;
            exit;
        end;

        if TotalAvailQty < ReserveQuantity then
            ReserveQuantity := TotalAvailQty;
        TotalAvailQty := TotalAvailQty - ReserveQuantity;

        if (TotalAvailQty = 0) and
           (ReserveQuantity = 0) and
           (QtyToReserve <> 0)
        then
            Error(Text002);

        UpdateReservMgt;
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Item Ledger Entry", 0, '', '', 0, "Entry No.",
          "Variant Code", "Location Code", "Serial No.", "Lot No.", "Qty. per Unit of Measure");
        ReservMgt.CreateReservation(
          ReservEntry.Description, 0D, 0, ReserveQuantity, TrackingSpecification);
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
        ReservMgt.SetTrackingFromReservEntry(ReservEntry);

        OnAfterUpdateReservMgt(ReservEntry);
    end;

    local procedure GetReservedQtyInLine(): Decimal
    begin
        ReservEntry2.Reset();
        SetReservationFilters(ReservEntry2);
        ReservEntry2.SetRange("Reservation Status", ReservEntry2."Reservation Status"::Reservation);
        exit(ReservMgt.MarkReservConnection(ReservEntry2, ReservEntry));
    end;

    local procedure SetFilters()
    var
        ItemTrackingType: Enum "Item Tracking Type";
        FieldFilter: Text[80];
    begin
        Reset();
        SetRange("Item No.", ReservEntry."Item No.");
        SetRange("Variant Code", ReservEntry."Variant Code");
        SetRange("Location Code", ReservEntry."Location Code");
        SetRange("Drop Shipment", false);
        SetRange(Open, true);
        if ReservEntry.FieldFilterNeeded(FieldFilter, ReservMgt.IsPositive, ItemTrackingType::"Lot No.") then
            SetFilter("Lot No.", FieldFilter);
        if ReservEntry.FieldFilterNeeded(FieldFilter, ReservMgt.IsPositive, ItemTrackingType::"Serial No.") then
            SetFilter("Serial No.", FieldFilter);
        if ReservMgt.IsPositive() then begin
            SetRange(Positive, true);
            SetFilter("Remaining Quantity", '>0');
        end else begin
            SetRange(Positive, false);
            SetFilter("Remaining Quantity", '<0');
        end;

        OnAfterSetFilters(Rec, ReservEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilters(var ItemLedgerEntry: Record "Item Ledger Entry"; ReservationEntry: Record "Reservation Entry")
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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateReservation(ReservationEntry: Record "Reservation Entry"; LotNo: Code[50]; SerialNo: Code[50])
    begin
    end;
}

