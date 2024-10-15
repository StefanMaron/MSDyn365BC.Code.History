#pragma warning disable AL0432
codeunit 31180 "Sync.Dep.Fld-InvtMvmtTempl CZL"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit will be removed after removing feature from Base Application.';
    ObsoleteTag = '17.0';

    [EventSubscriber(ObjectType::Table, Database::"Whse. Net Change Template", 'OnBeforeRenameEvent', '', false, false)]
    local procedure SyncOnBeforeRenameWhseNetChangeTemplate(var Rec: Record "Whse. Net Change Template"; var xRec: Record "Whse. Net Change Template")
    var
        InvtMovementTemplateCZL: Record "Invt. Movement Template CZL";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Whse. Net Change Template", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Invt. Movement Template CZL", 0);
        if InvtMovementTemplateCZL.Get(xRec.Name) then
            InvtMovementTemplateCZL.Rename(Rec.Name);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Invt. Movement Template CZL", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Net Change Template", 'OnAfterInsertEvent', '', false, false)]
    local procedure SyncOnAfterInsertWhseNetChangeTemplate(var Rec: Record "Whse. Net Change Template")
    begin
        SyncWhseNetChangeTemplate(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Net Change Template", 'OnAfterModifyEvent', '', false, false)]
    local procedure SyncOnAfterModifyWhseNetChangeTemplate(var Rec: Record "Whse. Net Change Template")
    begin
        SyncWhseNetChangeTemplate(Rec);
    end;

    local procedure SyncWhseNetChangeTemplate(var Rec: Record "Whse. Net Change Template")
    var
        InvtMovementTemplateCZL: Record "Invt. Movement Template CZL";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Whse. Net Change Template", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Invt. Movement Template CZL", 0);
        if not InvtMovementTemplateCZL.Get(Rec.Name) then begin
            InvtMovementTemplateCZL.Init();
            InvtMovementTemplateCZL.Name := Rec.Name;
            InvtMovementTemplateCZL.Insert(false);
        end;
        InvtMovementTemplateCZL.Description := Rec.Description;
        InvtMovementTemplateCZL."Entry Type" := Rec."Entry Type";
        InvtMovementTemplateCZL."Gen. Bus. Posting Group" := Rec."Gen. Bus. Posting Group";
        InvtMovementTemplateCZL.Modify(false);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Invt. Movement Template CZL", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Net Change Template", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure SyncOnBeforeDeleteWhseNetChangeTemplate(var Rec: Record "Whse. Net Change Template")
    var
        InvtMovementTemplateCZL: Record "Invt. Movement Template CZL";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Whse. Net Change Template", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Invt. Movement Template CZL", 0);
        if InvtMovementTemplateCZL.Get(Rec.Name) then
            InvtMovementTemplateCZL.Delete(false);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Invt. Movement Template CZL", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Invt. Movement Template CZL", 'OnBeforeRenameEvent', '', false, false)]
    local procedure SyncOnBeforeRenameInvtMovementTemplateCZL(var Rec: Record "Invt. Movement Template CZL"; var xRec: Record "Invt. Movement Template CZL")
    var
        WhseNetChangeTemplate: Record "Whse. Net Change Template";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Invt. Movement Template CZL", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Whse. Net Change Template", 0);
        if WhseNetChangeTemplate.Get(xRec.Name) then
            WhseNetChangeTemplate.Rename(Rec.Name);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Whse. Net Change Template", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Invt. Movement Template CZL", 'OnAfterInsertEvent', '', false, false)]
    local procedure SyncOnAfterInsertInvtMovementTemplateCZL(var Rec: Record "Invt. Movement Template CZL")
    begin
        SyncInvtMovementTemplateCZL(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Invt. Movement Template CZL", 'OnAfterModifyEvent', '', false, false)]
    local procedure SyncOnAfterModifyInvtMovementTemplateCZL(var Rec: Record "Invt. Movement Template CZL")
    begin
        SyncInvtMovementTemplateCZL(Rec);
    end;

    local procedure SyncInvtMovementTemplateCZL(var Rec: Record "Invt. Movement Template CZL")
    var
        WhseNetChangeTemplate: Record "Whse. Net Change Template";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if NavApp.IsInstalling() then
            exit;
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Invt. Movement Template CZL", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Whse. Net Change Template", 0);
        if not WhseNetChangeTemplate.Get(Rec.Name) then begin
            WhseNetChangeTemplate.Init();
            WhseNetChangeTemplate.Name := Rec.Name;
            WhseNetChangeTemplate.Insert(false);
        end;
        WhseNetChangeTemplate.Description := CopyStr(Rec.Description, 1, MaxStrLen(WhseNetChangeTemplate.Description));
        WhseNetChangeTemplate."Entry Type" := Rec."Entry Type";
        WhseNetChangeTemplate."Gen. Bus. Posting Group" := Rec."Gen. Bus. Posting Group";
        WhseNetChangeTemplate.Modify(false);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Whse. Net Change Template", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Invt. Movement Template CZL", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure SyncOnBeforeDeleteInvtMovementTemplateCZL(var Rec: Record "Invt. Movement Template CZL")
    var
        WhseNetChangeTemplate: Record "Whse. Net Change Template";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Invt. Movement Template CZL", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Whse. Net Change Template", 0);
        if WhseNetChangeTemplate.Get(Rec.Name) then
            WhseNetChangeTemplate.Delete(false);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Whse. Net Change Template", 0);
    end;
}
