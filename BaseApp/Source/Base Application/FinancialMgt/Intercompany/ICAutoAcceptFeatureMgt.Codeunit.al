#if not CLEAN20
codeunit 434 "IC Auto Accept Feature Mgt."
{
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';
    ObsoleteReason = 'The feature will be automatically enabled on version 23.0';

    trigger OnRun()
    begin
    end;

    var
        FeatureDisabledErr: Label 'This page is not available because the feature it''s for is not enabled. The new feature consolidates intercompany settings on a single page, and saves time by automatically accepting intercompany transactions in the general journal. Your administrator can enable the feature on the Feature Management page by turning on the IC auto accept general journal transactions feature update.';

    procedure IsICAutoAcceptTransactionEnabled() Result: Boolean
    begin
        Result := true;
        OnAfterIsICAutoAcceptTransactionEnabled(Result);
    end;

    procedure FailIfFeatureDisabled()
    begin
        if not IsICAutoAcceptTransactionEnabled() then
            Error(FeatureDisabledErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsICAutoAcceptTransactionEnabled(var Result: Boolean)
    begin
    end;
}
#endif