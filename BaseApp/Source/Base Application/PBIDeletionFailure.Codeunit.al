codeunit 6316 "PBI Deletion Failure"
{
    // // Handles background task failures triggered when doing Power BI report deletion in
    // // codeunit 6315 - just sets the flag in table 6308 to show that no background
    // // deletion is happening anymore.


    trigger OnRun()
    begin
        PowerBIServiceMgt.SetIsDeletingReports(false);
    end;

    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
}

