namespace System.Threading;

using System.Environment;
using System.Environment.Configuration;
using System.Security.AccessControl;
using System.Telemetry;

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
        User: Record User;
        UserExists: Boolean;
    begin
        User.SetRange("User Name", UserId());
        UserExists := not User.IsEmpty();

        JobQueueEntry.SetFilter(Status, '%1|%2', JobQueueEntry.Status::Ready, JobQueueEntry.Status::"In Process");
        JobQueueEntry.SetRange("Recurring Job", true);
        JobQueueEntry.SetRange(Scheduled, false);
        if JobQueueEntry.FindSet(true) then
            repeat
                if JobShouldBeRescheduled(JobQueueEntry, UserExists) then
                    Reschedule(JobQueueEntry);
            until JobQueueEntry.Next() = 0;

        JobQueueEntry.FilterInactiveOnHoldEntries();
        JobQueueEntry.SetRange(Scheduled, false);
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

    local procedure JobShouldBeRescheduled(JobQueueEntry: Record "Job Queue Entry"; UserExists: Boolean) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        if not UserExists then
            exit(false);

        IsHandled := false;
        OnBeforeJobShouldBeRescheduled(JobQueueEntry, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if UserExists then
            exit(true);

        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure RescheduleJobQueueEntriesOnCompanyOpen()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ScheduledTask: Record "Scheduled Task";
        User: Record User;
    begin
        if not GuiAllowed then
            exit;
        if not (JobQueueEntry.WritePermission and JobQueueEntry.ReadPermission) then
            exit;
        if not (JobQueueEntry.HasRequiredPermissions()) then
            exit;
        if not TaskScheduler.CanCreateTask() then
            exit;
        if not User.Get(UserSecurityId()) then
            exit;
        if User."License Type" = User."License Type"::"Limited User" then
            exit;

        ScheduledTask.SetRange("Run Codeunit", Codeunit::"Job Queue User Handler");
        ScheduledTask.SetRange(Company, CompanyName());
        ScheduledTask.SetRange("User ID", UserSecurityId());
        ScheduledTask.SetRange("Is Ready", true);
        if ScheduledTask.IsEmpty() then
            TaskScheduler.CreateTask(Codeunit::"Job Queue User Handler", 0, true, CompanyName, CurrentDateTime + 15000); // Add 15s
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobShouldBeRescheduled(var JobQueueEntry: Record "Job Queue Entry"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

