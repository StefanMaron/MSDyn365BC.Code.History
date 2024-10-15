codeunit 10500 "IRS 1099 Management"
{

    trigger OnRun()
    begin
    end;

    var
        BlockIfUpgradeNeededErr: Label 'You must update the form boxes in the 1099 Forms-Boxes window before you can run this report.';
        UpgradeFormBoxesNotificationMsg: Label 'The list of 1099 form boxes is not up to date.';
        UpgradeFormBoxesMsg: Label 'Upgrade the form boxes.';
        ScheduleUpgradeFormBoxesMsg: Label 'Schedule an update of the form boxes.';
        UpgradeFormBoxesScheduledMsg: Label 'A job queue entry has been created.\\Make sure Earliest Start Date/Time field in the Job Queue Entry Card window is correct, and then choose the Set Status to Ready action to schedule a background job.';
        ConfirmUpgradeNowQst: Label 'The update process can take a while and block other users activities. Do you want to start the update now?';
        FormBoxesUpgradedMsg: Label 'The 1099 form boxes are successfully updated.';

    [Scope('OnPrem')]
    procedure ShowUpgradeFormBoxesNotificationIfUpgradeNeeded()
    var
        UpgradeFormBoxes: Notification;
    begin
        if not UpgradeNeeded then
            exit;

        UpgradeFormBoxes.Id := GetUpgradeFormBoxesNotificationID;
        UpgradeFormBoxes.Message := UpgradeFormBoxesNotificationMsg;
        UpgradeFormBoxes.Scope := NOTIFICATIONSCOPE::LocalScope;
        UpgradeFormBoxes.AddAction(
          GetUpgradeFormBoxesNotificationMsg, CODEUNIT::"IRS 1099 Management", 'UpgradeFormBoxesFromNotification');
        UpgradeFormBoxes.Send;
    end;

    [Scope('OnPrem')]
    procedure ThrowErrorfUpgradeNeeded()
    begin
        if UpgradeNeeded then
            Error(BlockIfUpgradeNeededErr);
    end;

    [Scope('OnPrem')]
    procedure UpgradeNeeded(): Boolean
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
    begin
        exit(not IRS1099FormBox.Get('DIV-07'));
    end;

    local procedure GetUpgradeFormBoxesNotificationID(): Text
    begin
        exit('644a30e2-a1f4-45d1-ae23-4eb14071ea8a');
    end;

    local procedure GetUpgradeFormBoxesNotificationMsg(): Text
    begin
        if TASKSCHEDULER.CanCreateTask then
            exit(ScheduleUpgradeFormBoxesMsg);
        exit(UpgradeFormBoxesMsg);
    end;

    [Scope('OnPrem')]
    procedure UpgradeFormBoxesFromNotification(Notification: Notification)
    begin
        UpgradeFormBoxes;
    end;

    [Scope('OnPrem')]
    procedure UpgradeFormBoxes()
    var
        JobQueueEntry: Record "Job Queue Entry";
        UpgradeIRS1099FormBoxes: Codeunit "Upgrade IRS 1099 Form Boxes";
        JobQueueManagement: Codeunit "Job Queue Management";
        Confirmed: Boolean;
        Handled: Boolean;
        CanCreateTask: Boolean;
    begin
        if not UpgradeNeeded then
            exit;

        OnBeforeUpgradeFormBoxes(Handled, CanCreateTask);
        if not Handled then
            CanCreateTask := TASKSCHEDULER.CanCreateTask;
        if CanCreateTask then begin
            JobQueueEntry.Init;
            JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
            JobQueueEntry."Earliest Start Date/Time" := CreateDateTime(Today, Time + 60000);
            JobQueueEntry."Object ID to Run" := CODEUNIT::"Upgrade IRS 1099 Form Boxes";
            JobQueueManagement.CreateJobQueueEntry(JobQueueEntry);
            if GuiAllowed then
                Message(UpgradeFormBoxesScheduledMsg);
            JobQueueEntry.SetRecFilter;
            PAGE.Run(PAGE::"Job Queue Entry Card", JobQueueEntry);
        end else begin
            if GuiAllowed then
                Confirmed := Confirm(ConfirmUpgradeNowQst)
            else
                Confirmed := true;
            if Confirmed then begin
                UpgradeIRS1099FormBoxes.Run;
                Message(FormBoxesUpgradedMsg);
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpgradeFormBoxes(var Handled: Boolean; var CreateTask: Boolean)
    begin
    end;
}

