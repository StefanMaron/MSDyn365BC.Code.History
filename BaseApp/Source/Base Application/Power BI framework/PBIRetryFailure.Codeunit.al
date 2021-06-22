#if not CLEAN18
codeunit 6314 "PBI Retry Failure"
{
    // // Handles background task failures triggered when retrying failed Power BI report deployments
    // // in codeunit 6312 - just sets the flag in table 6308 to show that no background retry task is
    // // happening anymore.

    ObsoleteState = Pending;
    ObsoleteReason = 'The Power BI synchronization has been merged into "Power BI Report Synchronizer" and error handling is handled by the Job Queue framework.';
    ObsoleteTag = '18.0';

    trigger OnRun()
    begin
        PowerBIServiceMgt.SetIsRetryingUploads(false);
    end;

    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
}
#endif