namespace Microsoft.Purchases.Document;

using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.History;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;

codeunit 5992 "Purchases Warehouse Mgt."
{
    var
#if not CLEAN23
        WMSManagement: Codeunit "WMS Management";
#endif
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        WhseCreateSourceDocument: Codeunit "Whse.-Create Source Document";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowSourceDocLine', '', false, false)]
    local procedure OnShowSourceDocLine(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        if SourceType = Database::"Purchase Line" then begin
            PurchaseLine.Reset();
            PurchaseLine.SetRange("Document Type", SourceSubType);
            PurchaseLine.SetRange("Document No.", SourceNo);
            PurchaseLine.SetRange("Line No.", SourceLineNo);
            IsHandled := false;
#if not CLEAN23
            WMSManagement.RunOnShowSourceDocLineOnBeforeShowPurchLines(PurchaseLine, SourceSubType, SourceNo, SourceLineNo, IsHandled);
#endif
            OnBeforeShowPurchaseLines(PurchaseLine, SourceSubType, SourceNo, SourceLineNo, IsHandled);
            if not IsHandled then
                ShowPurchaseLines(PurchaseLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowSourceDocAttachedLines', '', false, false)]
    local procedure OnShowSourceDocAttachedLines(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        if SourceType = Database::"Purchase Line" then begin
            PurchaseLine.Reset();
            PurchaseLine.SetRange("Document Type", SourceSubType);
            PurchaseLine.SetRange("Document No.", SourceNo);
            PurchaseLine.SetRange("Attached to Line No.", SourceLineNo);
            IsHandled := false;
            OnBeforeShowAttachedPurchaseLines(PurchaseLine, SourceSubType, SourceNo, SourceLineNo, IsHandled);
            if not IsHandled then
                ShowPurchaseLines(PurchaseLine);
        end;
    end;

    local procedure ShowPurchaseLines(var PurchaseLine: Record "Purchase Line")
    begin
        Page.Run(Page::"Purchase Lines", PurchaseLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowSourceDocCard', '', false, false)]
    local procedure OnShowSourceDocCard(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if SourceType = DATABASE::"Purchase Line" then begin
            PurchaseHeader.Reset();
            PurchaseHeader.SetRange("Document Type", SourceSubType);
            if PurchaseHeader.Get(SourceSubType, SourceNo) then
                if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order then
                    PAGE.RunModal(PAGE::"Purchase Order", PurchaseHeader)
                else
                    PAGE.RunModal(PAGE::"Purchase Return Order", PurchaseHeader);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowPostedSourceDoc', '', false, false)]
    local procedure OnShowPostedSourceDoc(PostedSourceDoc: Option; PostedSourceNo: Code[20])
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        PostedSourceDocEnum: Enum "Warehouse Shipment Posted Source Document";
    begin
        PostedSourceDocEnum := Enum::"Warehouse Shipment Posted Source Document".FromInteger(PostedSourceDoc);
        case PostedSourceDocEnum of
            PostedSourceDocEnum::"Posted Receipt":
                begin
                    PurchRcptHeader.Reset();
                    PurchRcptHeader.SetRange("No.", PostedSourceNo);
                    PAGE.RunModal(PAGE::"Posted Purchase Receipt", PurchRcptHeader);
                end;
            PostedSourceDocEnum::"Posted Return Shipment":
                begin
                    ReturnShipmentHeader.Reset();
                    ReturnShipmentHeader.SetRange("No.", PostedSourceNo);
                    PAGE.RunModal(PAGE::"Posted Return Shipment", ReturnShipmentHeader);
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowPurchaseLines(var PurchaseLine: Record "Purchase Line"; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowAttachedPurchaseLines(var PurchaseLine: Record "Purchase Line"; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    procedure PurchaseLineVerifyChange(var NewPurchaseLine: Record "Purchase Line"; var OldPurchaseLine: Record "Purchase Line")
    var
        OverReceiptMgt: Codeunit "Over-Receipt Mgt.";
        NewRecordRef: RecordRef;
        OldRecordRef: RecordRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
#if not CLEAN23
        WhseValidateSourceLine.RunOnBeforePurchaseLineVerifyChange(NewPurchaseLine, OldPurchaseLine, IsHandled);
#endif
        OnBeforePurchaseLineVerifyChange(NewPurchaseLine, OldPurchaseLine, IsHandled);
        if IsHandled then
            exit;

        if not WhseValidateSourceLine.WhseLinesExist(
             DATABASE::"Purchase Line", NewPurchaseLine."Document Type".AsInteger(), NewPurchaseLine."Document No.",
             NewPurchaseLine."Line No.", 0, NewPurchaseLine.Quantity)
        then
            exit;

        NewRecordRef.GetTable(NewPurchaseLine);
        OldRecordRef.GetTable(OldPurchaseLine);
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewPurchaseLine.FieldNo(Type));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewPurchaseLine.FieldNo("No."));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewPurchaseLine.FieldNo("Variant Code"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewPurchaseLine.FieldNo("Location Code"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewPurchaseLine.FieldNo("Unit of Measure Code"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewPurchaseLine.FieldNo("Drop Shipment"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewPurchaseLine.FieldNo("Sales Order No."));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewPurchaseLine.FieldNo("Sales Order Line No."));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewPurchaseLine.FieldNo("Special Order"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewPurchaseLine.FieldNo("Special Order Sales No."));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewPurchaseLine.FieldNo("Special Order Sales Line No."));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewPurchaseLine.FieldNo("Job No."));
        if not OverReceiptMgt.IsQuantityUpdatedFromInvtPutAwayOverReceipt(NewPurchaseLine) then begin
            if not OverReceiptMgt.IsQuantityUpdatedFromWarehouseOverReceipt(NewPurchaseLine) then
                WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewPurchaseLine.FieldNo(Quantity));
            WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewPurchaseLine.FieldNo("Qty. to Receive"));
        end;

        OnAfterPurchaseLineVerifyChange(NewPurchaseLine, OldPurchaseLine, NewRecordRef, OldRecordRef);
#if not CLEAN23
        WhseValidateSourceLine.RunOnAfterPurchaseLineVerifyChange(NewPurchaseLine, OldPurchaseLine, NewRecordRef, OldRecordRef);
#endif
    end;

    procedure PurchaseLineDelete(var PurchaseLine: Record "Purchase Line")
    begin
        if WhseValidateSourceLine.WhseLinesExist(
             DATABASE::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.", 0, PurchaseLine.Quantity)
        then
            WhseValidateSourceLine.RaiseCannotBeDeletedErr(PurchaseLine.TableCaption());

        OnAfterPurchaseLineDelete(PurchaseLine);
#if not CLEAN23
        WhseValidateSourceLine.RunOnAfterPurchaseLineDelete(PurchaseLine);
#endif
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Validate Source Line", 'OnWhseLineExistOnBeforeCheckReceipt', '', false, false)]
    local procedure OnWhseLineExistOnBeforeCheckReceipt(SourceType: Integer; SourceSubType: Option; SourceQty: Decimal; var CheckReceipt: Boolean)
    begin
        CheckReceipt := CheckReceipt or
           ((SourceType = DATABASE::"Purchase Line") and (SourceSubType = 1) and (SourceQty >= 0)) or
           ((SourceType = DATABASE::"Purchase Line") and (SourceSubType = 5) and (SourceQty < 0));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Validate Source Line", 'OnWhseLineExistOnBeforeCheckShipment', '', false, false)]
    local procedure OnWhseLineExistOnBeforeCheckShipment(SourceType: Integer; SourceSubType: Option; SourceQty: Decimal; var CheckShipment: Boolean)
    begin
        CheckShipment := CheckShipment or
           ((SourceType = DATABASE::"Purchase Line") and (SourceSubType = 1) and (SourceQty < 0)) or
           ((SourceType = DATABASE::"Purchase Line") and (SourceSubType = 5) and (SourceQty >= 0));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchaseLineVerifyChange(var NewPurchaseLine: Record "Purchase Line"; var OldPurchaseLine: Record "Purchase Line"; var NewRecordRef: RecordRef; var OldRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchaseLineDelete(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseLineVerifyChange(var NewPurchaseLine: Record "Purchase Line"; var OldPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Request", 'OnShowSourceDocumentCard', '', false, false)]
    local procedure OnShowSourceDocumentCard(var WarehouseRequest: Record "Warehouse Request")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        case WarehouseRequest."Source Document" of
            Enum::"Warehouse Request Source Document"::"Purchase Order":
                begin
                    PurchaseHeader.Get(WarehouseRequest."Source Subtype", WarehouseRequest."Source No.");
                    PAGE.Run(PAGE::"Purchase Order", PurchaseHeader);
                end;
            Enum::"Warehouse Request Source Document"::"Purchase Return Order":
                begin
                    PurchaseHeader.Get(WarehouseRequest."Source Subtype", WarehouseRequest."Source No.");
                    PAGE.Run(PAGE::"Purchase Return Order", PurchaseHeader);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Source Filter", 'OnSetFiltersOnSourceTables', '', false, false)]
    local procedure OnSetFiltersOnSourceTables(var WarehouseSourceFilter: Record "Warehouse Source Filter"; var GetSourceDocuments: Report "Get Source Documents"; var WarehouseRequest: Record "Warehouse Request")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseHeader.SetFilter("Buy-from Vendor No.", WarehouseSourceFilter."Buy-from Vendor No. Filter");

        PurchaseLine.SetFilter("No.", WarehouseSourceFilter."Item No. Filter");
        PurchaseLine.SetFilter("Variant Code", WarehouseSourceFilter."Variant Code Filter");
        PurchaseLine.SetFilter("Unit of Measure Code", WarehouseSourceFilter."Unit of Measure Filter");
        PurchaseLine.SetFilter("Buy-from Vendor No.", WarehouseSourceFilter."Buy-from Vendor No. Filter");
        PurchaseLine.SetFilter("Expected Receipt Date", WarehouseSourceFilter."Expected Receipt Date");
        PurchaseLine.SetFilter("Planned Receipt Date", WarehouseSourceFilter."Planned Receipt Date");

        OnSetFiltersOnSourceTablesOnBeforeSetPurchaseTableView(WarehouseSourceFilter, WarehouseRequest, PurchaseHeader, PurchaseLine);
        GetSourceDocuments.SetTableView(PurchaseHeader);
        GetSourceDocuments.SetTableView(PurchaseLine);
    end;

    procedure FromPurchLine2ShptLine(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; PurchaseLine: Record "Purchase Line") Result: Boolean
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
#if not CLEAN23
        WhseCreateSourceDocument.RunOnBeforeFromPurchLine2ShptLine(PurchaseLine, Result, IsHandled, WarehouseShipmentHeader);
#endif
        OnBeforeFromPurchLine2ShptLine(PurchaseLine, Result, IsHandled, WarehouseShipmentHeader);
        if IsHandled then
            exit(Result);

        WarehouseShipmentLine.InitNewLine(WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.SetSource(DATABASE::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.TestField("Unit of Measure Code");
        WarehouseShipmentLine.SetItemData(
          PurchaseLine."No.", PurchaseLine.Description, PurchaseLine."Description 2", PurchaseLine."Location Code",
          PurchaseLine."Variant Code", PurchaseLine."Unit of Measure Code", PurchaseLine."Qty. per Unit of Measure",
          PurchaseLine."Qty. Rounding Precision", PurchaseLine."Qty. Rounding Precision (Base)");
#if not CLEAN23
        WhseCreateSourceDocument.RunOnFromPurchLine2ShptLineOnAfterInitNewLine(WarehouseShipmentLine, WarehouseShipmentHeader, PurchaseLine);
#endif
        OnFromPurchLine2ShptLineOnAfterInitNewLine(WarehouseShipmentLine, WarehouseShipmentHeader, PurchaseLine);
        WhseCreateSourceDocument.SetQtysOnShptLine(WarehouseShipmentLine, Abs(PurchaseLine."Outstanding Quantity"), Abs(PurchaseLine."Outstanding Qty. (Base)"));
        if PurchaseLine."Document Type" = PurchaseLine."Document Type"::Order then
            WarehouseShipmentLine."Due Date" := PurchaseLine."Expected Receipt Date";
        if PurchaseLine."Document Type" = PurchaseLine."Document Type"::"Return Order" then
            WarehouseShipmentLine."Due Date" := WorkDate();
        if WarehouseShipmentHeader."Shipment Date" = 0D then
            WarehouseShipmentLine."Shipment Date" := PurchaseLine."Planned Receipt Date"
        else
            WarehouseShipmentLine."Shipment Date" := WarehouseShipmentHeader."Shipment Date";
        WarehouseShipmentLine."Destination Type" := WarehouseShipmentLine."Destination Type"::Vendor;
        WarehouseShipmentLine."Destination No." := PurchaseLine."Buy-from Vendor No.";
        if WarehouseShipmentLine."Location Code" = WarehouseShipmentHeader."Location Code" then
            WarehouseShipmentLine."Bin Code" := WarehouseShipmentHeader."Bin Code";
        if WarehouseShipmentLine."Bin Code" = '' then
            WarehouseShipmentLine."Bin Code" := PurchaseLine."Bin Code";
        WhseCreateSourceDocument.UpdateShipmentLine(WarehouseShipmentLine, WarehouseShipmentHeader);
#if not CLEAN23
        WhseCreateSourceDocument.RunOnFromPurchLine2ShptLineOnBeforeCreateShptLine(WarehouseShipmentLine, WarehouseShipmentHeader, PurchaseLine);
#endif
        OnFromPurchLine2ShptLineOnBeforeCreateShptLine(WarehouseShipmentLine, WarehouseShipmentHeader, PurchaseLine);
        WhseCreateSourceDocument.CreateShipmentLine(WarehouseShipmentLine);
#if not CLEAN23
        WhseCreateSourceDocument.RunOnAfterCreateShptLineFromPurchLine(WarehouseShipmentLine, WarehouseShipmentHeader, PurchaseLine);
#endif
        OnAfterCreateShptLineFromPurchLine(WarehouseShipmentLine, WarehouseShipmentHeader, PurchaseLine);
        exit(not WarehouseShipmentLine.HasErrorOccured());
    end;

    procedure PurchLine2ReceiptLine(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; PurchaseLine: Record "Purchase Line"): Boolean
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
#if not CLEAN23
        WhseCreateSourceDocument.RunOnBeforePurchLine2ReceiptLine(WarehouseReceiptHeader, PurchaseLine, IsHandled, Result);
#endif
        OnBeforePurchLine2ReceiptLine(WarehouseReceiptHeader, PurchaseLine, IsHandled, Result);
        if IsHandled then
            exit(Result);

        WarehouseReceiptLine.InitNewLine(WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.SetSource(DATABASE::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.TestField("Unit of Measure Code");
        WarehouseReceiptLine.SetItemData(
          PurchaseLine."No.", PurchaseLine.Description, PurchaseLine."Description 2", PurchaseLine."Location Code",
          PurchaseLine."Variant Code", PurchaseLine."Unit of Measure Code", PurchaseLine."Qty. per Unit of Measure",
          PurchaseLine."Qty. Rounding Precision", PurchaseLine."Qty. Rounding Precision (Base)");
        WarehouseReceiptLine."Over-Receipt Code" := PurchaseLine."Over-Receipt Code";
        IsHandled := false;
#if not CLEAN23
        WhseCreateSourceDocument.RunOnPurchLine2ReceiptLineOnAfterInitNewLine(WarehouseReceiptLine, WarehouseReceiptHeader, PurchaseLine, IsHandled);
#endif
        OnPurchLine2ReceiptLineOnAfterInitNewLine(WarehouseReceiptLine, WarehouseReceiptHeader, PurchaseLine, IsHandled);
        if not IsHandled then begin
            case PurchaseLine."Document Type" of
                PurchaseLine."Document Type"::Order:
                    begin
                        WarehouseReceiptLine.Validate("Qty. Received", Abs(PurchaseLine."Quantity Received"));
                        WarehouseReceiptLine."Due Date" := PurchaseLine."Expected Receipt Date";
                    end;
                PurchaseLine."Document Type"::"Return Order":
                    begin
                        WarehouseReceiptLine.Validate("Qty. Received", Abs(PurchaseLine."Return Qty. Shipped"));
                        WarehouseReceiptLine."Due Date" := WorkDate();
                    end;
            end;
            WhseCreateSourceDocument.SetQtysOnRcptLine(WarehouseReceiptLine, Abs(PurchaseLine.Quantity), Abs(PurchaseLine."Quantity (Base)"));
        end;
#if not CLEAN23
        WhseCreateSourceDocument.RunOnPurchLine2ReceiptLineOnAfterSetQtysOnRcptLine(WarehouseReceiptLine, PurchaseLine);
#endif
        OnPurchLine2ReceiptLineOnAfterSetQtysOnRcptLine(WarehouseReceiptLine, PurchaseLine);
        WarehouseReceiptLine."Starting Date" := PurchaseLine."Planned Receipt Date";
        if WarehouseReceiptLine."Location Code" = WarehouseReceiptHeader."Location Code" then
            WarehouseReceiptLine."Bin Code" := WarehouseReceiptHeader."Bin Code";
        if WarehouseReceiptLine."Bin Code" = '' then
            WarehouseReceiptLine."Bin Code" := PurchaseLine."Bin Code";
        WhseCreateSourceDocument.UpdateReceiptLine(WarehouseReceiptLine, WarehouseReceiptHeader);
#if not CLEAN23
        WhseCreateSourceDocument.RunOnPurchLine2ReceiptLineOnAfterUpdateReceiptLine(WarehouseReceiptLine, WarehouseReceiptHeader, PurchaseLine);
#endif
        OnPurchLine2ReceiptLineOnAfterUpdateReceiptLine(WarehouseReceiptLine, WarehouseReceiptHeader, PurchaseLine);
        WhseCreateSourceDocument.CreateReceiptLine(WarehouseReceiptLine);
#if not CLEAN23
        WhseCreateSourceDocument.RunOnAfterCreateRcptLineFromPurchLine(WarehouseReceiptLine, WarehouseReceiptHeader, PurchaseLine);
#endif
        OnAfterCreateRcptLineFromPurchLine(WarehouseReceiptLine, WarehouseReceiptHeader, PurchaseLine);
        exit(not WarehouseReceiptLine.HasErrorOccured());
    end;

    procedure CheckIfFromPurchLine2ShptLine(PurchaseLine: Record "Purchase Line"): Boolean
    begin
        exit(CheckIfFromPurchLine2ShptLine(PurchaseLine, "Reservation From Stock"::" "));
    end;

    procedure CheckIfFromPurchLine2ShptLine(PurchaseLine: Record "Purchase Line"; ReservedFromStock: Enum "Reservation From Stock"): Boolean
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        IsHandled := false;
        ReturnValue := false;
#if not CLEAN23
        WhseCreateSourceDocument.RunOnBeforeCheckIfPurchLine2ShptLine(PurchaseLine, ReturnValue, IsHandled);
#endif
        OnBeforeCheckIfPurchLine2ShptLine(PurchaseLine, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        if PurchaseLine.IsNonInventoriableItem() then
            exit(false);

        if not PurchaseLine.CheckIfPurchaseLineMeetsReservedFromStockSetting(Abs(PurchaseLine."Outstanding Qty. (Base)"), ReservedFromStock) then
            exit(false);

        WarehouseShipmentLine.SetSourceFilter(DATABASE::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.", false);
        WarehouseShipmentLine.CalcSums("Qty. Outstanding (Base)");
        exit(Abs(PurchaseLine."Outstanding Qty. (Base)") > WarehouseShipmentLine."Qty. Outstanding (Base)");
    end;

    procedure CheckIfPurchLine2ReceiptLine(PurchaseLine: Record "Purchase Line"): Boolean
    var
        ReturnValue: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        ReturnValue := false;
#if not CLEAN23
        WhseCreateSourceDocument.RunOnBeforeCheckIfPurchLine2ReceiptLine(PurchaseLine, ReturnValue, IsHandled);
#endif
        OnBeforeCheckIfPurchLine2ReceiptLine(PurchaseLine, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        if PurchaseLine.IsNonInventoriableItem() then
            exit(false);

        PurchaseLine.CalcFields("Whse. Outstanding Qty. (Base)");
        exit(Abs(PurchaseLine."Outstanding Qty. (Base)") > Abs(PurchaseLine."Whse. Outstanding Qty. (Base)"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFromPurchLine2ShptLine(var PurchaseLine: Record "Purchase Line"; var Result: Boolean; var IsHandled: Boolean; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromPurchLine2ShptLineOnAfterInitNewLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromPurchLine2ShptLineOnBeforeCreateShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateShptLineFromPurchLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchLine2ReceiptLine(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchLine2ReceiptLineOnAfterInitNewLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchLine2ReceiptLineOnAfterSetQtysOnRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchLine2ReceiptLineOnAfterUpdateReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var WhseReceiptHeader: Record "Warehouse Receipt Header"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateRcptLineFromPurchLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfPurchLine2ReceiptLine(var PurchaseLine: Record "Purchase Line"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfPurchLine2ShptLine(var PurchaseLine: Record "Purchase Line"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetFiltersOnSourceTablesOnBeforeSetPurchaseTableView(var WarehouseSourceFilter: Record "Warehouse Source Filter"; var WarehouseRequest: Record "Warehouse Request"; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
    end;
}