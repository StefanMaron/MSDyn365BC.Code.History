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

        with JobQueueEntry do begin
            SavedStatus := Status;
            InitEntryForSchedulerWithDelayInSec(JobQueueEntry, 1);
            if IsNullGuid(ID) then
                Insert(true)
            else begin
                if CanScheduleTask(JobQueueEntry) then
                    CancelTask; // clears "System Task ID"
                Modify;
            end;

            if CanScheduleTask(JobQueueEntry) and not UpdateStatusOnHoldWithInactivityTimeout(JobQueueEntry, SavedStatus) then
                "System Task ID" := ScheduleTask;

            if not IsNullGuid("System Task ID") then begin
                if SavedStatus = Status::"On Hold with Inactivity Timeout" then
                    Status := SavedStatus
                else
                    Status := Status::Ready;
                Modify;
            end;
        end;

        OnAfterEnqueueJobQueueEntry(JobQueueEntry);
    end;

    local procedure InitEntryForSchedulerWithDelayInSec(var JobQueueEntry: Record "Job Queue Entry"; DelayInSec: Integer)
    begin
        with JobQueueEntry do begin
            Status := Status::"On Hold";
            "User Session Started" := 0DT;
            if "Earliest Start Date/Time" < (CurrentDateTime + 1000) then
                "Earliest Start Date/Time" := CurrentDateTime + DelayInSec * 1000;
        end;
    end;

    local procedure UpdateStatusOnHoldWithInactivityTimeout(var JobQueueEntry: Record "Job Queue Entry"; SavedStatus: Integer): Boolean
    begin
        with JobQueueEntry do
            if (SavedStatus = Status::"On Hold with Inactivity Timeout") and ("Inactivity Timeout Period" = 0) then begin
                if Status <> Status::"On Hold with Inactivity Timeout" then begin
                    Status := Status::"On Hold with Inactivity Timeout";
                    Modify;
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
}

