codeunit 6318 "PBI Check License Task"
{
    // // Background session to check whether user has a power bi license or not.


    trigger OnRun()
    begin
        if not CheckForPowerBILicense then begin
            if GetLastErrorText() = PowerBIServiceMgt.GetUnauthorizedErrorText() then
                PowerBISessionManager.SetHasPowerBILicense(false);

            SendTraceTag('0000B6Y', PowerBIServiceMgt.GetPowerBiTelemetryCategory(), VERBOSITY::Error,
                ExceptionMessage + ' : ' + ExceptionDetails + ' : ' + GetLastErrorText(),
                DATACLASSIFICATION::CustomerContent);

            Clear(ExceptionMessage);
            Clear(ExceptionDetails);
        end else
            PowerBISessionManager.SetHasPowerBILicense(true);
    end;

    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        PowerBISessionManager: Codeunit "Power BI Session Manager";
        ExceptionMessage: Text;
        ExceptionDetails: Text;

    [TryFunction]
    local procedure CheckForPowerBILicense()
    var
        Url: Text;
    begin
        Url := PowerBIServiceMgt.GetReportsUrl();

        // This will throw error message if unauthorized.
        PowerBIServiceMgt.GetData(ExceptionMessage, ExceptionDetails, Url);
    end;
}

