#pragma warning disable AL0432
codeunit 31186 "Sync.Dep.Fld-VatStmtCommLn CZL"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit will be removed after removing feature from Base Application.';
    ObsoleteTag = '17.0';

    [EventSubscriber(ObjectType::Table, Database::"VAT Statement Comment Line", 'OnBeforeRenameEvent', '', false, false)]
    local procedure SyncOnBeforeRenameVATStatementCommentLine(var Rec: Record "VAT Statement Comment Line"; var xRec: Record "VAT Statement Comment Line")
    var
        VATStatementCommentLineCZL: Record "VAT Statement Comment Line CZL";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"VAT Statement Comment Line", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"VAT Statement Comment Line CZL", 0);
        if VATStatementCommentLineCZL.Get(xRec."VAT Statement Template Name", xRec."VAT Statement Name", xRec."Line No.") then
            VATStatementCommentLineCZL.Rename(Rec."VAT Statement Template Name", Rec."VAT Statement Name", Rec."Line No.");
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"VAT Statement Comment Line CZL", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Statement Comment Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure SyncOnAfterInsertVATStatementCommentLine(var Rec: Record "VAT Statement Comment Line")
    begin
        SyncVATStatementCommentLine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Statement Comment Line", 'OnAfterModifyEvent', '', false, false)]
    local procedure SyncOnAfterModifyVATStatementCommentLine(var Rec: Record "VAT Statement Comment Line")
    begin
        SyncVATStatementCommentLine(Rec);
    end;

    local procedure SyncVATStatementCommentLine(var Rec: Record "VAT Statement Comment Line")
    var
        VATStatementCommentLineCZL: Record "VAT Statement Comment Line CZL";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"VAT Statement Comment Line", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"VAT Statement Comment Line CZL", 0);
        if not VATStatementCommentLineCZL.Get(Rec."VAT Statement Template Name", Rec."VAT Statement Name", Rec."Line No.") then begin
            VATStatementCommentLineCZL.Init();
            VATStatementCommentLineCZL."VAT Statement Template Name" := Rec."VAT Statement Template Name";
            VATStatementCommentLineCZL."VAT Statement Name" := Rec."VAT Statement Name";
            VATStatementCommentLineCZL."Line No." := Rec."Line No.";
            VATStatementCommentLineCZL.Insert(false);
        end;
        VATStatementCommentLineCZL.Date := Rec.Date;
        VATStatementCommentLineCZL.Comment := Rec.Comment;
        VATStatementCommentLineCZL.Modify(false);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"VAT Statement Comment Line CZL", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Statement Comment Line", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure SyncOnBeforeDeleteVATStatementCommentLine(var Rec: Record "VAT Statement Comment Line")
    var
        VATStatementCommentLineCZL: Record "VAT Statement Comment Line CZL";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"VAT Statement Comment Line", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"VAT Statement Comment Line CZL", 0);
        if VATStatementCommentLineCZL.Get(Rec."VAT Statement Template Name", Rec."VAT Statement Name", Rec."Line No.") then
            VATStatementCommentLineCZL.Delete(false);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"VAT Statement Comment Line CZL", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Statement Comment Line CZL", 'OnBeforeRenameEvent', '', false, false)]
    local procedure SyncOnBeforeRenameVATStatementCommentLineCZL(var Rec: Record "VAT Statement Comment Line CZL"; var xRec: Record "VAT Statement Comment Line CZL")
    var
        VATStatementCommentLine: Record "VAT Statement Comment Line";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"VAT Statement Comment Line CZL", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"VAT Statement Comment Line", 0);
        if VATStatementCommentLine.Get(xRec."VAT Statement Template Name", xRec."VAT Statement Name", xRec."Line No.") then
            VATStatementCommentLine.Rename(Rec."VAT Statement Template Name", Rec."VAT Statement Name", Rec."Line No.");
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"VAT Statement Comment Line", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Statement Comment Line CZL", 'OnAfterInsertEvent', '', false, false)]
    local procedure SyncOnAfterInsertVATStatementCommentLineCZL(var Rec: Record "VAT Statement Comment Line CZL")
    begin
        SyncVATStatementCommentLineCZL(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Statement Comment Line CZL", 'OnAfterModifyEvent', '', false, false)]
    local procedure SyncOnAfterModifyVATStatementCommentLineCZL(var Rec: Record "VAT Statement Comment Line CZL")
    begin
        SyncVATStatementCommentLineCZL(Rec);
    end;

    local procedure SyncVATStatementCommentLineCZL(var Rec: Record "VAT Statement Comment Line CZL")
    var
        VATStatementCommentLine: Record "VAT Statement Comment Line";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if NavApp.IsInstalling() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"VAT Statement Comment Line CZL", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"VAT Statement Comment Line", 0);
        if not VATStatementCommentLine.Get(Rec."VAT Statement Template Name", Rec."VAT Statement Name", Rec."Line No.") then begin
            VATStatementCommentLine.Init();
            VATStatementCommentLine."VAT Statement Template Name" := Rec."VAT Statement Template Name";
            VATStatementCommentLine."VAT Statement Name" := Rec."VAT Statement Name";
            VATStatementCommentLine."Line No." := Rec."Line No.";
            VATStatementCommentLine.Insert(false);
        end;
        VATStatementCommentLine.Date := Rec.Date;
        VATStatementCommentLine.Comment := Rec.Comment;
        VATStatementCommentLine.Modify(false);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"VAT Statement Comment Line", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Statement Comment Line CZL", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure SyncOnBeforeDeleteVATStatementCommentLineCZL(var Rec: Record "VAT Statement Comment Line CZL")
    var
        VATStatementCommentLine: Record "VAT Statement Comment Line";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"VAT Statement Comment Line CZL", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"VAT Statement Comment Line", 0);
        if VATStatementCommentLine.Get(Rec."VAT Statement Template Name", Rec."VAT Statement Name", Rec."Line No.") then
            VATStatementCommentLine.Delete(false);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"VAT Statement Comment Line", 0);
    end;
}
