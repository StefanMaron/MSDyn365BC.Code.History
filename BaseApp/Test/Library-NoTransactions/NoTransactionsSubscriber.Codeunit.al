codeunit 130630 "No Transactions Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetDatabaseTableTriggerSetup', '', false, false)]
    local procedure GetTriggers(TableId: Integer; var OnDatabaseDelete: Boolean; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseRename: Boolean)
    begin
        OnDatabaseDelete := true;
        OnDatabaseInsert := true;
        OnDatabaseModify := true;
        OnDatabaseRename := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseDelete', '', false, false)]
    local procedure ThrowErrorOnDelete(RecRef: RecordRef)
    begin
        if RecRef.IsTemporary() then
            exit;

        if IsTableExcluded(RecRef) then
            exit;

        Error(StrSubstNo(TransactionDetectedErr, RecRef.RecordId(), 'DELETE'));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseInsert', '', false, false)]
    local procedure ThrowErrorOnInsert(RecRef: RecordRef)
    begin
        if RecRef.IsTemporary() then
            exit;

        if IsTableExcluded(RecRef) then
            exit;

        Error(StrSubstNo(TransactionDetectedErr, RecRef.RecordId(), 'INSERT'));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseModify', '', false, false)]
    local procedure ThrowErrorOnModify(RecRef: RecordRef)
    begin
        if RecRef.IsTemporary() then
            exit;

        if IsTableExcluded(RecRef) then
            exit;

        Error(StrSubstNo(TransactionDetectedErr, RecRef.RecordId(), 'MODIFY'));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseRename', '', false, false)]
    local procedure ThrowErrorOnRename(RecRef: RecordRef)
    begin
        if RecRef.IsTemporary() then
            exit;

        if IsTableExcluded(RecRef) then
            exit;

        Error(StrSubstNo(TransactionDetectedErr, RecRef.RecordId(), 'RENAME'));
    end;

    local procedure IsTableExcluded(RecRef: RecordRef): Boolean
    begin
        case RecRef.Name() of
            'Azure AD Mgt. Setup':
                exit(true);
            'AMC Bank Pmt. Type':
                exit(true);
            'Application Area Setup':
                exit(true);
            'Assisted Setup':
                exit(true);
            'Bank Clearing Standard':
                exit(true);
            'Cue Setup':
                exit(true);
            'Isolated Storage':
                exit(true);
            'Purchases & Payables Setup':
                exit(true);
            'Report Selections':
                exit(true);
            'Reg. No. Srv Config':
                exit(true);
            'Sales & Receivables Setup':
                exit(true);
            'Service Mgt. Setup':
                exit(true);
            'Translation':
                exit(true);
            'Transformation Rule':
                exit(true);
            'Tenant Media':
                exit(true);
            'Tenant Media Thumbnails':
                exit(true);
            'Upgrade Tags':
                exit(true);
            'Workflow - Table Relation':
                exit(true);
            'Workflow Event':
                exit(true);
            'Workflow Category':
                exit(true);
        end;

        exit(false);
    end;

    var
        TransactionDetectedErr: Label 'Database transaction has been detected, no writes are allowed during this test. RecordID is %1, Operation %2.', Locked = true;
}