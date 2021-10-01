#if not CLEAN19
codeunit 451 "Job Queue Recover Job"
{
    Permissions = TableData "Job Queue Entry" = rm, TableData "Job Queue Log Entry" = rm, Tabledata "Session Event" = r;
    TableNo = "Job Queue Entry";
    ObsoleteState = Pending;
    ObsoleteReason = 'The recovery job is no longer needed.';
    ObsoleteTag = '19.0';

    var
        JobQueueServerTerminatedTxt: Label 'The job terminated for an unknown reason.';

    trigger OnRun()
    var
        ActiveSession: Record "Active Session";
        ErrorMessage: Text;
    begin
        Selectlatestversion();
        Rec.Locktable();
        if not Rec.Find() then
            exit;
        if Rec.Status <> Rec.Status::"In process" then
            exit;
        ActiveSession.Setrange("Server Instance ID", Rec."User Service Instance ID");
        ActiveSession.Setrange("Session ID", Rec."User Session ID");
        if not ActiveSession.IsEmpty() then begin
            Rec.ScheduleRecoveryJob();
            Rec.Modify();
        end else begin
            clear(Rec."Recovery Task Id");
            if Rec."User Language ID" <> 0 then
                GlobalLanguage(Rec."User Language ID");
            ErrorMessage := GetErrorMessage(Rec);
            if ErrorMessage = '' then
                ErrorMessage := JobQueueServerTerminatedTxt;
            UpdateLogEntry(Rec, ErrorMessage);
            if Rec."No. of Attempts to Run" >= Rec."Maximum No. of Attempts to Run" then
                Rec.SetError(ErrorMessage)
            else
                Rec.SetStatus(Rec.Status::Ready);
        end;
        Commit();
        OnAfterRunRecovery(Rec);
    end;


    local procedure UpdateLogEntry(var JobQueueEntry: Record "Job Queue Entry"; ErrorMsg: Text)
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        JobQueueLogEntry.SetRange(ID, JobQueueEntry.ID);
        JobQueueLogEntry.SetRange(Status, JobQueueLogEntry.Status::"In Process");
        JobQueueLogEntry.LockTable();
        if JobQueueLogEntry.FindLast() then begin
            JobQueueLogEntry."Error Message" := CopyStr(ErrorMsg, 1, MaxStrLen(JobQueueLogEntry."Error Message"));
            JobQueueLogEntry.Status := JobQueueLogEntry.Status::Error;
            JobQueueLogEntry.Modify();
        end
    end;

    local procedure GetErrorMessage(var JobQueueEntry: Record "Job Queue Entry"): Text
    var
        SessionEvent: Record "Session Event";
    begin
        if not SessionEvent.ReadPermission then
            exit('');
        SessionEvent.SetRange("Server Instance ID", JobQueueEntry."User Service Instance ID");
        SessionEvent.SetRange("Session ID", JobQueueEntry."User Session ID");
        SessionEvent.SetRange("Client Type", SessionEvent."Client Type"::Background);
        SessionEvent.SetFilter("Event Datetime", '>=%1', JobQueueEntry."Earliest Start Date/Time");
        SessionEvent.SetFilter(Comment, '<>%1', '');
        SessionEvent.SetCurrentKey("Event DateTime");
        if SessionEvent.FindLast() then
            exit(SessionEvent.Comment);
        exit('');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRunRecovery(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;
}
#endif