codeunit 6318 "PBI Check License Task"
{
    // // Background session to check whether user has a power bi license or not.


    trigger OnRun()
    begin
        if not CheckForPowerBILicense then
            if GetLastErrorText = PowerBIServiceMgt.GetUnauthorizedErrorText then begin
                PowerBISessionManager.SetHasPowerBILicense(false);
                PowerBIServiceMgt.LogException(ExceptionMessage, ExceptionDetails);
                exit;
            end;

        PowerBISessionManager.SetHasPowerBILicense(true);
    end;

    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        PowerBISessionManager: Codeunit "Power BI Session Manager";
        ExceptionMessage: Text;
        ExceptionDetails: Text;
        NullGuidTxt: Label '00000000-0000-0000-0000-000000000000';

    [TryFunction]
    local procedure CheckForPowerBILicense()
    var
        Url: Text;
    begin
        Url := PowerBIServiceMgt.GetReportsUrl;

        Url := Url + '/' + NullGuidTxt;

        // This will throw error message if unauthorized.
        PowerBIServiceMgt.GetData(ExceptionMessage, ExceptionDetails, Url);
    end;
}

