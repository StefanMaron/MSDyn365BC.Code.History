#if not CLEAN20
codeunit 132465 "Telemetry Background Scheduler"
{
    ObsoleteReason = 'OnBeforeTelemetryScheduleTask will be removed.';
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';
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

#endif