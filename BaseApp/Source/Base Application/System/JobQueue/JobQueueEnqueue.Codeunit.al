namespace System.Threading;

codeunit 453 "Job Queue - Enqueue"
{
    Permissions = TableData "Job Queue Entry" = rimd;
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        EnqueueJobQueueEntry(Rec);
    end;

    local procedure EnqueueJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry")
    var
        SavedStatus: Option;
    begin
        OnBeforeEnqueueJobQueueEntry(JobQueueEntry);

        JobQueueEntry.CheckRequiredPermissions();

        SavedStatus := JobQueueEntry.Status;
        InitEntryForSchedulerWithDelayInSec(JobQueueEntry, 1);
        if IsNullGuid(JobQueueEntry.ID) then
            JobQueueEntry.Insert(true)
        else begin
            if CanScheduleTask(JobQueueEntry) then
                JobQueueEntry.CancelTask(); // clears "System Task ID"
            JobQueueEntry.Modify();
        end;

        if CanScheduleTask(JobQueueEntry) and not UpdateStatusOnHoldWithInactivityTimeout(JobQueueEntry, SavedStatus) then
            JobQueueEntry."System Task ID" := JobQueueEntry.ScheduleTask();

        if not IsNullGuid(JobQueueEntry."System Task ID") then begin
            if SavedStatus = JobQueueEntry.Status::"On Hold with Inactivity Timeout" then
                JobQueueEntry.Status := SavedStatus
            else
                JobQueueEntry.Status := JobQueueEntry.Status::Ready;
            OnEnqueueJobQueueEntryOnBeforeJobQueueEntrySecondModify(JobQueueEntry);
            JobQueueEntry.Modify();
        end;

        OnAfterEnqueueJobQueueEntry(JobQueueEntry);
    end;

    local procedure InitEntryForSchedulerWithDelayInSec(var JobQueueEntry: Record "Job Queue Entry"; DelayInSec: Integer)
    begin
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry."User Session Started" := 0DT;
        if JobQueueEntry."Earliest Start Date/Time" < (CurrentDateTime + 1000) then
            JobQueueEntry."Earliest Start Date/Time" := CurrentDateTime + DelayInSec * 1000;
    end;

    local procedure UpdateStatusOnHoldWithInactivityTimeout(var JobQueueEntry: Record "Job Queue Entry"; SavedStatus: Integer): Boolean
    begin
        if (SavedStatus = JobQueueEntry.Status::"On Hold with Inactivity Timeout") and (JobQueueEntry."Inactivity Timeout Period" = 0) then begin
            if JobQueueEntry.Status <> JobQueueEntry.Status::"On Hold with Inactivity Timeout" then begin
                JobQueueEntry.Status := JobQueueEntry.Status::"On Hold with Inactivity Timeout";
                JobQueueEntry.Modify();
            end;
            exit(true);
        end;

        exit(false);
    end;

    local procedure CanScheduleTask(var JobQueueEntry: Record "Job Queue Entry"): Boolean
    var
        DoNotScheduleTask: Boolean;
    begin
        OnBeforeJobQueueScheduleTask(JobQueueEntry, DoNotScheduleTask);
        exit(not DoNotScheduleTask);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterEnqueueJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEnqueueJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobQueueScheduleTask(var JobQueueEntry: Record "Job Queue Entry"; var DoNotScheduleTask: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEnqueueJobQueueEntryOnBeforeJobQueueEntrySecondModify(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;
}

