codeunit 3997 "Retention Policy JQ"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        CurrSessionId: Integer;
        RetentionPolicyLogCategory: Enum "Retention Policy Log Category";
        StartApplyRetentionPolicyFromJobQueueLbl: Label 'The job queue entry that applies retention policies started.';
        EndApplyRetentionPolicyFromJobQueueLbl: Label 'The job queue entry that applies retention policies finished.';
        RescheduleOnLimitExceededLbl: Label 'The maximum number of records that you are allowed to delete at the same time has been reached. The job queue entry was scheduled to run again.';
        SkipRescheduleOnLimitExceededLbl: Label 'Wrong session ID for job queue. Did not reschedule the job queue entry. Session ID: %1, Expected Session ID %2.', Comment = '%1, %2 = integer';

    trigger OnRun()
    var
        RetentionPolicyJQ: Codeunit "Retention Policy JQ";
        RetentionPolicyLog: Codeunit "Retention Policy Log";
    begin
        BindSubscription(RetentionPolicyJQ);
        RetentionPolicyJQ.SetSessionId(Database.SessionId());
        RetentionPolicyLog.LogInfo(RetentionPolicyLogCategory::"Retention Policy - Schedule", StartApplyRetentionPolicyFromJobQueueLbl);

        Codeunit.Run(Codeunit::"Apply Retention Policy");

        RetentionPolicyLog.LogInfo(RetentionPolicyLogCategory::"Retention Policy - Schedule", EndApplyRetentionPolicyFromJobQueueLbl);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Apply Retention Policy", 'OnApplyRetentionPolicyRecordLimitExceeded', '', true, true)]
    local procedure ScheduleJobQueueEntryOnApplyRetentionPolicyRecordLimitExceeded(ApplyAllRetentionPolicies: Boolean; UserInvokedRun: Boolean; var Handled: Boolean)
    var
        JobQueueEntry: Record "Job Queue Entry";
        RetentionPolicyLog: Codeunit "Retention Policy Log";
        BlankRecordId: RecordId;
    begin
        if Handled then
            exit;

        if UserInvokedRun then
            exit;

        if not ApplyAllRetentionPolicies then
            exit;

        if Database.SessionId() <> CurrSessionId then begin
            RetentionPolicyLog.LogWarning(RetentionPolicyLogCategory::"Retention Policy - Schedule", StrSubstNo(SkipRescheduleOnLimitExceededLbl, Database.SessionId(), CurrSessionId));
            exit;
        end;

        RetentionPolicyLog.LogInfo(RetentionPolicyLogCategory::"Retention Policy - Schedule", RescheduleOnLimitExceededLbl);
        JobQueueEntry.ScheduleJobQueueEntry(Codeunit::"Retention Policy JQ", BlankRecordId);

        Handled := true;
    end;

    internal procedure SetSessionId(SessionId: Integer)
    begin
        CurrSessionId := SessionId
    end;
}