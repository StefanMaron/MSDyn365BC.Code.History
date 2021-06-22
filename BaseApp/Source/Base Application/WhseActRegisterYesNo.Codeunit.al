codeunit 7306 "Whse.-Act.-Register (Yes/No)"
{
    TableNo = "Warehouse Activity Line";

    trigger OnRun()
    begin
        WhseActivLine.Copy(Rec);
        Code;
        Copy(WhseActivLine);
    end;

    var
        Text001: Label 'Do you want to register the %1 Document?';
        WhseActivLine: Record "Warehouse Activity Line";
        WhseActivityRegister: Codeunit "Whse.-Activity-Register";
        WMSMgt: Codeunit "WMS Management";
        Text002: Label 'The document %1 is not supported.';

    local procedure "Code"()
    var
        IsHandled: Boolean;
    begin
        OnBeforeCode(WhseActivLine);

        with WhseActivLine do begin
            if ("Activity Type" = "Activity Type"::"Invt. Movement") and
               not ("Source Document" in ["Source Document"::" ",
                                          "Source Document"::"Prod. Consumption",
                                          "Source Document"::"Assembly Consumption"])
            then
                Error(Text002, "Source Document");

            WMSMgt.CheckBalanceQtyToHandle(WhseActivLine);

            if not Confirm(Text001, false, "Activity Type") then
                exit;

            IsHandled := false;
            OnBeforeRegisterRun(WhseActivLine, IsHandled);
            if not IsHandled then
                WhseActivityRegister.Run(WhseActivLine);
            Clear(WhseActivityRegister);
        end;

        OnAfterCode(WhseActivLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRegisterRun(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;
}

