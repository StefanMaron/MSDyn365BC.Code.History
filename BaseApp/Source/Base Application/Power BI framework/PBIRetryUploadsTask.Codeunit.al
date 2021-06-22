#if not CLEAN18
codeunit 6312 "PBI Retry Uploads Task"
{
    // // For background sessions for asynchronously retrying errored-out Power BI uploads.
    // // Called by RetryUnfinishedReportsInBackground method of codeunit 6301.

    ObsoleteState = Pending;
    ObsoleteReason = 'The Power BI synchronization has been merged into "Power BI Report Synchronizer" and "Power BI Sync. Error Handler" codeunits';
    ObsoleteTag = '18.0';

    trigger OnRun()
    begin
        PowerBIServiceMgt.RetryAllPartialReportUploads();
    end;

    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
}
#endif