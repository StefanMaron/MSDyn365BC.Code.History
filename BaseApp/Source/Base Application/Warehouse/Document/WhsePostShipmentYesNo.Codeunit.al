namespace Microsoft.Warehouse.Document;

using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.ReceivablesPayables;

codeunit 5764 "Whse.-Post Shipment (Yes/No)"
{
    TableNo = "Warehouse Shipment Line";
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        WhseShptLine.Copy(Rec);
        Code();
        Rec := WhseShptLine;
    end;

    var
        WhseShptLine: Record "Warehouse Shipment Line";
        Selection: Integer;

    local procedure "Code"()
    var
        PostingSelectionManagement: Codeunit "Posting Selection Management";
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
        Invoice: Boolean;
        HideDialog: Boolean;
        IsPosted: Boolean;
    begin
        HideDialog := false;
        IsPosted := false;
        OnBeforeConfirmWhseShipmentPost(WhseShptLine, HideDialog, Invoice, IsPosted, Selection);
        if IsPosted then
            exit;

        with WhseShptLine do begin
            if Find() then
                if not HideDialog then begin
                    if not PostingSelectionManagement.ConfirmPostWhseShipment(WhseShptLine, Selection) then
                        exit;
                    Invoice := (Selection = 2);
                end;

            OnAfterConfirmPost(WhseShptLine, Invoice);

            WhsePostShipment.SetPostingSettings(Invoice);
            WhsePostShipment.SetPrint(false);
            WhsePostShipment.Run(WhseShptLine);
            WhsePostShipment.GetResultMessage();
            Clear(WhsePostShipment);
        end;

        OnAfterCode(WhseShptLine);
    end;

    procedure Preview(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    var
        WhsePostShipmentYesNo: Codeunit "Whse.-Post Shipment (Yes/No)";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        BindSubscription(WhsePostShipmentYesNo);
        GenJnlPostPreview.Preview(WhsePostShipmentYesNo, WarehouseShipmentLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
    begin
        WarehouseShipmentLine.Copy(RecVar);
        WhsePostShipment.SetPreviewMode(true);
        WhsePostShipment.SetPostingSettings(true);
        WhsePostShipment.SetPrint(false);
        Result := WhsePostShipment.Run(WarehouseShipmentLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmPost(WhseShipmentLine: Record "Warehouse Shipment Line"; Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmWhseShipmentPost(var WhseShptLine: Record "Warehouse Shipment Line"; var HideDialog: Boolean; var Invoice: Boolean; var IsPosted: Boolean; var Selection: Integer)
    begin
    end;
}

