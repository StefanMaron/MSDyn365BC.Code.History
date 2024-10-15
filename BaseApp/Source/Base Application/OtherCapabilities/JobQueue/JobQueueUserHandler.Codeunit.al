codeunit 455 "Job Queue User Handler"
{
    var
        JobQueueRescheduledTxt: Label 'Job queue entry rescheduled on login: %1', Comment = '%1 - Job Queue Entry ID', Locked = true;

    trigger OnRun()
    begin
        RescheduleJobQueueEntries();
    end;

    local procedure RescheduleJobQueueEntries()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetFilter(Status, '%1|%2', JobQueueEntry.Status::Ready, JobQueueEntry.Status::"In Process");
        JobQueueEntry.SetRange("Recurring Job", true);
        if JobQueueEntry.FindSet(true) then
            repeat
                if JobShouldBeRescheduled(JobQueueEntry) then
                    Reschedule(JobQueueEntry);
            until JobQueueEntry.Next() = 0;

        JobQueueEntry.FilterInactiveOnHoldEntries();
        if JobQueueEntry.FindSet(true) then
            repeat
                if JobQueueEntry.DoesJobNeedToBeRun() then
                    Reschedule(JobQueueEntry);
            until JobQueueEntry.Next() = 0;
    end;

    local procedure Reschedule(var JobQueueEntry: Record "Job Queue Entry")
    var
        Telemetry: Codeunit Telemetry;
        TelemetrySubscribers: Codeunit "Telemetry Subscribers";
        Dimensions: Dictionary of [Text, Text];
    begin
        if TaskScheduler.SetTaskReady(JobQueueEntry."System Task ID", JobQueueEntry."Earliest Start Date/Time") then begin
            JobQueueEntry.Status := JobQueueEntry.Status::Ready;
            JobQueueEntry."Earliest Start Date/Time" := CurrentDateTime();
            JobQueueEntry.Modify();
            Dimensions.Add('JobQueueRescheduledNewTask', Format(false));
        end else begin
            JobQueueEntry.Restart();
            Dimensions.Add('JobQueueRescheduledNewTask', Format(true));
        end;
        TelemetrySubscribers.SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);

        Telemetry.LogMessage('0000I49', StrSubstNo(JobQueueRescheduledTxt, Format(JobQueueEntry.ID, 0, 4)),
                                Verbosity::Normal,
                                DataClassification::OrganizationIdentifiableInformation,
                                TelemetryScope::All,
                                Dimensions)
    end;

    local procedure JobShouldBeRescheduled(JobQueueEntry: Record "Job Queue Entry") Result: Boolean
    var
        User: Record User;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeJobShouldBeRescheduled(JobQueueEntry, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if JobQueueEntry."User ID" = UserId then begin
            JobQueueEntry.CalcFields(Scheduled);
            exit(not JobQueueEntry.Scheduled);
        end;
        User.SetRange("User Name", JobQueueEntry."User ID");
        exit(User.IsEmpty);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure RescheduleJobQueueEntriesOnCompanyOpen()
    var
        JobQueueEntry: Record "Job Queue Entry";
        User: Record User;
    begin
        if not GuiAllowed then
            exit;
        if not (JobQueueEntry.WritePermission and JobQueueEntry.ReadPermission) then
            exit;
        if not (JobQueueEntry.TryCheckRequiredPermissions()) then
            exit;
        if not TASKSCHEDULER.CanCreateTask() then
            exit;
        if not User.Get(UserSecurityId()) then
            exit;
        if User."License Type" = User."License Type"::"Limited User" then
            exit;

        TASKSCHEDULER.CreateTask(CODEUNIT::"Job Queue User Handler", 0, true, CompanyName, CurrentDateTime + 15000); // Add 15s
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobShouldBeRescheduled(var JobQueueEntry: Record "Job Queue Entry"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

