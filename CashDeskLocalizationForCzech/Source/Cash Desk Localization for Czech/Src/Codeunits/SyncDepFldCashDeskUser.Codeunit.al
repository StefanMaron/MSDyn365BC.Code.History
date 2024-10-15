#pragma warning disable AL0432
codeunit 31126 "Sync.Dep.Fld-CashDeskUser CZP"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit will be removed after removing feature from Base Application.';
    ObsoleteTag = '17.0';

    [EventSubscriber(ObjectType::Table, Database::"Cash Desk User", 'OnBeforeRenameEvent', '', false, false)]
    local procedure SyncOnBeforeRenameCashDeskUser(var Rec: Record "Cash Desk User"; var xRec: Record "Cash Desk User")
    var
        CashDeskUserCZP: Record "Cash Desk User CZP";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Cash Desk User", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Cash Desk User CZP", 0);
        if CashDeskUserCZP.Get(xRec."Cash Desk No.", xRec."User ID") then
            CashDeskUserCZP.Rename(Rec."Cash Desk No.", Rec."User ID");
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Cash Desk User CZP", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cash Desk User", 'OnAfterInsertEvent', '', false, false)]
    local procedure SyncOnAfterInsertCashDeskUser(var Rec: Record "Cash Desk User")
    begin
        SyncCashDeskUser(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cash Desk User", 'OnAfterModifyEvent', '', false, false)]
    local procedure SyncOnAfterModifyCashDeskUser(var Rec: Record "Cash Desk User")
    begin
        SyncCashDeskUser(Rec);
    end;

    local procedure SyncCashDeskUser(var Rec: Record "Cash Desk User")
    var
        CashDeskUserCZP: Record "Cash Desk User CZP";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Cash Desk User", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Cash Desk User CZP", 0);
        if not CashDeskUserCZP.Get(Rec."Cash Desk No.", Rec."User ID") then begin
            CashDeskUserCZP.Init();
            CashDeskUserCZP."Cash Desk No." := Rec."Cash Desk No.";
            CashDeskUserCZP."User ID" := Rec."User ID";
            CashDeskUserCZP.Insert(false);
        end;
        CashDeskUserCZP.Create := Rec.Create;
        CashDeskUserCZP.Issue := Rec.Issue;
        CashDeskUserCZP.Post := Rec.Post;
        CashDeskUserCZP."User Full Name" := Rec.GetUserName(Rec."User ID");
        CashDeskUserCZP.Modify(false);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Cash Desk User CZP", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cash Desk User", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure SyncOnBeforeDeleteCashDeskUser(var Rec: Record "Cash Desk User")
    var
        CashDeskUserCZP: Record "Cash Desk User CZP";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Cash Desk User", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Cash Desk User CZP", 0);
        if CashDeskUserCZP.Get(Rec."Cash Desk No.", Rec."User ID") then
            CashDeskUserCZP.Delete(false);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Cash Desk User CZP", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cash Desk User CZP", 'OnBeforeRenameEvent', '', false, false)]
    local procedure SyncOnBeforeRenameCashDeskUserCZP(var Rec: Record "Cash Desk User CZP"; var xRec: Record "Cash Desk User CZP")
    var
        CashDeskUser: Record "Cash Desk User";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Cash Desk User CZP", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Cash Desk User", 0);
        if CashDeskUser.Get(xRec."Cash Desk No.", xRec."User ID") then
            CashDeskUser.Rename(Rec."Cash Desk No.", Rec."User ID");
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Cash Desk User", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cash Desk User CZP", 'OnAfterInsertEvent', '', false, false)]
    local procedure SyncOnAfterInsertCashDeskUserCZP(var Rec: Record "Cash Desk User CZP")
    begin
        SyncCashDeskUserCZP(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cash Desk User CZP", 'OnAfterModifyEvent', '', false, false)]
    local procedure SyncOnAfterModifyCashDeskUserCZP(var Rec: Record "Cash Desk User CZP")
    begin
        SyncCashDeskUserCZP(Rec);
    end;

    local procedure SyncCashDeskUserCZP(var Rec: Record "Cash Desk User CZP")
    var
        CashDeskUser: Record "Cash Desk User";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if NavApp.IsInstalling() then
            exit;
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Cash Desk User CZP", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Cash Desk User", 0);
        if not CashDeskUser.Get(Rec."Cash Desk No.", Rec."User ID") then begin
            CashDeskUser.Init();
            CashDeskUser."Cash Desk No." := Rec."Cash Desk No.";
            CashDeskUser."User ID" := Rec."User ID";
            CashDeskUser.Insert(false);
        end;
        CashDeskUser.Create := Rec.Create;
        CashDeskUser.Issue := Rec.Issue;
        CashDeskUser.Post := Rec.Post;
        CashDeskUser.Modify(false);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Cash Desk User", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cash Desk User CZP", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure SyncOnBeforeDeleteCashDeskUserCZP(var Rec: Record "Cash Desk User CZP")
    var
        CashDeskUser: Record "Cash Desk User";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Cash Desk User CZP", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Cash Desk User", 0);
        if CashDeskUser.Get(Rec."Cash Desk No.", Rec."User ID") then
            CashDeskUser.Delete(false);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Cash Desk User", 0);
    end;
}
