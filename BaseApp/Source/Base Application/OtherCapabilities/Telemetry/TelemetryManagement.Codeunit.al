codeunit 1350 "Telemetry Management"
{
    var
        TelemetryJobCreatedTxt: Label 'A daily job for sending telemetry is created.', Locked = true;
        DailyTelemetryCategoryTxt: Label 'AL Daily Telemetry Job.', Locked = true;

    trigger OnRun()
    begin
        OnSendDailyTelemetry();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure ScheduleDailyTelemetryAfterCompanyOpen()
    var
        JobQueueEntry: Record "Job Queue Entry";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if not EnvironmentInformation.IsSaaS() then
            exit;
        if not (Session.CurrentClientType() in [ClientType::Web, ClientType::Desktop, ClientType::Tablet, ClientType::Phone]) then
            exit;
        if not TaskScheduler.CanCreateTask() then
            exit;
        if not (JobQueueEntry.ReadPermission() and JobQueueEntry.WritePermission()) then
            exit;
        if not JobQueueEntry.TryCheckRequiredPermissions() then
            exit;

        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Telemetry Management");
        JobQueueEntry.SetRange("Recurring Job", true);
        if JobQueueEntry.FindFirst() then begin
            if JobQueueEntry.Status in [JobQueueEntry.Status::"On Hold", JobQueueEntry.Status::Error] then
                JobQueueEntry.Restart();
            exit;
        end;

        JobQueueEntry.InitRecurringJob(24 * 60); // one day
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"Telemetry Management";
        JobQueueEntry."Earliest Start Date/Time" := CreateDateTime(Today() + 1, 0T);
        Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);

        Session.LogMessage('0000ADZ', TelemetryJobCreatedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DailyTelemetryCategoryTxt);
    end;

#if not CLEAN20
    [Obsolete('Calendar events are not used for sending telemetry anymore. Subscibe to OnSendDailyTelemetry event instead.', '20.0')]
    procedure ScheduleCalEventsForTelemetryAsync(TelemetryCodeunitRecID: RecordID; CalEventsCodeunit: Integer; ExecutionDelayInSeconds: Integer)
    var
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        if not GuiAllowed then
            exit;

        if CanScheduleTask() and (ExecutionDelayInSeconds >= 0) and (CalEventsCodeunit > 0) then
            if not (ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::Background, CLIENTTYPE::NAS, CLIENTTYPE::Management]) then
                TASKSCHEDULER.CreateTask(CalEventsCodeunit, 0, true, CompanyName,
                  CurrentDateTime + (ExecutionDelayInSeconds * 1000), TelemetryCodeunitRecID);
    end;

    [Obsolete('Calendar events are not used for sending telemetry anymore. Subscibe to OnSendDailyTelemetry event instead.', '20.0')]
    procedure DoesTelemetryCalendarEventExist(EventDate: Date; Description: Text[100]; CodeunitID: Integer): Boolean
    var
        CalendarEvent: Record "Calendar Event";
    begin
        if not CalendarEvent.ReadPermission then
            exit;
        CalendarEvent.SetRange(Description, Description);
        CalendarEvent.SetRange("Scheduled Date", EventDate);
        CalendarEvent.SetRange("Object ID to Run", CodeunitID);
        CalendarEvent.SetRange(Type, CalendarEvent.Type::System);
        exit(not CalendarEvent.IsEmpty);
    end;

    local procedure CanScheduleTask(): Boolean
    var
        DoNotScheduleTask: Boolean;
    begin
        OnBeforeTelemetryScheduleTask(DoNotScheduleTask);
        exit(not DoNotScheduleTask and TASKSCHEDULER.CanCreateTask());
    end;

    [Obsolete('Calendar events are not used for sending telemetry anymore. Subscibe to OnSendDailyTelemetry event instead.', '20.0')]
    [IntegrationEvent(false, false)]
    procedure OnBeforeTelemetryScheduleTask(var DoNotScheduleTask: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnSendDailyTelemetry()
    begin
    end;
}

