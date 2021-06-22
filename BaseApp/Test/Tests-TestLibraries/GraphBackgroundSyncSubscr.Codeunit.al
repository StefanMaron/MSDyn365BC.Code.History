codeunit 130621 "Graph Background Sync. Subscr."
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, 5450, 'OnCanSyncOnInsert', '', false, false)]
    local procedure EnableSyncOnInsertOnCanSyncOnInsert(var CanSync: Boolean)
    begin
        CanSync := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5450, 'OnScheduleSyncTask', '', false, false)]
    local procedure InsertScheduledTaskOnScheduleSyncTask(CodeunitID: Integer; FailureCodeunitID: Integer; NotBefore: DateTime; RecordID: Variant)
    var
        ScheduledTask: Record "Scheduled Task";
    begin
        ScheduledTask.Init;
        ScheduledTask.ID := CreateGuid;
        ScheduledTask.Company := CompanyName;
        ScheduledTask."Run Codeunit" := CodeunitID;
        ScheduledTask."Failure Codeunit" := FailureCodeunitID;
        ScheduledTask."Not Before" := NotBefore;

        if RecordID.IsRecordId then
            ScheduledTask.Record := RecordID;

        ScheduledTask.Insert;
    end;
}

