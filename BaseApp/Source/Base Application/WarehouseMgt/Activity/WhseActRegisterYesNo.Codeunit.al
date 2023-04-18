codeunit 7306 "Whse.-Act.-Register (Yes/No)"
{
    TableNo = "Warehouse Activity Line";

    trigger OnRun()
    begin
        WhseActivLine.Copy(Rec);
        Code();
        Copy(WhseActivLine);
    end;

    var
        WhseActivLine: Record "Warehouse Activity Line";
        WhseActivityRegister: Codeunit "Whse.-Activity-Register";
        WMSMgt: Codeunit "WMS Management";

        Text001: Label 'Do you want to register the %1 Document?';
        Text002: Label 'The document %1 is not supported.';

    local procedure "Code"()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCode(WhseActivLine, IsHandled);
        if IsHandled then
            exit;

        with WhseActivLine do begin
            CheckSourceDocument();

            WMSMgt.CheckBalanceQtyToHandle(WhseActivLine);

            if not ConfirmRegister(WhseActivLine) then
                exit;

            IsHandled := false;
            OnBeforeRegisterRun(WhseActivLine, IsHandled);
            if not IsHandled then
                WhseActivityRegister.Run(WhseActivLine);
            Clear(WhseActivityRegister);
        end;

        OnAfterCode(WhseActivLine);
    end;

    local procedure ConfirmRegister(WarehouseActivityLine: Record "Warehouse Activity Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmRegister(WarehouseActivityLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Result := Confirm(Text001, false, WarehouseActivityLine."Activity Type");
    end;

    local procedure CheckSourceDocument()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSourceDocument(WhseActivLine, IsHandled);
        if IsHandled then
            exit;

        with WhseActivLine do
            if ("Activity Type" = "Activity Type"::"Invt. Movement") and
               not ("Source Document" in ["Source Document"::" ",
                                          "Source Document"::"Prod. Consumption",
                                          "Source Document"::"Assembly Consumption"])
            then
                Error(Text002, "Source Document");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSourceDocument(WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmRegister(var WarehouseActivityLine: Record "Warehouse Activity Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRegisterRun(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;
}

