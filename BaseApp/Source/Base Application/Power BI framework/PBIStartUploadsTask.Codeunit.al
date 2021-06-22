#if not CLEAN18
codeunit 6311 "PBI Start Uploads Task"
{
    // // For triggering background sessions for asynchronous deployment of default Power BI reports.
    // // Called by UploadDefaultReportInBackground method of codeunit 6301.

    ObsoleteState = Pending;
    ObsoleteReason = 'The Power BI synchronization has been merged into "Power BI Report Synchronizer" and "Power BI Sync. Error Handler" codeunits';
    ObsoleteTag = '18.0';

    trigger OnRun()
    begin
        PowerBIServiceMgt.UploadDefaultReport();
    end;

    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
}
#endif