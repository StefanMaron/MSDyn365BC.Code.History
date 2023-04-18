#if not CLEAN21
codeunit 6318 "PBI Check License Task"
{
    // // Background session to check whether user has a power bi license or not.
    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit has been merged into codeunit 6301 "Power BI Service Mgt.", procedure CheckForPowerBILicenseInForeground.';
    ObsoleteTag = '21.0';

    trigger OnRun()
    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
    begin
        PowerBIServiceMgt.CheckForPowerBILicenseInForeground();
    end;

}
#endif