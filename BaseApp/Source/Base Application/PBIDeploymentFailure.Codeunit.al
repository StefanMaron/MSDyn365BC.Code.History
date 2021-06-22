codeunit 6313 "PBI Deployment Failure"
{
    // // Handles background task failures triggered when doing Power BI report deployment in
    // // codeunits 6311 - just sets the flag in table 6308 to show that no background
    // // deployment is happening anymore.


    trigger OnRun()
    begin
        PowerBIServiceMgt.SetIsDeployingReports(false);
    end;

    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
}

