codeunit 130630 "No Transactions Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseDelete', '', false, false)]
    local procedure ThrowErrorOnDelete(RecRef: RecordRef)
    begin
        if RecRef.IsTemporary() then
            exit;

        Error(StrSubstNo(TransactionDetectedErr, RecRef.RecordId(), 'DELETE'));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseInsert', '', false, false)]
    local procedure ThrowErrorOnInsert(RecRef: RecordRef)
    begin
        if RecRef.IsTemporary() then
            exit;

        Error(StrSubstNo(TransactionDetectedErr, RecRef.RecordId(), 'INSERT'));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseModify', '', false, false)]
    local procedure ThrowErrorOnModify(RecRef: RecordRef)
    begin
        if RecRef.IsTemporary() then
            exit;

        Error(StrSubstNo(TransactionDetectedErr, RecRef.RecordId(), 'MODIFY'));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseRename', '', false, false)]
    local procedure ThrowErrorOnRename(RecRef: RecordRef)
    begin
        if RecRef.IsTemporary() then
            exit;

        Error(StrSubstNo(TransactionDetectedErr, RecRef.RecordId(), 'RENAME'));
    end;

    var
        TransactionDetectedErr: Label 'Database transaction has been detected, no writes are allowed during this test. RecordID is %1, Operation %2.', Locked = true;
}