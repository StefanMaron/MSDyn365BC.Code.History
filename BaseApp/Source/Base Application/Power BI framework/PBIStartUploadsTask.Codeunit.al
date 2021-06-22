codeunit 6311 "PBI Start Uploads Task"
{
    // // For triggering background sessions for asynchronous deployment of default Power BI reports.
    // // Called by UploadDefaultReportInBackground method of codeunit 6301.


    trigger OnRun()
    begin
        PowerBIServiceMgt.UploadDefaultReport;
    end;

    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
}

