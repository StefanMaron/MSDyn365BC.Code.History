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
        with JobQueueEntry do begin
            SetFilter(Status, '%1|%2',Status::Ready, Status::"In Process");
            SetRange("Recurring Job",true);
            if FindSet(true) then
                repeat
                    if JobShouldBeRescheduled(JobQueueEntry) then
                        Restart;
                until Next = 0;

              FilterInactiveOnHoldEntries;
              if FindSet(true) then
                  repeat
                      if DoesJobNeedToBeRun then
                          Restart;
                  until Next = 0;
        end;
    end;

    local procedure JobShouldBeRescheduled(JobQueueEntry: Record "Job Queue Entry"): Boolean
    var
        User: Record User;
    begin
        if JobQueueEntry."User ID" = UserId then begin
            JobQueueEntry.CalcFields(Scheduled);
            exit(not JobQueueEntry.Scheduled);
        end;
        User.SetRange("User Name", JobQueueEntry."User ID");
        exit(User.IsEmpty);
    end;

    [EventSubscriber(ObjectType::Codeunit, 40, 'OnAfterCompanyOpen', '', true, true)]
    local procedure RescheduleJobQueueEntriesOnCompanyOpen()
    var
        JobQueueEntry: Record "Job Queue Entry";
        User: Record User;
    begin
        if not GuiAllowed then
            exit;
        if not (JobQueueEntry.WritePermission and JobQueueEntry.ReadPermission) then
            exit;
        if not TASKSCHEDULER.CanCreateTask then
            exit;
        if not User.Get(UserSecurityId) then
            exit;
        if User."License Type" = User."License Type"::"Limited User" then
            exit;

        TASKSCHEDULER.CreateTask(CODEUNIT::"Job Queue User Handler", 0, true, CompanyName, CurrentDateTime + 15000); // Add 15s
    end;
}

