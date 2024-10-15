#if not CLEAN24
codeunit 2161 "Calendar Event Execution"
{
    Permissions = TableData "Calendar Event" = rimd;
    ObsoleteReason = 'Invoicing';
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        OnBeforeOnRun(IsHandled);
        if IsHandled then
            exit;

        RunCalendarEvents();
    end;

    var
        ProcessCalendarTxt: Label 'Run Calendar Event';
        UnknownStateTxt: Label 'The event completed in an unknown state.';

    procedure RunCalendarEvents()
    var
        CalendarEvent: Record "Calendar Event";
        JobQueueEntry: Record "Job Queue Entry";
        CalendarEventMangement: Codeunit "Calendar Event Mangement";
    begin
        CalendarEvent.SetRange("Scheduled Date", 0D, Today);
        CalendarEvent.SetRange(Archived, false);
        CalendarEvent.SetRange(User, UserId);

        if not CalendarEvent.FindSet() then begin
            // This may happen the first time we run (i.e. after the job queue has been created)
            // UpdateJobQueue will now set the next run date to a good one.
            if CalendarEventMangement.FindJobQueue(JobQueueEntry) then // should always be called from a job queue so we should not create a new one
                CalendarEventMangement.UpdateJobQueue(JobQueueEntry);
            exit;
        end;

        repeat
            RunCalendarEvent(CalendarEvent);
        until CalendarEvent.Next() = 0;

        // Update the job queue entry if there are more events
        // Otherwise it will be rescheduled when an event is inserted
        CalendarEvent.SetRange("Scheduled Date");
        CalendarEventMangement.FindJobQueue(JobQueueEntry);

        if CalendarEvent.IsEmpty() then
            CalendarEventMangement.SetJobQueueOnHold(JobQueueEntry)
        else
            CalendarEventMangement.UpdateJobQueue(JobQueueEntry);
    end;

    local procedure RunCalendarEvent(var CalendarEvent: Record "Calendar Event")
    var
        ActivityLog: Record "Activity Log";
        Result: Boolean;
    begin
        // Execute
        Result := RunCodeunit(CalendarEvent);
        CalendarEvent.LockTable(true);
        if not CalendarEvent.Find() then begin // The event may have been removed while we executed it
            ActivityLog.LogActivity(CalendarEvent, ActivityLog.Status::Failed, ProcessCalendarTxt, CalendarEvent.Description, UnknownStateTxt);
            Commit();
            exit;
        end;

        // Log
        if Result then begin
            if CalendarEvent.Type = CalendarEvent.Type::System then begin
                CalendarEvent.Delete();
                Commit();
                exit;
            end;
            ActivityLog.LogActivity(CalendarEvent, ActivityLog.Status::Success, ProcessCalendarTxt, CalendarEvent.Description, '');
            CalendarEvent.Validate(State, CalendarEvent.State::Completed);
        end else begin
            ActivityLog.LogActivity(CalendarEvent, ActivityLog.Status::Failed, ProcessCalendarTxt, CalendarEvent.Description, '');
            CalendarEvent.Validate(State, CalendarEvent.State::Failed);
        end;

        // Mark as complete
        CalendarEvent.Validate(Archived, true);
        CalendarEvent.Modify(true);

        Commit(); // may error if we have delayed inserts - this entry will be skipped when the job queue reruns
    end;

    local procedure RunCodeunit(var CalendarEvent: Record "Calendar Event"): Boolean
    var
        AllObjWithCaption: Record AllObjWithCaption;
        CalendarEventCopy: Record "Calendar Event";
        Result: Boolean;
    begin
        if not AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Codeunit, CalendarEvent."Object ID to Run") then
            exit(false);

        if CalendarEvent.Archived then // Sanity check
            exit(false);

        if CalendarEvent.State <> CalendarEvent.State::Queued then // Sanity check
            exit(false);

        CalendarEvent.Validate(State, CalendarEvent.State::"In Progress");
        CalendarEvent.Modify(true);
        Commit(); // Now if an error occurs related to this entry we will not run it again (even if the job queue is reran)

        CalendarEventCopy := CalendarEvent;
        Result := CODEUNIT.Run(CalendarEvent."Object ID to Run", CalendarEventCopy);

        // Write back allowed changes from the event
        if CalendarEventCopy.State = CalendarEventCopy.State::Failed then
            Result := false;

        if CalendarEventCopy.Result <> '' then
            CalendarEvent.Result := CalendarEventCopy.Result;

        exit(Result);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var IsHandled: Boolean)
    begin
    end;
}
#endif
