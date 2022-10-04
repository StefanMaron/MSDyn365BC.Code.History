#if not CLEAN21
codeunit 6317 "Power BI Session Manager"
{
    // // This is singleton class to maintain information about Power BI for a user session.
    ObsoleteState = Pending;
    ObsoleteReason = 'Caching the license state caused a degraded user experience. Power BI license will be checked just in time.';
    SingleInstance = true;
    ObsoleteTag = '21.0';

    trigger OnRun()
    begin
        if not PowerBIServiceMgt.CheckPowerBITablePermissions() then
            exit;
    end;

    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        UserLicenseSetTelemetryMsg: Label 'Setting value of PowerBIUserLicense to: %1.', Locked = true;
        HasPowerBILicense: Boolean;

    [Scope('OnPrem')]
    procedure SetHasPowerBILicense(Value: Boolean)
    var
        PowerBIUserLicense: Record "Power BI User License";
    begin
        HasPowerBILicense := Value;

        Session.LogMessage('0000BVI', StrSubstNo(UserLicenseSetTelemetryMsg, Value), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());

        PowerBIUserLicense.LockTable();
        if PowerBIUserLicense.Get(UserSecurityId()) then begin
            PowerBIUserLicense."Has Power BI License" := Value;
            PowerBIUserLicense.Modify();
            exit;
        end;

        PowerBIUserLicense.Init();
        PowerBIUserLicense."Has Power BI License" := Value;
        PowerBIUserLicense."User Security ID" := UserSecurityId();
        PowerBIUserLicense.Insert();
    end;

    [Scope('OnPrem')]
    procedure GetHasPowerBILicense(): Boolean
    var
        PowerBIUserLicense: Record "Power BI User License";
    begin
        if HasPowerBILicense then
            exit(true);

        if PowerBIUserLicense.Get(UserSecurityId()) then
            HasPowerBILicense := PowerBIUserLicense."Has Power BI License";

        exit(HasPowerBILicense);
    end;

    [Scope('OnPrem')]
    procedure ClearState(): Boolean
    begin
        // Clear all possible state
        Clear(HasPowerBILicense);
        Clear(PowerBIServiceMgt);
    end;
}
#endif