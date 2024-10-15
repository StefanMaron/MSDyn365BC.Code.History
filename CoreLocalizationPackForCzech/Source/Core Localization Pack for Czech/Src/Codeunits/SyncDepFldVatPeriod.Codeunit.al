#pragma warning disable AL0432
codeunit 31176 "Sync.Dep.Fld-VatPeriod CZL"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit will be removed after removing feature from Base Application.';
    ObsoleteTag = '17.0';

    [EventSubscriber(ObjectType::Table, Database::"VAT Period", 'OnBeforeRenameEvent', '', false, false)]
    local procedure SyncOnBeforeRenameVATPeriod(var Rec: Record "VAT Period"; var xRec: Record "VAT Period")
    var
        VATPeriodCZL: Record "VAT Period CZL";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"VAT Period", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"VAT Period CZL", 0);
        if VATPeriodCZL.Get(xRec."Starting Date") then
            VATPeriodCZL.Rename(Rec."Starting Date");
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"VAT Period CZL", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Period", 'OnAfterInsertEvent', '', false, false)]
    local procedure SyncOnAfterInsertVATPeriod(var Rec: Record "VAT Period")
    begin
        SyncVATPeriod(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Period", 'OnAfterModifyEvent', '', false, false)]
    local procedure SyncOnAfterModifyVATPeriod(var Rec: Record "VAT Period")
    begin
        SyncVATPeriod(Rec);
    end;

    local procedure SyncVATPeriod(var Rec: Record "VAT Period")
    var
        VATPeriodCZL: Record "VAT Period CZL";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"VAT Period", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"VAT Period CZL", 0);
        if not VATPeriodCZL.Get(Rec."Starting Date") then begin
            VATPeriodCZL.Init();
            VATPeriodCZL."Starting Date" := Rec."Starting Date";
            VATPeriodCZL.Insert(false);
        end;
        VATPeriodCZL.Name := Rec.Name;
        VATPeriodCZL."New VAT Year" := Rec."New VAT Year";
        VATPeriodCZL.Closed := Rec.Closed;
        VATPeriodCZL.Modify(false);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"VAT Period CZL", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Period", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure SyncOnBeforeDeleteVATPeriod(var Rec: Record "VAT Period")
    var
        VATPeriodCZL: Record "VAT Period CZL";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"VAT Period", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"VAT Period CZL", 0);
        if VATPeriodCZL.Get(Rec."Starting Date") then
            VATPeriodCZL.Delete(false);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"VAT Period CZL", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Period CZL", 'OnBeforeRenameEvent', '', false, false)]
    local procedure SyncOnBeforeRenameVATPeriodCZL(var Rec: Record "VAT Period CZL"; var xRec: Record "VAT Period CZL")
    var
        VATPeriod: Record "VAT Period";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"VAT Period CZL", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"VAT Period", 0);
        if VATPeriod.Get(xRec."Starting Date") then
            VATPeriod.Rename(Rec."Starting Date");
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"VAT Period", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Period CZL", 'OnAfterInsertEvent', '', false, false)]
    local procedure SyncOnAfterInsertVATPeriodCZL(var Rec: Record "VAT Period CZL")
    begin
        SyncVATPeriodCZL(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Period CZL", 'OnAfterModifyEvent', '', false, false)]
    local procedure SyncOnAfterModifyVATPeriodCZL(var Rec: Record "VAT Period CZL")
    begin
        SyncVATPeriodCZL(Rec);
    end;

    local procedure SyncVATPeriodCZL(var Rec: Record "VAT Period CZL")
    var
        VATPeriod: Record "VAT Period";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if NavApp.IsInstalling() then
            exit;
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"VAT Period CZL", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"VAT Period", 0);
        if not VATPeriod.Get(Rec."Starting Date") then begin
            VATPeriod.Init();
            VATPeriod."Starting Date" := Rec."Starting Date";
            VATPeriod.Insert(false);
        end;
        VATPeriod.Name := Rec.Name;
        VATPeriod."New VAT Year" := Rec."New VAT Year";
        VATPeriod.Closed := Rec.Closed;
        VATPeriod.Modify(false);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"VAT Period", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Period CZL", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure SyncOnBeforeDeleteVATPeriodCZL(var Rec: Record "VAT Period CZL")
    var
        VATPeriod: Record "VAT Period";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"VAT Period CZL", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"VAT Period", 0);
        if VATPeriod.Get(Rec."Starting Date") then
            VATPeriod.Delete(false);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"VAT Period", 0);
    end;
}
