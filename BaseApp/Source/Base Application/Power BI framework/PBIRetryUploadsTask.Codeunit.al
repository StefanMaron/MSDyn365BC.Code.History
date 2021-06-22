codeunit 6312 "PBI Retry Uploads Task"
{
    // // For background sessions for asynchronously retrying errored-out Power BI uploads.
    // // Called by RetryUnfinishedReportsInBackground method of codeunit 6301.


    trigger OnRun()
    begin
        PowerBIServiceMgt.RetryAllPartialReportUploads;
    end;

    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
}

