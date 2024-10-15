namespace System.Threading;

using Microsoft.EServices.EDocument;
using System.Environment.Configuration;

codeunit 487 "Job Queue Start Report"
{
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
        ShouldModifyNotifyOnSuccess: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunReport(ReportID, JobQueueEntry, IsHandled);
        if IsHandled then
            exit;

        SetReportTimeOut(JobQueueEntry);

        ReportInbox.Init();
        ReportInbox."User ID" := JobQueueEntry."User ID";
        ReportInbox."Job Queue Log Entry ID" := JobQueueEntry.ID;
        ReportInbox."Report ID" := ReportID;
        ReportInbox.Description := JobQueueEntry.Description;
        ReportInbox."Report Output".CreateOutStream(OutStr);
        OnRunReportOnAfterAssignFields(ReportInbox, JobQueueEntry);
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
                ProcessPrint(ReportID, JobQueueEntry, RunOnRec, RecRef);
            JobQueueEntry."Report Output Type"::PDF:
                begin
                    ProcessSaveAs(ReportID, JobQueueEntry, RunOnRec, RecRef, REPORTFORMAT::Pdf, OutStr);
                    ReportInbox."Output Type" := ReportInbox."Output Type"::PDF;
                end;
            JobQueueEntry."Report Output Type"::Word:
                begin
                    ProcessSaveAs(ReportID, JobQueueEntry, RunOnRec, RecRef, REPORTFORMAT::Word, OutStr);
                    ReportInbox."Output Type" := ReportInbox."Output Type"::Word;
                end;
            JobQueueEntry."Report Output Type"::Excel:
                begin
                    ProcessSaveAs(ReportID, JobQueueEntry, RunOnRec, RecRef, REPORTFORMAT::Excel, OutStr);
                    ReportInbox."Output Type" := ReportInbox."Output Type"::Excel;
                end;
        end;

        OnRunReportOnAfterProcessDifferentReportOutputTypes(ReportID, JobQueueEntry);

        case JobQueueEntry."Report Output Type" of
            JobQueueEntry."Report Output Type"::"None (Processing only)":
                begin
                    ShouldModifyNotifyOnSuccess := JobQueueEntry."Notify On Success" = false;
                    OnRunReportOnAfterCalcShouldModifyNotifyOnSuccess(ReportID, JobQueueEntry, ShouldModifyNotifyOnSuccess);
                    if ShouldModifyNotifyOnSuccess then begin
                        JobQueueEntry."Notify On Success" := true;
                        JobQueueEntry.Modify();
                    end;
                end;

            JobQueueEntry."Report Output Type"::Print:
                ;
            else begin
                IsHandled := false;
                OnRunReportOnBeforeReportInboxInsert(ReportInbox, JobQueueEntry, IsHandled);
                if not IsHandled then begin
                    ReportInbox."Created Date-Time" := RoundDateTime(CurrentDateTime, 60000);
                    ReportInbox.Insert(true);
                end;
            end;
        end;
        OnRunReportOnBeforeCommit(ReportInbox, JobQueueEntry);
        Commit();
    end;

    local procedure ProcessPrint(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry"; RunOnRec: Boolean; var RecRef: RecordRef)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeProcessPrint(ReportID, JobQueueEntry, IsHandled);
        if IsHandled then
            exit;

        if RunOnRec then
            REPORT.Print(ReportID, JobQueueEntry.GetReportParameters(), JobQueueEntry."Printer Name", RecRef)
        else
            REPORT.Print(ReportID, JobQueueEntry.GetReportParameters(), JobQueueEntry."Printer Name");
    end;

    local procedure ProcessSaveAs(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry"; RunOnRec: Boolean; var RecordRef: RecordRef; RepFormat: ReportFormat; var OutStream: OutStream)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeProcessSaveAs(ReportID, JobQueueEntry, RunOnRec, RecordRef, RepFormat, OutStream, IsHandled);
        if IsHandled then
            exit;

        if RunOnRec then
            REPORT.SaveAs(ReportID, JobQueueEntry.GetReportParameters(), RepFormat, OutStream, RecordRef)
        else
            REPORT.SaveAs(ReportID, JobQueueEntry.GetReportParameters(), RepFormat, OutStream);
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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessPrint(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessSaveAs(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry"; RunOnRec: Boolean; var RecordRef: RecordRef; RepFormat: ReportFormat; var OutStream: OutStream; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunReport(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunReportOnAfterCalcShouldModifyNotifyOnSuccess(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry"; var ShouldModifyNotifyOnSuccess: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunReportOnAfterAssignFields(var ReportInbox: Record "Report Inbox"; var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunReportOnAfterProcessDifferentReportOutputTypes(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunReportOnBeforeReportInboxInsert(ReportInbox: Record "Report Inbox"; var JobQueueEntry: Record "Job Queue Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunReportOnBeforeCommit(ReportInbox: Record "Report Inbox"; var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;
}