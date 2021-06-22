codeunit 6317 "Power BI Session Manager"
{
    // // This is singleton class to maintain information about Power BI for a user session.

    SingleInstance = true;

    trigger OnRun()
    begin
        if not PowerBIServiceMgt.CheckPowerBITablePermissions() then begin
            exit;
        end;
    end;

    var
        PowerBIUserLicense: Record "Power BI User License";
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        UserLicenseSetTelemetryMsg: Label 'Setting value of PowerBIUserLicense to: %1.', Locked = true;
        HasPowerBILicense: Boolean;

    [Scope('OnPrem')]
    procedure SetHasPowerBILicense(Value: Boolean)
    begin
        HasPowerBILicense := Value;

        Session.LogMessage('0000BVI', StrSubstNo(UserLicenseSetTelemetryMsg, Value), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());

        PowerBIUserLicense.LockTable();
        if PowerBIUserLicense.Get(UserSecurityId) then begin
            PowerBIUserLicense."Has Power BI License" := Value;
            PowerBIUserLicense.Modify();
            exit;
        end;

        PowerBIUserLicense.Init();
        PowerBIUserLicense."Has Power BI License" := Value;
        PowerBIUserLicense."User Security ID" := UserSecurityId;
        PowerBIUserLicense.Insert();
    end;

    [Scope('OnPrem')]
    procedure GetHasPowerBILicense(): Boolean
    begin
        if HasPowerBILicense then
            exit(true);

        if PowerBIUserLicense.Get(UserSecurityId) then
            HasPowerBILicense := PowerBIUserLicense."Has Power BI License";

        exit(HasPowerBILicense);
    end;
}

