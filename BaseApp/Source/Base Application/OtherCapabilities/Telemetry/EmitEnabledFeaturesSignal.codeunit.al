#if not CLEAN21
codeunit 9523 "Emit Enabled Features Signal"
{
    Access = Internal;

    trigger OnRun()
    var
        FeatureKeyManagement: Codeunit "Feature Key Management";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ModernActionBarLbl: Label 'ModernActionBar', Locked = true;
    begin
        if FeatureKeyManagement.IsModernActionBarEnabled() then
            FeatureTelemetry.LogUsage('0000I8F', ModernActionBarLbl, 'Feature Enabled');
    end;
}
#endif