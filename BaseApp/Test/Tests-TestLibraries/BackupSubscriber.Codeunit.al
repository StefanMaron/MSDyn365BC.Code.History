codeunit 130015 "Backup Subscriber"
{
    EventSubscriberInstance = Manual;
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        BackupManagement: Codeunit "Backup Management";

    [EventSubscriber(ObjectType::Codeunit, 49, 'OnAfterOnDatabaseInsert', '', false, false)]
    local procedure OnDatabaseInsertHandler(RecRef: RecordRef)
    begin
        BackupManagement.ChangeLog(RecRef.Number);
    end;

    [EventSubscriber(ObjectType::Codeunit, 49, 'OnAfterOnDatabaseModify', '', false, false)]
    local procedure OnDatabaseModifyHandler(RecRef: RecordRef)
    begin
        BackupManagement.ChangeLog(RecRef.Number);
    end;

    [EventSubscriber(ObjectType::Codeunit, 49, 'OnAfterOnDatabaseDelete', '', false, false)]
    local procedure OnDatabaseDeleteHandler(RecRef: RecordRef)
    begin
        BackupManagement.ChangeLog(RecRef.Number);
    end;

    [EventSubscriber(ObjectType::Codeunit, 49, 'OnAfterOnDatabaseRename', '', false, false)]
    local procedure OnDatabaseRenameHandler(RecRef: RecordRef; xRecRef: RecordRef)
    begin
        BackupManagement.ChangeLog(RecRef.Number);
    end;
}

