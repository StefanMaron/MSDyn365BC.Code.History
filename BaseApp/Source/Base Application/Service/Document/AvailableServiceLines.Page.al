namespace Microsoft.Service.Document;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using System.Utilities;

page 5999 "Available - Service Lines"
{
    Caption = 'Available - Service Lines';
    DataCaptionExpression = CaptionText;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    Permissions = TableData "Service Line" = rm;
    SourceTable = "Service Line";
    SourceTableView = sorting(Type, "No.", "Variant Code", "Location Code", "Needed by Date", "Document Type", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service order number associated with this line.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the inventory location from where the items on the line should be taken and where they should be registered.';
                }
                field("Needed by Date"; Rec."Needed by Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when you require the item to be available for a service order.';
                }
                field("Outstanding Qty. (Base)"; Rec."Outstanding Qty. (Base)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the quantity of registered items, resource time, costs, or payments to the general ledger account that have not been shipped.';
                }
                field("Reserved Qty. (Base)"; Rec."Reserved Qty. (Base)")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of registered items that have been reserved.';
                }
                field(QtyToReserveBase; QtyToReserveBase)
                {
                    ApplicationArea = Service;
                    Caption = 'Available Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of the item that is available.';
                }
                field(ReservedQuantity; GetReservedQtyInLine())
                {
                    ApplicationArea = Reservation;
                    Caption = 'Current Reserved Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item that is reserved for the document type.';

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
                        UpdateReservMgt();
                        Rec.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
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
                    ApplicationArea = Service;
                    Caption = '&Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the information on the line comes from.';

                    trigger OnAction()
                    var
                        ServiceHeader: Record "Service Header";
                    begin
                        ServiceHeader.Get(Rec."Document Type", Rec."Document No.");
                        PAGE.Run(PAGE::"Service Order", ServiceHeader);
                    end;
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

        Text000: Label 'Fully reserved.';
        Text001: Label 'Do you want to cancel the reservation?';
        Text002: Label 'The available quantity is %1.';

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
            Error(Text002, Abs(Rec."Outstanding Qty. (Base)") + Rec."Reserved Qty. (Base)");

        Rec.TestField(Type, Rec.Type::Item);
        Rec.TestField("No.", ReservEntry."Item No.");
        Rec.TestField("Variant Code", ReservEntry."Variant Code");
        Rec.TestField("Location Code", ReservEntry."Location Code");

        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Service Line", Rec."Document Type".AsInteger(), Rec."Document No.", '', 0, Rec."Line No.",
          Rec."Variant Code", Rec."Location Code", Rec."Qty. per Unit of Measure");
        ReservMgt.CreateReservation(
          ReservEntry.Description, Rec."Posting Date", ReserveQuantity, ReserveQuantityBase, TrackingSpecification);
        UpdateReservFrom();
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
        Rec.SetRange(Type, Rec.Type::Item);
        Rec.SetRange("No.", ReservEntry."Item No.");
        Rec.SetRange("Variant Code", ReservEntry."Variant Code");
        Rec.SetRange("Location Code", ReservEntry."Location Code");
        Rec.SetFilter("Needed by Date", ReservMgt.GetAvailabilityFilter(ReservEntry."Shipment Date"));
        case CurrentSubType of
            0, 1, 2, 4:
                if ReservMgt.IsPositive() then
                    Rec.SetFilter("Quantity (Base)", '<0')
                else
                    Rec.SetFilter("Quantity (Base)", '>0');
            3:
                if not ReservMgt.IsPositive() then
                    Rec.SetFilter("Quantity (Base)", '<0')
                else
                    Rec.SetFilter("Quantity (Base)", '>0');
        end;

        OnAfterSetFilters(Rec, ReservEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilters(var ServiceLine: Record "Service Line"; ReservationEntry: Record "Reservation Entry")
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
}
