#if not CLEAN18
codeunit 6315 "PBI Start Deletions Task"
{
    // // For triggering background sessions for asynchronous deletion of default Power BI reports.
    // // Called by DeleteDefaultReportsInBackground method of codeunit 6301.

    ObsoleteState = Pending;
    ObsoleteReason = 'The Power BI synchronization has been merged into "Power BI Report Synchronizer" and "Power BI Sync. Error Handler" codeunits';
    ObsoleteTag = '18.0';

    trigger OnRun()
    begin
        PowerBIServiceMgt.DeleteMarkedDefaultReports();
    end;

    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
}
#endif