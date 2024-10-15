codeunit 265 "Feature Key Management"
{
    Access = Internal;

    var
        FeatureManagementFacade: Codeunit "Feature Management Facade";
        AllowMultipleCustVendPostingGroupsTxt: Label 'AllowMultipleCustVendPostingGroups', Locked = true;
        ExtensibleExchangeRateAdjustmentTxt: Label 'ExtensibleExchangeRateAdjustment', Locked = true;
        ExtensibleInvoicePostingEngineTxt: Label 'ExtensibleInvoicePostingEngine', Locked = true;
#if not CLEAN21
        ModernActionBarLbl: Label 'ModernActionBar', Locked = true;
#endif

    procedure IsAllowMultipleCustVendPostingGroupsEnabled(): Boolean
    begin
        exit(FeatureManagementFacade.IsEnabled(GetAllowMultipleCustVendPostingGroupsFeatureKey()));
    end;

    procedure IsExtensibleExchangeRateAdjustmentEnabled(): Boolean
    begin
        exit(FeatureManagementFacade.IsEnabled(GetExtensibleExchangeRateAdjustmentFeatureKey()));
    end;

    procedure IsExtensibleInvoicePostingEngineEnabled(): Boolean
    begin
        exit(FeatureManagementFacade.IsEnabled(GetExtensibleInvoicePostingEngineFeatureKey()));
    end;

    local procedure GetAllowMultipleCustVendPostingGroupsFeatureKey(): Text[50]
    begin
        exit(AllowMultipleCustVendPostingGroupsTxt);
    end;

    local procedure GetExtensibleExchangeRateAdjustmentFeatureKey(): Text[50]
    begin
        exit(ExtensibleExchangeRateAdjustmentTxt);
    end;

    local procedure GetExtensibleInvoicePostingEngineFeatureKey(): Text[50]
    begin
        exit(ExtensibleInvoicePostingEngineTxt);
    end;

#if not CLEAN21
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Feature Management Facade", 'OnAfterFeatureEnableConfirmed', '', false, false)]
    local procedure HandleOnAfterFeatureEnableConfirmed(var FeatureKey: Record "Feature Key")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if FeatureKey.ID = ModernActionBarLbl then begin
            FeatureTelemetry.LogUptake('0000I8D', ModernActionBarLbl, Enum::"Feature Uptake Status"::Discovered);
            FeatureTelemetry.LogUsage('0000I8F', ModernActionBarLbl, 'Feature Enabled');
        end;
    end;
#endif

#if not CLEAN21
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Feature Management Facade", 'OnAfterFeatureDisableConfirmed', '', false, false)]
    local procedure HandleOnAfterFeatureDisableConfirmed(FeatureKey: Record "Feature Key")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if FeatureKey.ID = ModernActionBarLbl then
            FeatureTelemetry.LogUptake('0000I8E', ModernActionBarLbl, Enum::"Feature Uptake Status"::Undiscovered);
    end;
#endif
}