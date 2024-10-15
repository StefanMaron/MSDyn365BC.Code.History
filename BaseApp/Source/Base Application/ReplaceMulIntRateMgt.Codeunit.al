#if not CLEAN20
codeunit 31428 "Replace Mul. Int. Rate Mgt."
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Feature Multiple Interest Rate CZ will be replaced by Finance Charge Interest Rate by default.';
    ObsoleteTag = '20.0';

    var
        ReplaceMultipleInterestRateCZFeatureIdTok: Label 'ReplaceMultipleInterestRateCZ', Locked = true, MaxLength = 50;
        FinChargeInterestRateFeatureNotEnabledErr: Label 'The Finance Charge Interest Rate feature is not enabled.\Please enable it by using Feature Management before use.';

    [Obsolete('Not used anymore and will be removed.', '20.0')]
    procedure IsEnabled() FeatureEnabled: Boolean
    var
        FeatureManagementFacade: Codeunit "Feature Management Facade";
    begin
#pragma warning disable AL0432
        FeatureEnabled := FeatureManagementFacade.IsEnabled(GetFeatureKey());
        OnAfterIsEnabled(FeatureEnabled);
#pragma warning restore AL0432
    end;

    [Obsolete('Not used anymore and will be removed.', '20.0')]
    procedure TestIsEnabled()
    begin
        if not IsEnabled() then
            Error(FinChargeInterestRateFeatureNotEnabledErr);
    end;

    [Obsolete('Not used anymore and will be removed.', '20.0')]
    procedure GetFeatureKey(): Text[50]
    begin
        exit(ReplaceMultipleInterestRateCZFeatureIdTok);
    end;

    [Obsolete('Not used anymore and will be removed.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterIsEnabled(var FeatureEnabled: Boolean)
    begin
    end;
}
#endif