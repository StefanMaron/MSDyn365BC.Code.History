#pragma warning disable AL0432
codeunit 31157 "Sync.Dep.Fld-DocFooter CZL"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit will be removed after removing feature from Base Application.';
    ObsoleteTag = '17.0';

    [EventSubscriber(ObjectType::Table, Database::"Document Footer", 'OnBeforeRenameEvent', '', false, false)]
    local procedure SyncOnBeforeRenameDocumentFooter(var Rec: Record "Document Footer"; var xRec: Record "Document Footer")
    var
        DocumentFooterCZL: Record "Document Footer CZL";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Document Footer", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Document Footer CZL", 0);
        if DocumentFooterCZL.Get(xRec."Language Code") then
            DocumentFooterCZL.Rename(Rec."Language Code");
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Document Footer CZL", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Footer", 'OnAfterInsertEvent', '', false, false)]
    local procedure SyncOnAfterInsertDocumentFooter(var Rec: Record "Document Footer")
    begin
        SyncDocumentFooter(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Footer", 'OnAfterModifyEvent', '', false, false)]
    local procedure SyncOnAfterModifyDocumentFooter(var Rec: Record "Document Footer")
    begin
        SyncDocumentFooter(Rec);
    end;

    local procedure SyncDocumentFooter(var Rec: Record "Document Footer")
    var
        DocumentFooterCZL: Record "Document Footer CZL";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Document Footer", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Document Footer CZL", 0);
        if not DocumentFooterCZL.Get(Rec."Language Code") then begin
            DocumentFooterCZL.Init();
            DocumentFooterCZL."Language Code" := Rec."Language Code";
            DocumentFooterCZL.Insert(false);
        end;
        DocumentFooterCZL."Footer Text" := Rec."Footer Text";
        DocumentFooterCZL.Modify(false);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Document Footer CZL", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Footer", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure SyncOnBeforeDeleteDocumentFooter(var Rec: Record "Document Footer")
    var
        DocumentFooterCZL: Record "Document Footer CZL";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Document Footer", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Document Footer CZL", 0);
        if DocumentFooterCZL.Get(Rec."Language Code") then
            DocumentFooterCZL.Delete(false);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Document Footer CZL", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Footer CZL", 'OnBeforeRenameEvent', '', false, false)]
    local procedure SyncOnBeforeRenameDocumentFooterCZL(var Rec: Record "Document Footer CZL"; var xRec: Record "Document Footer CZL")
    var
        DocumentFooter: Record "Document Footer";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Document Footer CZL", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Document Footer", 0);
        if DocumentFooter.Get(xRec."Language Code") then
            DocumentFooter.Rename(Rec."Language Code");
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Document Footer", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Footer CZL", 'OnAfterInsertEvent', '', false, false)]
    local procedure SyncOnAfterInsertDocumentFooterCZL(var Rec: Record "Document Footer CZL")
    begin
        SyncDocumentFooterCZL(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Footer CZL", 'OnAfterModifyEvent', '', false, false)]
    local procedure SyncOnAfterModifyDocumentFooterCZL(var Rec: Record "Document Footer CZL")
    begin
        SyncDocumentFooterCZL(Rec);
    end;

    local procedure SyncDocumentFooterCZL(var Rec: Record "Document Footer CZL")
    var
        DocumentFooter: Record "Document Footer";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if NavApp.IsInstalling() then
            exit;
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Document Footer CZL", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Document Footer", 0);
        if not DocumentFooter.Get(Rec."Language Code") then begin
            DocumentFooter.Init();
            DocumentFooter."Language Code" := Rec."Language Code";
            DocumentFooter.Insert(false);
        end;
        DocumentFooter."Footer Text" := CopyStr(Rec."Footer Text", 1, MaxStrLen(DocumentFooter."Footer Text"));
        DocumentFooter.Modify(false);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Document Footer", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Footer CZL", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure SyncOnBeforeDeleteDocumentFooterCZL(var Rec: Record "Document Footer CZL")
    var
        DocumentFooter: Record "Document Footer";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Document Footer CZL", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Document Footer", 0);
        if DocumentFooter.Get(Rec."Language Code") then
            DocumentFooter.Delete(false);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Document Footer", 0);
    end;
}
