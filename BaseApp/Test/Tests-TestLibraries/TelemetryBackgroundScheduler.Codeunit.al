codeunit 132465 "Telemetry Background Scheduler"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, 1350, 'OnBeforeTelemetryScheduleTask', '', false, false)]
    local procedure OnBeforeTelemetryScheduleTaskEvent(var DoNotScheduleTask: Boolean)
    begin
        DoNotScheduleTask := true;
    end;
}

