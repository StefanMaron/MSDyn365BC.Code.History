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
        AutomaticAccountCodesTxt: Label 'AutomaticAccountCodes', Locked = true;
        SIEAuditFileExportTxt: label 'SIEAuditFileExport', Locked = true;
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

    procedure IsAutomaticAccountCodesEnabled(): Boolean
    begin
        exit(FeatureManagementFacade.IsEnabled(GetAutomaticAccountCodesFeatureKey()));
    end;

    procedure IsSIEAuditFileExportEnabled(): Boolean
    begin
        exit(FeatureManagementFacade.IsEnabled(GetSIEAuditFileExportFeatureKeyId()));
    end;

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

    local procedure GetAutomaticAccountCodesFeatureKey(): Text[50]
    begin
        exit(AutomaticAccountCodesTxt);
    end;

    local procedure GetSIEAuditFileExportFeatureKeyId(): Text[50]
    begin
        exit(SIEAuditFileExportTxt);
    end;

#if not CLEAN21
    local procedure GetModernActionBarFeatureKey(): Text[50]
    begin
        exit(ModernActionBarLbl);
    end;
#endif

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

        // Log feature uptake
        case FeatureKey.ID of
#if not CLEAN21
            ModernActionBarLbl:
                FeatureTelemetry.LogUptake('0000I8D', ModernActionBarLbl, Enum::"Feature Uptake Status"::Discovered);
#endif
            ExtensibleExchangeRateAdjustmentLbl:
                FeatureTelemetry.LogUptake('0000JR9', ExtensibleExchangeRateAdjustmentLbl, Enum::"Feature Uptake Status"::Discovered);
            ExtensibleInvoicePostingEngineLbl:
                FeatureTelemetry.LogUptake('0000JRA', ExtensibleInvoicePostingEngineLbl, Enum::"Feature Uptake Status"::Discovered);
            AllowMultipleCustVendPostingGroupsLbl:
                FeatureTelemetry.LogUptake('0000JRB', AllowMultipleCustVendPostingGroupsLbl, Enum::"Feature Uptake Status"::Discovered);
        end;
    end;

#if not CLEAN21
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Feature Management Facade", 'OnAfterFeatureDisableConfirmed', '', false, false)]
    local procedure HandleOnAfterFeatureDisableConfirmed(FeatureKey: Record "Feature Key")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        CustomerExperienceSurvey: Codeunit "Customer Experience Survey";
        FormsProId: Text;
        FormsProEligibilityId: Text;
        IsEligible: Boolean;
    begin
        if FeatureKey.ID = ModernActionBarLbl then begin
            FeatureTelemetry.LogUptake('0000I8E', ModernActionBarLbl, Enum::"Feature Uptake Status"::Undiscovered);
            if CustomerExperienceSurvey.RegisterEventAndGetEligibility('modernactionbar_event', 'modernactionbar', FormsProId, FormsProEligibilityId, IsEligible) then
                if IsEligible then
                    CustomerExperienceSurvey.RenderSurvey('modernactionbar', FormsProId, FormsProEligibilityId);
        end;
    end;
#endif
}