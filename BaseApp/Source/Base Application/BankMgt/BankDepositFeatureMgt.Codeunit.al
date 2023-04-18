#if not CLEAN21
codeunit 1514 "Bank Deposit Feature Mgt."
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Bank Deposits feature will be enabled by default';
    ObsoleteTag = '21.0';

    procedure OnBeforeUpgradeToBankDeposits(var DepositsTableId: Integer; var BankRecHeaderTableId: Integer; var BankRecLineTableId: Integer)
    begin
        DepositsTableId := 0;
        BankRecHeaderTableId := 0;
        BankRecLineTableId := 0;
    end;

    procedure IsEnabled(): Boolean
    var
        FeatureManagementFacade: Codeunit "Feature Management Facade";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        OnBeforeIsEnabled(Result, IsHandled);
        if IsHandled then
            exit(Result);
        exit(FeatureManagementFacade.IsEnabled(FeatureKeyIdTok));
    end;

    procedure GetFeatureKeyId(): Text
    begin
        exit(FeatureKeyIdTok);
    end;

    procedure EnableDepositActions()
    begin
    end;

    procedure DisableDepositActions()
    begin
    end;

    procedure DefaultDepositSetup()
    begin
    end;

    internal procedure PreviousNADepositStateDetected()
    begin
        OnPreviousNADepositStateDetected();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsEnabled(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreviousNADepositStateDetected()
    begin
    end;

    var
        FeatureKeyIdTok: Label 'StandardizedBankReconciliationAndDeposits', Locked = true;
}
#endif