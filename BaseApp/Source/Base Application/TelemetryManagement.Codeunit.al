codeunit 1350 "Telemetry Management"
{

    trigger OnRun()
    begin
    end;

    var
        ClientTypeManagement: Codeunit "Client Type Management";

    procedure ScheduleCalEventsForTelemetryAsync(TelemetryCodeunitRecID: RecordID; CalEventsCodeunit: Integer; ExecutionDelayInSeconds: Integer)
    begin
        if not GuiAllowed then
            exit;

        if CanScheduleTask and (ExecutionDelayInSeconds >= 0) and (CalEventsCodeunit > 0) then
            if not (ClientTypeManagement.GetCurrentClientType in [CLIENTTYPE::Background, CLIENTTYPE::NAS, CLIENTTYPE::Management]) then
                TASKSCHEDULER.CreateTask(CalEventsCodeunit, 0, true, CompanyName,
                  CurrentDateTime + (ExecutionDelayInSeconds * 1000), TelemetryCodeunitRecID);
    end;

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
        exit(not DoNotScheduleTask and TASKSCHEDULER.CanCreateTask);
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeTelemetryScheduleTask(var DoNotScheduleTask: Boolean)
    begin
    end;
}

