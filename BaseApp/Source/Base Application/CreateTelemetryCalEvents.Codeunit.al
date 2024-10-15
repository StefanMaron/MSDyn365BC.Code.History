codeunit 1352 "Create Telemetry Cal. Events"
{
    TableNo = "CodeUnit Metadata";
    Permissions = TableData "Calendar Event" = rimd;

    trigger OnRun()
    var
        CalendarEvent: Record "Calendar Event";
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        TelemetryManagement: Codeunit "Telemetry Management";
        CalendarEventMangement: Codeunit "Calendar Event Mangement";
    begin
        if not CalendarEvent.WritePermission then
            exit;
        if not TaskScheduler.CanCreateTask() then
            exit;
        if not JobQueueLogEntry.WritePermission() then
            exit;
        if not JobQueueEntry.TryCheckRequiredPermissions() then
            exit;

        if not TelemetryManagement.DoesTelemetryCalendarEventExist(Today + 1, Name, ID) then
            CalendarEventMangement.CreateCalendarEventForCodeunit(Today + 1, Name, ID);

        if not TelemetryManagement.DoesTelemetryCalendarEventExist(Today + 2, Name, ID) then
            CalendarEventMangement.CreateCalendarEventForCodeunit(Today + 2, Name, ID);
    end;
}

