codeunit 450 "Job Queue Error Handler"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        if not DoesExistLocked then
            exit;
        SetError(GetLastErrorText);
        LogError(Rec);
    end;

    local procedure LogError(var JobQueueEntry: Record "Job Queue Entry")
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        OnBeforeLogError(JobQueueLogEntry, JobQueueEntry);

        with JobQueueLogEntry do begin
            SetRange(ID, JobQueueEntry.ID);
            SetRange(Status, Status::"In Process");
            if FindFirst then begin
                "Error Message" := JobQueueEntry."Error Message";
                SetErrorCallStack(GetLastErrorCallstack);
                Status := Status::Error;
                Modify;
                OnLogErrorOnAfterJobQueueLogEntryModify(JobQueueEntry);
            end else begin
                JobQueueEntry.InsertLogEntry(JobQueueLogEntry);
                JobQueueEntry.FinalizeLogEntry(JobQueueLogEntry);
                OnLogErrorOnAfterJobQueueLogEntryFinalizeLogEntry(JobQueueEntry);
            end;
        end;
        OnAfterLogError(JobQueueEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLogError(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLogError(var JobQueueLogEntry: Record "Job Queue Log Entry"; var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogErrorOnAfterJobQueueLogEntryModify(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogErrorOnAfterJobQueueLogEntryFinalizeLogEntry(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;
}

