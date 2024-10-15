codeunit 6318 "PBI Check License Task"
{
    // // Background session to check whether user has a power bi license or not.

    trigger OnRun()
    var
        DummyResponseText: Text;
        ExceptionMessage: Text;
        ExceptionDetails: Text;
        ErrorStatusCode: Integer;
    begin
        DummyResponseText := PowerBIServiceMgt.GetDataCatchErrors(ExceptionMessage, ExceptionDetails, ErrorStatusCode, PowerBIServiceMgt.GetReportsUrl());

        Session.LogMessage('0000C0H', StrSubstNo(PowerBiLicenseCheckStatusCodeTelemetryMsg, ErrorStatusCode), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());

        // REMARK: 404 means the Power BI user workspace has not been provisioned yet. It could be that the user just activated a license and we can actually
        // start autodeployment already, or that the user does not have a license at all and autodeployment would fail. We do not have a way to distinguish
        // these cases. So, we take the conservative approach and consider it a missing license scenario (if the license has just been assigned, it usually takes
        // 10-15 minutes to propagate and provision, so not too bad; the user can force this by uploading a report from the Power BI home page).
        case true of
            ErrorStatusCode in [401, 403, 404]:
                PowerBISessionManager.SetHasPowerBILicense(false);
            (ErrorStatusCode = 0) and (ExceptionMessage = ''): // ErrorStatusCode has a value only if a error happens (e.g. it's never 200)
                PowerBISessionManager.SetHasPowerBILicense(true);
        // Other error status codes like 500 mean that something else went wrong, so let's not change the value in the DB and retry the check next time
        end;

        if ExceptionMessage <> '' then
            Session.LogMessage('0000B6Y', StrSubstNo(PowerBiLicenseCheckFinishedTelemetryMsg, ExceptionMessage, ExceptionDetails, GetLastErrorText()), Verbosity::Warning, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
    end;

    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        PowerBISessionManager: Codeunit "Power BI Session Manager";
        PowerBiLicenseCheckFinishedTelemetryMsg: Label 'Power BI license check finished with exceptions. Exception Message: %1. Exception Details: %2. Last Error Text: %3.', Locked = true;
        PowerBiLicenseCheckStatusCodeTelemetryMsg: Label 'Power BI license check returned status code: %1.', Locked = true;
}