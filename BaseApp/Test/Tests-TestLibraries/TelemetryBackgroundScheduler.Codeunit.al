codeunit 132465 "Telemetry Background Scheduler"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Telemetry Management", 'OnBeforeTelemetryScheduleTask', '', false, false)]
    local procedure OnBeforeTelemetryScheduleTaskEvent(var DoNotScheduleTask: Boolean)
    begin
        DoNotScheduleTask := true;
    end;
}

