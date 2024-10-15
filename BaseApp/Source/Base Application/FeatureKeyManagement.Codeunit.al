codeunit 265 "Feature Key Management"
{
    Access = Internal;

    var
        FeatureManagementFacade: Codeunit "Feature Management Facade";
        FeatureCannotBeEnabledErr: Label 'Feature ''%1'' cannot be enabled for Production environment. This feature replace old implememtation by new one and currently made available as developer preview for extension update only.', Comment = '%1 - feature description';
        FeatureShouldBeEnabledErr: Label 'You need to enable this feature first: %1', Comment = '%1 - feature name';
        AllowMultipleCustVendPostingGroupsLbl: Label 'AllowMultipleCustVendPostingGroups', Locked = true;
        ExtensibleExchangeRateAdjustmentLbl: Label 'ExtensibleExchangeRateAdjustment', Locked = true;
        ExtensibleInvoicePostingEngineLbl: Label 'ExtensibleInvoicePostingEngine', Locked = true;
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

#if not CLEAN21
    internal procedure IsModernActionBarEnabled(): Boolean
    begin
        exit(FeatureManagementFacade.IsEnabled(GetModernActionBarFeatureKey()));
    end;
#endif

    local procedure GetAllowMultipleCustVendPostingGroupsFeatureKey(): Text[50]
    begin
        exit(AllowMultipleCustVendPostingGroupsLbl);
    end;

    local procedure GetExtensibleExchangeRateAdjustmentFeatureKey(): Text[50]
    begin
        exit(ExtensibleExchangeRateAdjustmentLbl);
    end;

    local procedure GetExtensibleInvoicePostingEngineFeatureKey(): Text[50]
    begin
        exit(ExtensibleInvoicePostingEngineLbl);
    end;

    internal procedure GetFeatureCannotBeEnabledErr(): Text
    begin
        exit(FeatureCannotBeEnabledErr);
    end;

    internal procedure GetFeatureShouldBeEnabledErr(): Text
    begin
        exit(FeatureShouldBeEnabledErr);
    end;

#if not CLEAN21
    local procedure GetModernActionBarFeatureKey(): Text[50]
    begin
        exit(ModernActionBarLbl);
    end;
#endif

#if not CLEAN21
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Feature Management Facade", 'OnAfterFeatureEnableConfirmed', '', false, false)]
    local procedure HandleOnAfterFeatureEnableConfirmed(var FeatureKey: Record "Feature Key")
    var
        RequiredFeatureKey: Record "Feature Key";
        EnvironmentInformation: Codeunit "Environment Information";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        // Check feature dependencies and if feature can be enabled for Production environment
        case FeatureKey.ID of
            ExtensibleExchangeRateAdjustmentLbl:
                if EnvironmentInformation.IsSaaS() and EnvironmentInformation.IsProduction() then
                    error(FeatureCannotBeEnabledErr, FeatureKey.Description);
            ExtensibleInvoicePostingEngineLbl:
                if EnvironmentInformation.IsSaaS() and EnvironmentInformation.IsProduction() then
                    error(FeatureCannotBeEnabledErr, FeatureKey.Description);
            AllowMultipleCustVendPostingGroupsLbl:
                begin
                    if EnvironmentInformation.IsSaaS() and EnvironmentInformation.IsProduction() then
                        error(FeatureCannotBeEnabledErr, FeatureKey.Description);
                    RequiredFeatureKey.Get(ExtensibleExchangeRateAdjustmentLbl);
                    if RequiredFeatureKey.Enabled <> RequiredFeatureKey.Enabled::"All Users" then
                        error(FeatureShouldBeEnabledErr, RequiredFeatureKey.Description);
                end;
        end;

        if FeatureKey.ID = ModernActionBarLbl then
            FeatureTelemetry.LogUptake('0000I8D', ModernActionBarLbl, Enum::"Feature Uptake Status"::Discovered);
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