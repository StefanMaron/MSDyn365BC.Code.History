codeunit 455 "Job Queue User Handler"
{

    trigger OnRun()
    begin
        RescheduleJobQueueEntries;
    end;

    local procedure RescheduleJobQueueEntries()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetFilter(Status, '%1|%2', JobQueueEntry.Status::Ready, JobQueueEntry.Status::"In Process");
        JobQueueEntry.SetRange("Recurring Job", true);
        if JobQueueEntry.FindSet(true) then
            repeat
                if JobShouldBeRescheduled(JobQueueEntry) then begin
                    JobQueueEntry.Status := JobQueueEntry.Status::Ready;
                    JobQueueEntry."Earliest Start Date/Time" := CurrentDateTime();
                    JobQueueEntry.Modify();
                    if TaskScheduler.SetTaskReady(JobQueueEntry."System Task ID", JobQueueEntry."Earliest Start Date/Time") then;
                end;
            until JobQueueEntry.Next() = 0;

        JobQueueEntry.FilterInactiveOnHoldEntries();
        if JobQueueEntry.FindSet(true) then
            repeat
                if JobQueueEntry.DoesJobNeedToBeRun() then begin
                    JobQueueEntry.Status := JobQueueEntry.Status::Ready;
                    JobQueueEntry."Earliest Start Date/Time" := CurrentDateTime();
                    JobQueueEntry.Modify();
                    if TaskScheduler.SetTaskReady(JobQueueEntry."System Task ID", JobQueueEntry."Earliest Start Date/Time") then;
                end;
            until JobQueueEntry.Next() = 0;
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
        if not TASKSCHEDULER.CanCreateTask then
            exit;
        if not User.Get(UserSecurityId) then
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

