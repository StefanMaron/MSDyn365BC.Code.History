#if not CLEAN22
codeunit 9523 "Emit Enabled Features Signal"
{
    Access = Internal;

    trigger OnRun()
    begin
#if not CLEAN21
        LogIfModernActionBarEnabled();
#endif
#if not CLEAN22
        LogIfNewTimeSheetExperienceEnabled();
#endif
    end;

#if not CLEAN21
    local procedure LogIfModernActionBarEnabled()
    var
        FeatureKeyManagement: Codeunit "Feature Key Management";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ModernActionBarLbl: Label 'ModernActionBar', Locked = true;
    begin
        if FeatureKeyManagement.IsModernActionBarEnabled() then
            FeatureTelemetry.LogUsage('0000I8F', ModernActionBarLbl, 'Feature Enabled');
    end;
#endif

#if not CLEAN22
    local procedure LogIfNewTimeSheetExperienceEnabled()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TimeSheetManagement: Codeunit "Time Sheet Management";
    begin
        if TimeSheetManagement.TimeSheetV2Enabled() then
            FeatureTelemetry.LogUsage('0000JQU', TimeSheetManagement.GetTimeSheetV2FeatureKey(), 'Feature Enabled');
    end;
#endif
}
#endif