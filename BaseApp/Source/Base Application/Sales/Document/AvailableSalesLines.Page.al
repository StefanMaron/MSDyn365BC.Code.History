namespace Microsoft.Sales.Document;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using Microsoft.Utilities;
using System.Utilities;

page 499 "Available - Sales Lines"
{
    Caption = 'Available - Sales Lines';
    DataCaptionExpression = CaptionText;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    Permissions = TableData "Sales Line" = rm;
    SourceTable = "Sales Line";
    SourceTableView = sorting("Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Shipment Date");

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document that you are about to create.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the inventory location from which the items sold should be picked and where the inventory decrease is registered.';
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                }
                field("Outstanding Qty. (Base)"; Rec."Outstanding Qty. (Base)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the outstanding quantity expressed in the base units of measure.';
                }
                field("Reserved Qty. (Base)"; Rec."Reserved Qty. (Base)")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies the reserved quantity of the item expressed in base units of measure.';
                }
                field(QtyToReserveBase; QtyToReserveBase)
                {
                    ApplicationArea = Reservation;
                    Caption = 'Available Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of the item that is available for reservation.';
                }
                field(ReservedQuantity; GetReservedQtyInLine())
                {
                    ApplicationArea = Reservation;
                    Caption = 'Current Reserved Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item that is reserved from the sales line for the current line or entry.';

                    trigger OnDrillDown()
                    begin
                        ReservEntry2.Reset();
                        Rec.SetReservationFilters(ReservEntry2);
                        ReservEntry2.SetRange("Reservation Status", ReservEntry2."Reservation Status"::Reservation);
                        ReservMgt.MarkReservConnection(ReservEntry2, ReservEntry);
                        PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry2);
                        UpdateReservFrom();
                        CurrPage.Update();
                    end;
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies which work type the resource applies to when the sale is related to a project.';
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
                    ToolTip = 'Reserve the quantity that is required on the document line that you opened this window for.';

                    trigger OnAction()
                    begin
                        ReservEntry.LockTable();
                        UpdateReservMgt();
                        Rec.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
                        QtyToReserve -= QtyReserved;
                        QtyToReserveBase -= QtyReservedBase;
                        ReservMgt.CalculateRemainingQty(NewQtyReserved, NewQtyReservedBase);
                        ReservMgt.CopySign(NewQtyReservedBase, QtyToReserveBase);
                        ReservMgt.CopySign(NewQtyReserved, QtyToReserve);
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
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if not ConfirmManagement.GetResponseOrDefault(Text001, true) then
                            exit;

                        ReservEntry2.Copy(ReservEntry);
                        Rec.SetReservationFilters(ReservEntry2);
                        if ReservEntry2.Find('-') then begin
                            UpdateReservMgt();
                            repeat
                                ReservEngineMgt.CancelReservation(ReservEntry2);
                            until ReservEntry2.Next() = 0;

                            UpdateReservFrom();
                        end;
                    end;
                }
                action(ShowDocument)
                {
                    ApplicationArea = Planning;
                    Caption = '&Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the information on the line comes from.';

                    trigger OnAction()
                    var
                        SalesHeader: Record "Sales Header";
                        PageManagement: Codeunit "Page Management";
                    begin
                        SalesHeader.Get(Rec."Document Type", Rec."Document No.");
                        PageManagement.PageRun(SalesHeader);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Reserve_Promoted; Reserve)
                {
                }
                actionref(CancelReservation_Promoted; CancelReservation)
                {
                }
                actionref(ShowDocument_Promoted; ShowDocument)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
    end;

    trigger OnOpenPage()
    begin
        ReservEntry.TestField("Source Type");

        SetFilters();
    end;

    var
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        ReservMgt: Codeunit "Reservation Management";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        SourceRecRef: RecordRef;
        QtyReserved: Decimal;
        QtyReservedBase: Decimal;
        NewQtyReserved: Decimal;
        NewQtyReservedBase: Decimal;
        CaptionText: Text;
        CurrentSubType: Option;

#pragma warning disable AA0074
        Text000: Label 'Fully reserved.';
        Text001: Label 'Do you want to cancel the reservation?';
#pragma warning disable AA0470
        Text003: Label 'Available Quantity is %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        QtyToReserve: Decimal;
        QtyToReserveBase: Decimal;

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

    local procedure CreateReservation(ReserveQuantity: Decimal; ReserveQuantityBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
    begin
        if Abs(Rec."Outstanding Qty. (Base)") + Rec."Reserved Qty. (Base)" < ReserveQuantityBase then
            Error(Text003, Abs(Rec."Outstanding Qty. (Base)") + Rec."Reserved Qty. (Base)");

        CheckSalesLine();

        TrackingSpecification.InitTrackingSpecification(
            Database::"Sales Line", Rec."Document Type".AsInteger(), Rec."Document No.", '', 0, Rec."Line No.",
            Rec."Variant Code", Rec."Location Code", Rec."Qty. per Unit of Measure");
        ReservMgt.CreateReservation(
          ReservEntry.Description, Rec."Shipment Date", ReserveQuantity, ReserveQuantityBase, TrackingSpecification);
        UpdateReservFrom();
    end;

    local procedure CheckSalesLine()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesLine(Rec, ReservEntry, IsHandled);
        if IsHandled then
            exit;

        Rec.TestField("Job No.", '');
        Rec.TestField("Drop Shipment", false);
        Rec.TestField("No.", ReservEntry."Item No.");
        Rec.TestField("Variant Code", ReservEntry."Variant Code");
        Rec.TestField("Location Code", ReservEntry."Location Code");
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

    protected procedure GetReservedQtyInLine(): Decimal
    begin
        ReservEntry2.Reset();
        Rec.SetReservationFilters(ReservEntry2);
        ReservEntry2.SetRange("Reservation Status", ReservEntry2."Reservation Status"::Reservation);
        exit(ReservMgt.MarkReservConnection(ReservEntry2, ReservEntry));
    end;

    procedure SetCurrentSubType(SubType: Option)
    begin
        CurrentSubType := SubType;
    end;

    local procedure SetFilters()
    begin
        Rec.SetRange("Document Type", CurrentSubType);
        Rec.SetRange(Type, Rec.Type::Item);
        Rec.SetRange("No.", ReservEntry."Item No.");
        Rec.SetRange("Variant Code", ReservEntry."Variant Code");
        Rec.SetRange("Job No.", '');
        Rec.SetRange("Drop Shipment", false);
        Rec.SetRange("Location Code", ReservEntry."Location Code");
        Rec.SetFilter("Shipment Date", ReservMgt.GetAvailabilityFilter(ReservEntry."Shipment Date"));
        case CurrentSubType of
            0, 1, 2, 4:
                if ReservMgt.IsPositive() then
                    Rec.SetFilter("Quantity (Base)", '<0')
                else
                    Rec.SetFilter("Quantity (Base)", '>0');
            3, 5:
                if not ReservMgt.IsPositive() then
                    Rec.SetFilter("Quantity (Base)", '<0')
                else
                    Rec.SetFilter("Quantity (Base)", '>0');
        end;

        OnAfterSetFilters(Rec, ReservEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilters(var SalesLine: Record "Sales Line"; ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateReservFrom(var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateReservMgt(var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesLine(SalesLine: Record "Sales Line"; ReservationEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;
}

