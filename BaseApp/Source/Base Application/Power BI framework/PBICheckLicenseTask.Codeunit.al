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

        case true of
            ErrorStatusCode in [401, 403, 404]: // 404 means the Power BI user workspace has not been provisioned yet
                PowerBISessionManager.SetHasPowerBILicense(false);
            (ErrorStatusCode = 0) and (ExceptionMessage = ''):
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