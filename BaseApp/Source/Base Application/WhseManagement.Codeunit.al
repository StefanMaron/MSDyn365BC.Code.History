codeunit 5775 "Whse. Management"
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'The Source Document is not defined.';
        UOMMgt: Codeunit "Unit of Measure Management";

    procedure GetSourceDocument(SourceType: Integer; SourceSubtype: Integer): Integer
    var
        SourceDocument: Option ,"S. Order","S. Invoice","S. Credit Memo","S. Return Order","P. Order","P. Invoice","P. Credit Memo","P. Return Order","Inb. Transfer","Outb. Transfer","Prod. Consumption","Item Jnl.","Phys. Invt. Jnl.","Reclass. Jnl.","Consumption Jnl.","Output Jnl.","BOM Jnl.","Serv. Order","Job Jnl.","Assembly Consumption","Assembly Order";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSourceDocument(SourceType, SourceSubtype, SourceDocument, IsHandled);
        if IsHandled then
            exit(SourceDocument);

        case SourceType of
            DATABASE::"Sales Line":
                case SourceSubtype of
                    1:
                        exit(SourceDocument::"S. Order");
                    2:
                        exit(SourceDocument::"S. Invoice");
                    3:
                        exit(SourceDocument::"S. Credit Memo");
                    5:
                        exit(SourceDocument::"S. Return Order");
                end;
            DATABASE::"Purchase Line":
                case SourceSubtype of
                    1:
                        exit(SourceDocument::"P. Order");
                    2:
                        exit(SourceDocument::"P. Invoice");
                    3:
                        exit(SourceDocument::"P. Credit Memo");
                    5:
                        exit(SourceDocument::"P. Return Order");
                end;
            DATABASE::"Service Line":
                exit(SourceDocument::"Serv. Order");
            DATABASE::"Prod. Order Component":
                exit(SourceDocument::"Prod. Consumption");
            DATABASE::"Assembly Line":
                exit(SourceDocument::"Assembly Consumption");
            DATABASE::"Assembly Header":
                exit(SourceDocument::"Assembly Order");
            DATABASE::"Transfer Line":
                case SourceSubtype of
                    0:
                        exit(SourceDocument::"Outb. Transfer");
                    1:
                        exit(SourceDocument::"Inb. Transfer");
                end;
            DATABASE::"Item Journal Line":
                case SourceSubtype of
                    0:
                        exit(SourceDocument::"Item Jnl.");
                    1:
                        exit(SourceDocument::"Reclass. Jnl.");
                    2:
                        exit(SourceDocument::"Phys. Invt. Jnl.");
                    4:
                        exit(SourceDocument::"Consumption Jnl.");
                    5:
                        exit(SourceDocument::"Output Jnl.");
                end;
            DATABASE::"Job Journal Line":
                exit(SourceDocument::"Job Jnl.");
        end;
        OnAfterGetSourceDocument(SourceType, SourceSubtype, SourceDocument, IsHandled);
        if IsHandled then
            exit(SourceDocument);
        Error(Text000);
    end;

    procedure GetSourceType(WhseWkshLine: Record "Whse. Worksheet Line") SourceType: Integer
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSourceType(WhseWkshLine, SourceType, IsHandled);
        if IsHandled then
            exit(SourceType);

        with WhseWkshLine do
            case "Whse. Document Type" of
                "Whse. Document Type"::Receipt:
                    SourceType := DATABASE::"Posted Whse. Receipt Line";
                "Whse. Document Type"::Shipment:
                    SourceType := DATABASE::"Warehouse Shipment Line";
                "Whse. Document Type"::Production:
                    SourceType := DATABASE::"Prod. Order Component";
                "Whse. Document Type"::Assembly:
                    SourceType := DATABASE::"Assembly Line";
                "Whse. Document Type"::"Internal Put-away":
                    SourceType := DATABASE::"Whse. Internal Put-away Line";
                "Whse. Document Type"::"Internal Pick":
                    SourceType := DATABASE::"Whse. Internal Pick Line";
            end;
    end;

    procedure GetOutboundDocLineQtyOtsdg(SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; var QtyOutstanding: Decimal; var QtyBaseOutstanding: Decimal)
    var
        WhseShptLine: Record "Warehouse Shipment Line";
    begin
        with WhseShptLine do begin
            SetCurrentKey("Source Type");
            SetRange("Source Type", SourceType);
            SetRange("Source Subtype", SourceSubType);
            SetRange("Source No.", SourceNo);
            SetRange("Source Line No.", SourceLineNo);
            if FindFirst then begin
                CalcFields("Pick Qty. (Base)", "Pick Qty.");
                CalcSums(Quantity, "Qty. (Base)");
                QtyOutstanding := Quantity - "Pick Qty." - "Qty. Picked";
                QtyBaseOutstanding := "Qty. (Base)" - "Pick Qty. (Base)" - "Qty. Picked (Base)";
            end else
                GetSrcDocLineQtyOutstanding(SourceType, SourceSubType, SourceNo,
                  SourceLineNo, SourceSubLineNo, QtyOutstanding, QtyBaseOutstanding);
        end;
    end;

    local procedure GetSrcDocLineQtyOutstanding(SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; var QtyOutstanding: Decimal; var QtyBaseOutstanding: Decimal)
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        ServiceLine: Record "Service Line";
        ProdOrderComp: Record "Prod. Order Component";
        AssemblyLine: Record "Assembly Line";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        case SourceType of
            DATABASE::"Sales Line":
                if SalesLine.Get(SourceSubType, SourceNo, SourceLineNo) then begin
                    QtyOutstanding := SalesLine."Outstanding Quantity";
                    QtyBaseOutstanding := SalesLine."Outstanding Qty. (Base)";
                end;
            DATABASE::"Purchase Line":
                if PurchaseLine.Get(SourceSubType, SourceNo, SourceLineNo) then begin
                    QtyOutstanding := PurchaseLine."Outstanding Quantity";
                    QtyBaseOutstanding := PurchaseLine."Outstanding Qty. (Base)";
                end;
            DATABASE::"Transfer Line":
                if TransferLine.Get(SourceNo, SourceLineNo) then
                    case SourceSubType of
                        0: // Direction = Outbound
                            begin
                                QtyOutstanding :=
                                  Round(
                                    TransferLine."Whse Outbnd. Otsdg. Qty (Base)" / (QtyOutstanding / QtyBaseOutstanding),
                                    UOMMgt.QtyRndPrecision);
                                QtyBaseOutstanding := TransferLine."Whse Outbnd. Otsdg. Qty (Base)";
                            end;
                        1: // Direction = Inbound
                            begin
                                QtyOutstanding :=
                                  Round(
                                    TransferLine."Whse. Inbnd. Otsdg. Qty (Base)" / (QtyOutstanding / QtyBaseOutstanding),
                                    UOMMgt.QtyRndPrecision);
                                QtyBaseOutstanding := TransferLine."Whse. Inbnd. Otsdg. Qty (Base)";
                            end;
                    end;
            DATABASE::"Service Line":
                if ServiceLine.Get(SourceSubType, SourceNo, SourceLineNo) then begin
                    QtyOutstanding := ServiceLine."Outstanding Quantity";
                    QtyBaseOutstanding := ServiceLine."Outstanding Qty. (Base)";
                end;
            DATABASE::"Prod. Order Component":
                if ProdOrderComp.Get(SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo) then begin
                    QtyOutstanding := ProdOrderComp."Remaining Quantity";
                    QtyBaseOutstanding := ProdOrderComp."Remaining Qty. (Base)";
                end;
            DATABASE::"Assembly Line":
                if AssemblyLine.Get(SourceSubType, SourceNo, SourceLineNo) then begin
                    QtyOutstanding := AssemblyLine."Remaining Quantity";
                    QtyBaseOutstanding := AssemblyLine."Remaining Quantity (Base)";
                end;
            DATABASE::"Prod. Order Line":
                if ProdOrderLine.Get(SourceSubType, SourceNo, SourceLineNo) then begin
                    QtyOutstanding := ProdOrderLine."Remaining Quantity";
                    QtyBaseOutstanding := ProdOrderLine."Remaining Qty. (Base)";
                end;
            else begin
                    QtyOutstanding := 0;
                    QtyBaseOutstanding := 0;
                end;
        end;

        OnAfterGetSrcDocLineQtyOutstanding(
          SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, QtyOutstanding, QtyBaseOutstanding);
    end;

    procedure SetSourceFilterForWhseRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SetKey: Boolean)
    begin
        with WarehouseReceiptLine do begin
            if SetKey then
                SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.");
            SetRange("Source Type", SourceType);
            if SourceSubType >= 0 then
                SetRange("Source Subtype", SourceSubType);
            SetRange("Source No.", SourceNo);
            if SourceLineNo >= 0 then
                SetRange("Source Line No.", SourceLineNo);
        end;
    end;

    procedure SetSourceFilterForWhseShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SetKey: Boolean)
    begin
        with WarehouseShipmentLine do begin
            if SetKey then
                SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.");
            SetRange("Source Type", SourceType);
            if SourceSubType >= 0 then
                SetRange("Source Subtype", SourceSubType);
            SetRange("Source No.", SourceNo);
            if SourceLineNo >= 0 then
                SetRange("Source Line No.", SourceLineNo);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSrcDocLineQtyOutstanding(SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; var QtyOutstanding: Decimal; var QtyBaseOutstanding: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSourceDocument(SourceType: Integer; SourceSubtype: Integer; var SourceDocument: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSourceDocument(SourceType: Integer; SourceSubtype: Integer; var SourceDocument: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSourceType(WhseWorksheetLine: Record "Whse. Worksheet Line"; var SourceType: Integer; var IsHandled: Boolean)
    begin
    end;
}

