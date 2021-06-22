codeunit 5765 "Whse.-Post Shipment + Print"
{
    TableNo = "Warehouse Shipment Line";

    trigger OnRun()
    begin
        WhseShptLine.Copy(Rec);
        Code;
        Rec := WhseShptLine;
    end;

    var
        WhseShptLine: Record "Warehouse Shipment Line";
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
        Selection: Integer;
        ShipInvoiceQst: Label '&Ship,Ship &and Invoice';

    local procedure "Code"()
    var
        Invoice: Boolean;
        HideDialog: Boolean;
        IsPosted: Boolean;
    begin
        HideDialog := false;
        IsPosted := false;
        OnBeforeCode(WhseShptLine, HideDialog, Invoice, IsPosted);
        if IsPosted then
            exit;

        with WhseShptLine do begin
            if Find then
                if not HideDialog then begin
                    Selection := StrMenu(ShipInvoiceQst, 1);
                    if Selection = 0 then
                        exit;
                    Invoice := (Selection = 2);
                end;

            OnAfterConfirmPost(WhseShptLine, Invoice);

            WhsePostShipment.SetPostingSettings(Invoice);
            WhsePostShipment.SetPrint(true);
            WhsePostShipment.Run(WhseShptLine);
            WhsePostShipment.GetResultMessage;
            Clear(WhsePostShipment);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmPost(WhseShipmentLine: Record "Warehouse Shipment Line"; Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var WhseShptLine: Record "Warehouse Shipment Line"; var HideDialog: Boolean; var Invoice: Boolean; var IsPosted: Boolean)
    begin
    end;
}

