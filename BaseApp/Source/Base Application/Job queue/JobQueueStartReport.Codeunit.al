codeunit 487 "Job Queue Start Report"
{
    Access = Internal;
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        RunReport(Rec."Object ID to Run", Rec);
    end;

    local procedure RunReport(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry")
    var
        ReportInbox: Record "Report Inbox";
        RecRef: RecordRef;
        OutStr: OutStream;
        RunOnRec: Boolean;
    begin
        SetReportTimeOut(JobQueueEntry);

        ReportInbox.Init();
        ReportInbox."User ID" := JobQueueEntry."User ID";
        ReportInbox."Job Queue Log Entry ID" := JobQueueEntry.ID;
        ReportInbox."Report ID" := ReportID;
        ReportInbox.Description := JobQueueEntry.Description;
        ReportInbox."Report Output".CreateOutStream(OutStr);
        RunOnRec := RecRef.Get(JobQueueEntry."Record ID to Process");
        if RunOnRec then
            RecRef.SetRecFilter();

        case JobQueueEntry."Report Output Type" of
            JobQueueEntry."Report Output Type"::"None (Processing only)":
                if RunOnRec then
                    REPORT.Execute(ReportID, JobQueueEntry.GetReportParameters(), RecRef)
                else
                    REPORT.Execute(ReportID, JobQueueEntry.GetReportParameters());
            JobQueueEntry."Report Output Type"::Print:
                if RunOnRec then
                    REPORT.Print(ReportID, JobQueueEntry.GetReportParameters(), JobQueueEntry."Printer Name", RecRef)
                else
                    REPORT.Print(ReportID, JobQueueEntry.GetReportParameters(), JobQueueEntry."Printer Name");
            JobQueueEntry."Report Output Type"::PDF:
                begin
                    if RunOnRec then
                        REPORT.SaveAs(ReportID, JobQueueEntry.GetReportParameters(), REPORTFORMAT::Pdf, OutStr, RecRef)
                    else
                        REPORT.SaveAs(ReportID, JobQueueEntry.GetReportParameters(), REPORTFORMAT::Pdf, OutStr);
                    ReportInbox."Output Type" := ReportInbox."Output Type"::PDF;
                end;
            JobQueueEntry."Report Output Type"::Word:
                begin
                    if RunOnRec then
                        REPORT.SaveAs(ReportID, JobQueueEntry.GetReportParameters(), REPORTFORMAT::Word, OutStr, RecRef)
                    else
                        REPORT.SaveAs(ReportID, JobQueueEntry.GetReportParameters(), REPORTFORMAT::Word, OutStr);
                    ReportInbox."Output Type" := ReportInbox."Output Type"::Word;
                end;
            JobQueueEntry."Report Output Type"::Excel:
                begin
                    if RunOnRec then
                        REPORT.SaveAs(ReportID, JobQueueEntry.GetReportParameters(), REPORTFORMAT::Excel, OutStr, RecRef)
                    else
                        REPORT.SaveAs(ReportID, JobQueueEntry.GetReportParameters(), REPORTFORMAT::Excel, OutStr);
                    ReportInbox."Output Type" := ReportInbox."Output Type"::Excel;
                end;
        end;

        case JobQueueEntry."Report Output Type" of
            JobQueueEntry."Report Output Type"::"None (Processing only)":
                if JobQueueEntry."Notify On Success" = false then begin
                    JobQueueEntry."Notify On Success" := true;
                    JobQueueEntry.Modify();
                end;
            JobQueueEntry."Report Output Type"::Print:
                ;
            else begin
                    ReportInbox."Created Date-Time" := RoundDateTime(CurrentDateTime, 60000);
                    ReportInbox.Insert(true);
                end;
        end;
        Commit();
    end;

    local procedure SetReportTimeOut(JobQueueEntry: Record "Job Queue Entry")
    var
        ReportSettingsOverride: Record "Report Settings Override";
        TimoutInSeconds: Integer;
    begin
        if not ReportSettingsOverride.WritePermission then
            exit;
        if JobQueueEntry."Job Timeout" = 0 then
            exit;
        ReportSettingsOverride.LockTable();
        if JobQueueEntry."Job Timeout" = 0 then
            TimoutInSeconds := JobQueueEntry.DefaultJobTimeout() div 1000
        else
            TimoutInSeconds := JobQueueEntry."Job Timeout" div 1000;

        if ReportSettingsOverride.Get(JobQueueEntry."Object ID to Run", CompanyName) then begin
            if ReportSettingsOverride.Timeout < TimoutInSeconds then begin
                ReportSettingsOverride.Timeout := TimoutInSeconds;
                ReportSettingsOverride.Modify();
            end;
        end else
            if TimoutInSeconds > 6 * 60 * 60 then begin // Report default is 6hrs
                ReportSettingsOverride."Object ID" := JobQueueEntry."Object ID to Run";
                ReportSettingsOverride."Company Name" := CopyStr(CompanyName, 1, MaxStrLen(ReportSettingsOverride."Company Name"));
                ReportSettingsOverride.Timeout := TimoutInSeconds;
                ReportSettingsOverride.Insert();
            end;
        Commit();
    end;
}