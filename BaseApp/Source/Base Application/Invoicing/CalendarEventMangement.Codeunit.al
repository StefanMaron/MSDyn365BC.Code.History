#if not CLEAN24
codeunit 2160 "Calendar Event Mangement"
{
    Permissions = TableData "Calendar Event" = rimd,
                  TableData "Calendar Event User Config." = rimd;
    ObsoleteReason = 'Invoicing';
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';

    trigger OnRun()
    begin
    end;

    var
        JobQueueEntryDescTxt: Label 'Auto-created for communicating with Microsoft Invoicing. Can be deleted if not used. Will be recreated when the feature is activated.';

    [Obsolete('Invoicing', '24.0')]
    procedure CreateCalendarEvent(ScheduledDate: Date; Description: Text[100]; CodeunitNo: Integer; RecId: RecordID; QueueEvent: Boolean): Integer
    var
        CalendarEvent: Record "Calendar Event";
    begin
        CalendarEvent.Init();
        CalendarEvent.Validate(Description, Description);
        CalendarEvent.Validate("Scheduled Date", ScheduledDate);
        CalendarEvent.Validate("Object ID to Run", CodeunitNo);
        CalendarEvent.Validate("Record ID to Process", RecId);
        if not QueueEvent then
            CalendarEvent.Validate(State, CalendarEvent.State::"On Hold");
        CalendarEvent.Insert(true);

        exit(CalendarEvent."No.")
    end;

    [Obsolete('Invoicing', '24.0')]
    procedure CreateCalendarEventForCodeunit(ScheduledDate: Date; Description: Text[100]; CodeunitNo: Integer): Integer
    var
        CalendarEvent: Record "Calendar Event";
    begin
        CalendarEvent.Init();
        CalendarEvent.Validate(Description, Description);
        CalendarEvent.Validate("Scheduled Date", ScheduledDate);
        CalendarEvent.Validate("Object ID to Run", CodeunitNo);
        CalendarEvent.Validate(Type, CalendarEvent.Type::System);
        CalendarEvent.Insert(true);

        exit(CalendarEvent."No.")
    end;

    [Obsolete('Invoicing', '24.0')]
    procedure QueueBackgroundSystemEvent(Description: Text[100]; CodeunitNo: Integer; RecId: RecordID): Integer
    var
        CalendarEvent: Record "Calendar Event";
    begin
        CalendarEvent.Init();
        CalendarEvent.Validate(Description, Description);
        CalendarEvent.Validate("Scheduled Date", Today);
        CalendarEvent.Validate(Type, CalendarEvent.Type::System);
        CalendarEvent.Validate("Object ID to Run", CodeunitNo);
        CalendarEvent.Validate("Record ID to Process", RecId);
        CalendarEvent.Insert(true);

        exit(CalendarEvent."No.")
    end;

    [Obsolete('Invoicing', '24.0')]
    procedure CreateOrUpdateJobQueueEntry(CalendarEvent: Record "Calendar Event")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        FindOrCreateJobQueue(JobQueueEntry);
        UpdateJobQueueWithSuggestedDate(JobQueueEntry, CalendarEvent);
    end;

    [Obsolete('Invoicing', '24.0')]
    procedure DescheduleCalendarEvent(var CalendarEvent: Record "Calendar Event")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not FindJobQueue(JobQueueEntry) then
            exit;

        // If the next scheduled run date matches this record
        // We may be able to move it further back if there were no more events on this date.
        if GetNextJobQueueRunDate(JobQueueEntry) = CalendarEvent."Scheduled Date" then
            UpdateJobQueue(JobQueueEntry);
    end;

    [Obsolete('Invoicing', '24.0')]
    procedure DescheduleCalendarEventForCodeunit(CodeunitID: Integer)
    var
        CalendarEvent: Record "Calendar Event";
    begin
        CalendarEvent.SetRange("Object ID to Run", CodeunitID);
        CalendarEvent.SetRange(Archived, false);
        CalendarEvent.DeleteAll(true);
    end;

    [Obsolete('Invoicing', '24.0')]
    procedure FindJobQueue(var JobQueueEntry: Record "Job Queue Entry"): Boolean
    var
        CalendarEventUserConfig: Record "Calendar Event User Config.";
    begin
        GetCalendarEventUserConfiguration(CalendarEventUserConfig);

        if IsNullGuid(CalendarEventUserConfig."Current Job Queue Entry") then
            exit(false);

        exit(JobQueueEntry.Get(CalendarEventUserConfig."Current Job Queue Entry"));
    end;

    [Obsolete('Invoicing', '24.0')]
    procedure SetJobQueueOnHold(var JobQueueEntry: Record "Job Queue Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetJobQueueOnHold(JobQueueEntry, IsHandled);
        if IsHandled then
            exit;

        JobQueueEntry.LockTable(true);
        JobQueueEntry.Find();

        if JobQueueEntry.Status <> JobQueueEntry.Status::"On Hold" then begin
            Clear(JobQueueEntry."User ID");
            JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        end;

        JobQueueEntry.Modify(true);
    end;

    [Obsolete('Invoicing', '24.0')]
    procedure UpdateJobQueue(var JobQueueEntry: Record "Job Queue Entry")
    var
        CalendarEvent: Record "Calendar Event";
    begin
        UpdateJobQueueWithFilter(JobQueueEntry, CalendarEvent);
    end;

    local procedure UpdateJobQueueWithSuggestedDate(var JobQueueEntry: Record "Job Queue Entry"; CalendarEvent: Record "Calendar Event")
    var
        OtherCalendarEvent: Record "Calendar Event";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateJobQueueWithSuggestedDate(JobQueueEntry, CalendarEvent, IsHandled);
        if IsHandled then
            exit;

        JobQueueEntry.LockTable();
        JobQueueEntry.Find();

        if CalendarEvent."Scheduled Date" > GetNextJobQueueRunDate(JobQueueEntry) then begin
            if not OtherCalendarEvent.Get(CalendarEvent."No.") then // Check if this is an existing event
                exit; // It's new, so no need to check if we need to update the date

            // It's an existing event - check that we weren't waiting for this one originally
            if OtherCalendarEvent."Scheduled Date" > GetNextJobQueueRunDate(JobQueueEntry) then
                exit;

            // Find the next date (ignoring this event)
            OtherCalendarEvent.SetFilter("No.", '<>%1', CalendarEvent."No.");
            UpdateJobQueueWithFilter(JobQueueEntry, OtherCalendarEvent);

            // Then check if the updated date is after the new date we found
            if CalendarEvent."Scheduled Date" > GetNextJobQueueRunDate(JobQueueEntry) then
                exit; // It is, so no need to update with the proposed date
        end;

        SetNextJobQueueRunDate(JobQueueEntry, CalendarEvent."Scheduled Date");
    end;

    local procedure UpdateJobQueueWithFilter(var JobQueueEntry: Record "Job Queue Entry"; var CalendarEvent: Record "Calendar Event")
    begin
        CalendarEvent.SetCurrentKey("Scheduled Date");
        CalendarEvent.SetAscending("Scheduled Date", true);
        CalendarEvent.SetRange(Archived, false);
        CalendarEvent.SetRange(User, UserId);
        CalendarEvent.SetRange(State, CalendarEvent.State::Queued);

        if not CalendarEvent.FindFirst() then begin
            SetJobQueueOnHold(JobQueueEntry);
            exit;
        end;

        SetNextJobQueueRunDate(JobQueueEntry, CalendarEvent."Scheduled Date");
    end;

    local procedure FindOrCreateJobQueue(var JobQueueEntry: Record "Job Queue Entry")
    var
        CalendarEventUserConfig: Record "Calendar Event User Config.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindOrCreateJobQueue(JobQueueEntry, IsHandled);
        if IsHandled then
            exit;

        if FindJobQueue(JobQueueEntry) then
            exit;

        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Calendar Event Execution";
        JobQueueEntry."Maximum No. of Attempts to Run" := 3;
        JobQueueEntry."Recurring Job" := true;
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry."Manual Recurrence" := true;
        JobQueueEntry.Description := CopyStr(JobQueueEntryDescTxt, 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry.Insert(true);

        GetCalendarEventUserConfiguration(CalendarEventUserConfig);
        CalendarEventUserConfig."Current Job Queue Entry" := JobQueueEntry.ID;
        CalendarEventUserConfig.Modify(true);
    end;

    local procedure GetJobQueueRunTime() Result: Time
    var
        CalendarEventUserConfig: Record "Calendar Event User Config.";
    begin
        Result := 0T;

        GetCalendarEventUserConfiguration(CalendarEventUserConfig);

        exit(CalendarEventUserConfig."Default Execute Time");
    end;

    local procedure GetNextJobQueueRunDate(var JobQueueEntry: Record "Job Queue Entry"): Date
    begin
        if JobQueueEntry.Status <> JobQueueEntry.Status::Ready then
            exit(DMY2Date(31, 12, 9999));

        exit(DT2Date(JobQueueEntry."Earliest Start Date/Time"));
    end;

    local procedure SetNextJobQueueRunDate(var JobQueueEntry: Record "Job Queue Entry"; NewDate: Date)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetNextJobQueueRunDate(JobQueueEntry, NewDate, IsHandled);
        if IsHandled then
            exit;

        JobQueueEntry.LockTable(true);
        JobQueueEntry.Find();

        if NewDate <= Today then
            JobQueueEntry."Earliest Start Date/Time" := CreateDateTime(Today, Time + (5 * 1000))
        else
            JobQueueEntry."Earliest Start Date/Time" := CreateDateTime(NewDate, GetJobQueueRunTime());

        Clear(JobQueueEntry."User ID");

        if JobQueueEntry.Status <> JobQueueEntry.Status::Ready then
            JobQueueEntry.Status := JobQueueEntry.Status::Ready;

        JobQueueEntry.Modify(true);
    end;

    local procedure GetCalendarEventUserConfiguration(var CalendarEventUserConfig: Record "Calendar Event User Config.")
    begin
        CalendarEventUserConfig.LockTable();
        if not CalendarEventUserConfig.Get(UserId) then begin
            CalendarEventUserConfig.Init();
            CalendarEventUserConfig.Validate(User, UserId);
            if not CalendarEventUserConfig.Insert(true) then // Insert failed, possibly because it was just inserted in another session
                CalendarEventUserConfig.Get(UserId); // Try to get the record one more time before failing
        end;
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Invoicing', '24.0')]
    local procedure OnBeforeFindOrCreateJobQueue(var JobQueueEntry: Record "Job Queue Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Invoicing', '24.0')]
    local procedure OnBeforeSetNextJobQueueRunDate(var JobQueueEntry: Record "Job Queue Entry"; NewDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Invoicing', '24.0')]
    local procedure OnBeforeSetJobQueueOnHold(var JobQueueEntry: Record "Job Queue Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Invoicing', '24.0')]
    local procedure OnBeforeUpdateJobQueueWithSuggestedDate(var JobQueueEntry: Record "Job Queue Entry"; CalendarEvent: Record "Calendar Event"; var IsHandled: Boolean)
    begin
    end;
}
#endif

