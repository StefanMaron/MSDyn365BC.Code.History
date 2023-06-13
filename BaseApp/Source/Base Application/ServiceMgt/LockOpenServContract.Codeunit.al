codeunit 5943 "Lock-OpenServContract"
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'It is not possible to lock this %1 Service %2 because some lines have zero %3.';
        Text001: Label 'It is not possible to open a %1 service contract';
        Text002: Label 'New lines have been added to this contract.\Would you like to continue?';
        SignServContractDoc: Codeunit SignServContractDoc;
        Text003: Label 'You cannot lock service contract with negative annual amount.';
        Text004: Label 'You cannot lock service contract with zero annual amount when invoice period is different from None.';

    procedure LockServContract(FromServContractHeader: Record "Service Contract Header")
    var
        ServContractHeader: Record "Service Contract Header";
        ServContractLine: Record "Service Contract Line";
        RaiseError: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeLockServContract(FromServContractHeader);

        ServContractHeader := FromServContractHeader;
        with ServContractHeader do begin
            if "Change Status" = "Change Status"::Locked then
                exit;

            IsHandled := false;
            OnLockServContractOnBeforeCheckAmounts(ServContractHeader, IsHandled);
            if not IsHandled then begin
                CalcFields("Calcd. Annual Amount");
                TestField("Annual Amount", "Calcd. Annual Amount");
                if "Annual Amount" < 0 then
                    Error(Text003);
            end;

            IsHandled := false;
            OnLockServContractOnBeforeCheckZeroAnnualAmount(ServContractHeader, IsHandled);
            if not IsHandled then
                if IsInvoicePeriodInTimeSegment() then
                    if "Annual Amount" = 0 then
                        Error(Text004);

            LockTable();
            IsHandled := false;
            OnLockServContractOnAfterLockTable(ServContractHeader, IsHandled);
            if not IsHandled then
                if ("Contract Type" = "Contract Type"::Contract) and (Status = Status::Signed) then begin
                    ServContractLine.Reset();
                    ServContractLine.SetRange("Contract Type", "Contract Type");
                    ServContractLine.SetRange("Contract No.", "Contract No.");
                    ServContractLine.SetRange("Line Amount", 0);
                    ServContractLine.SetFilter("Line Discount %", '<%1', 100);
                    RaiseError := not ServContractLine.IsEmpty();
                    OnErrorIfServContractLinesHaveZeroAmount(ServContractHeader, ServContractLine, RaiseError);
                    if RaiseError then
                        Error(Text000, Status, "Contract Type", ServContractLine.FieldCaption("Line Amount"));
                    ServContractLine.Reset();
                    ServContractLine.SetRange("Contract Type", "Contract Type");
                    ServContractLine.SetRange("Contract No.", "Contract No.");
                    ServContractLine.SetRange("New Line", true);
                    if not ServContractLine.IsEmpty() then
                        SignServContract(ServContractHeader);
                end;
            Get(FromServContractHeader."Contract Type", FromServContractHeader."Contract No.");
            "Change Status" := "Change Status"::Locked;
            Modify();
        end;

        OnAfterLockServContract(ServContractHeader, FromServContractHeader);
    end;

    procedure OpenServContract(ServContractHeader: Record "Service Contract Header")
    begin
        with ServContractHeader do begin
            if "Change Status" = "Change Status"::Open then
                exit;
            LockTable();
            if (Status = Status::Cancelled) and ("Contract Type" = "Contract Type"::Contract) then
                Error(Text001, Status);
            "Change Status" := "Change Status"::Open;
            Modify();
        end;

        OnAfterOpenServContract(ServContractHeader);
    end;

    local procedure SignServContract(ServContractHeader: Record "Service Contract Header")
    var
        ConfirmManagement: Codeunit "Confirm Management";
        AutoSign: Boolean;
        IsHandled: Boolean;
    begin
        AutoSign := false;
        IsHandled := false;
        OnBeforeSignServContract(ServContractHeader, AutoSign, IsHandled);
        if IsHandled then
            exit;

        if not AutoSign then
            if not ConfirmManagement.GetResponseOrDefault(Text002, true) then
                exit;

        SignServContractDoc.AddendumToContract(ServContractHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLockServContract(var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnErrorIfServContractLinesHaveZeroAmount(ServiceContractHeader: Record "Service Contract Header"; ServiceContractLine: Record "Service Contract Line"; var RaiseError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLockServContract(var ServiceContractHeader: Record "Service Contract Header"; var FromServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOpenServContract(var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLockServContractOnBeforeCheckZeroAnnualAmount(ServContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSignServContract(ServContractHeader: Record "Service Contract Header"; var AutoSign: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLockServContractOnBeforeCheckAmounts(var ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLockServContractOnAfterLockTable(var ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;
}

