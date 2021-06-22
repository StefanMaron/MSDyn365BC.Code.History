codeunit 6315 "PBI Start Deletions Task"
{
    // // For triggering background sessions for asynchronous deletion of default Power BI reports.
    // // Called by DeleteDefaultReportsInBackground method of codeunit 6301.


    trigger OnRun()
    begin
        PowerBIServiceMgt.DeleteMarkedDefaultReports;
    end;

    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
}

