namespace Microsoft.Inventory.Tracking;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Projects.Project.Planning;
using Microsoft.Sales.Document;
using Microsoft.Service.Document;

report 300 "Carry Out Reservation"
{
    ApplicationArea = Reservation;
    ProcessingOnly = true;

    dataset
    {
        dataitem(ReservationWkshLine; "Reservation Wksh. Line")
        {
            DataItemTableView = sorting("Journal Batch Name", "Source Type", "Source Subtype", "Source ID", "Source Ref. No.", "Source Batch Name", "Source Prod. Order Line")
                                where(Accept = const(true));

            trigger OnPreDataItem()
            begin
                case DemandType of
                    DemandType::All:
                        SetRange("Source Type");
                    DemandType::"Sales Orders":
                        SetRange("Source Type", Database::"Sales Line");
                    DemandType::"Transfer Orders":
                        SetRange("Source Type", Database::"Transfer Line");
                    DemandType::"Service Orders":
                        SetRange("Source Type", Database::"Service Line");
                    DemandType::"Job Usage":
                        SetRange("Source Type", Database::"Job Planning Line");
                    DemandType::"Assembly Components":
                        SetRange("Source Type", Database::"Assembly Line");
                    DemandType::"Production Components":
                        SetRange("Source Type", Database::"Prod. Order Component");
                    else
                        OnCarryOutReservationOtherDemandType(ReservationWkshLine);
                end;
            end;

            trigger OnAfterGetRecord()
            begin
                if "Qty. to Reserve" <> 0 then
                    Reserve();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                group(Options)
                {
                    field("Demand Type"; DemandType)
                    {
                        Caption = 'Demand Type';
                        ToolTip = 'Specifies the type of demand to be reserved.';
                    }
                }
            }
        }
    }

    var
        ReservationWorksheetMgt: Codeunit "Reservation Worksheet Mgt.";
        DemandType: Enum "Reservation Demand Type";

    local procedure Reserve()
    var
        ReservationManagement: Codeunit "Reservation Management";
        RecordVariant: Variant;
        AvailabilityDate: Date;
        QtyToReserve: Decimal;
        QtyToReserveBase: Decimal;
        SavedQtyToReserve: Decimal;
    begin
        ReservationWorksheetMgt.GetSourceDocumentLine(
          ReservationWkshLine, RecordVariant, QtyToReserve, QtyToReserveBase, AvailabilityDate);
        if not RecordVariant.IsRecord() then
            exit;

        ReservationManagement.SetReservSource(RecordVariant);
        QtyToReserve := MinValue(QtyToReserve, ReservationWkshLine."Qty. to Reserve");
        QtyToReserveBase := MinValue(QtyToReserveBase, ReservationWkshLine."Qty. to Reserve (Base)");
        SavedQtyToReserve := QtyToReserve;

        ReservationManagement.AutoReserveOneLine(1, QtyToReserve, QtyToReserveBase, '', AvailabilityDate);

        ReservationWorksheetMgt.LogChanges(ReservationWkshLine, SavedQtyToReserve - QtyToReserve);
        ReservationWkshLine.Delete(true);
    end;

    local procedure MinValue(A: Decimal; B: Decimal): Decimal
    begin
        if A <= B then
            exit(A);

        exit(B);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCarryOutReservationOtherDemandType(var ReservationWkshLine: Record "Reservation Wksh. Line")
    begin
    end;
}
