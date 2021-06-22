codeunit 449 "Job Queue Start Codeunit"
{
    Permissions = TableData "Job Queue Entry" = rm;
    TableNo = "Job Queue Entry";

    var
        JobQueueStartContextTxt: Label 'Job Queue Start', Locked = true;

    trigger OnRun()
    var
        ErrorMessageManagement: Codeunit "Error Message Management";
        ErrorContextElement: Codeunit "Error Context Element";
    begin
        if "User Language ID" <> 0 then
            GlobalLanguage("User Language ID");

        ErrorMessageManagement.PushContext(ErrorContextElement, RecordId(), 0, JobQueueStartContextTxt);
        case "Object Type to Run" of
            "Object Type to Run"::Codeunit:
                CODEUNIT.Run("Object ID to Run", Rec);
            "Object Type to Run"::Report:
                RunReport("Object ID to Run", Rec);
        end;
        ErrorMessageManagement.Finish(ErrorContextElement);

        // Commit any remaining transactions from the target codeunit\report. This is necessary due
        // to buffered record insertion which may not have surfaced errors in CODEUNIT.RUN above.
        Commit();
        OnAfterRun(Rec);
    end;

    local procedure RunReport(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry")
    var
        ReportInbox: Record "Report Inbox";
        RecRef: RecordRef;
        OutStr: OutStream;
        RunOnRec: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunReport(ReportID, JobQueueEntry, IsHandled);
        if IsHandled then
            exit;

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
                    REPORT.Execute(ReportID, JobQueueEntry.GetReportParameters, RecRef)
                else
                    REPORT.Execute(ReportID, JobQueueEntry.GetReportParameters);
            JobQueueEntry."Report Output Type"::Print:
                if RunOnRec then
                    REPORT.Print(ReportID, JobQueueEntry.GetReportParameters, JobQueueEntry."Printer Name", RecRef)
                else
                    REPORT.Print(ReportID, JobQueueEntry.GetReportParameters, JobQueueEntry."Printer Name");
            JobQueueEntry."Report Output Type"::PDF:
                begin
                    if RunOnRec then
                        REPORT.SaveAs(ReportID, JobQueueEntry.GetReportParameters, REPORTFORMAT::Pdf, OutStr, RecRef)
                    else
                        REPORT.SaveAs(ReportID, JobQueueEntry.GetReportParameters, REPORTFORMAT::Pdf, OutStr);
                    ReportInbox."Output Type" := ReportInbox."Output Type"::PDF;
                end;
            JobQueueEntry."Report Output Type"::Word:
                begin
                    if RunOnRec then
                        REPORT.SaveAs(ReportID, JobQueueEntry.GetReportParameters, REPORTFORMAT::Word, OutStr, RecRef)
                    else
                        REPORT.SaveAs(ReportID, JobQueueEntry.GetReportParameters, REPORTFORMAT::Word, OutStr);
                    ReportInbox."Output Type" := ReportInbox."Output Type"::Word;
                end;
            JobQueueEntry."Report Output Type"::Excel:
                begin
                    if RunOnRec then
                        REPORT.SaveAs(ReportID, JobQueueEntry.GetReportParameters, REPORTFORMAT::Excel, OutStr, RecRef)
                    else
                        REPORT.SaveAs(ReportID, JobQueueEntry.GetReportParameters, REPORTFORMAT::Excel, OutStr);
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

    [IntegrationEvent(false, false)]
    local procedure OnAfterRun(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunReport(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry"; var IsHandled: Boolean)
    begin
    end;
}

