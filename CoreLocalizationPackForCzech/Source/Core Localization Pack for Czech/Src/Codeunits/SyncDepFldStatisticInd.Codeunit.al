#pragma warning disable AL0432
codeunit 31196 "Sync.Dep.Fld-StatisticInd CZL"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit will be removed after removing feature from Base Application.';
    ObsoleteTag = '17.0';

    [EventSubscriber(ObjectType::Table, Database::"Statistic Indication", 'OnBeforeRenameEvent', '', false, false)]
    local procedure SyncOnBeforeRenameStatisticIndication(var Rec: Record "Statistic Indication"; var xRec: Record "Statistic Indication")
    var
        StatisticIndicationCZL: Record "Statistic Indication CZL";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Statistic Indication", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Statistic Indication CZL", 0);
        if StatisticIndicationCZL.Get(xRec."Tariff No.", xRec.Code) then
            StatisticIndicationCZL.Rename(Rec."Tariff No.", Rec.Code);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Statistic Indication CZL", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Statistic Indication", 'OnAfterInsertEvent', '', false, false)]
    local procedure SyncOnAfterInsertStatisticIndication(var Rec: Record "Statistic Indication")
    begin
        SyncStatisticIndication(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Statistic Indication", 'OnAfterModifyEvent', '', false, false)]
    local procedure SyncOnAfterModifyStatisticIndication(var Rec: Record "Statistic Indication")
    begin
        SyncStatisticIndication(Rec);
    end;

    local procedure SyncStatisticIndication(var Rec: Record "Statistic Indication")
    var
        StatisticIndicationCZL: Record "Statistic Indication CZL";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Statistic Indication", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Statistic Indication CZL", 0);
        if not StatisticIndicationCZL.Get(Rec."Tariff No.", Rec.Code) then begin
            StatisticIndicationCZL.Init();
            StatisticIndicationCZL."Tariff No." := Rec."Tariff No.";
            StatisticIndicationCZL.Code := Rec.Code;
            StatisticIndicationCZL.Insert(false);
        end;
        StatisticIndicationCZL.Description := Rec.Description;
        StatisticIndicationCZL.Modify(false);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Statistic Indication CZL", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Statistic Indication", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure SyncOnBeforeDeleteStatisticIndication(var Rec: Record "Statistic Indication")
    var
        StatisticIndicationCZL: Record "Statistic Indication CZL";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Statistic Indication", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Statistic Indication CZL", 0);
        if StatisticIndicationCZL.Get(Rec."Tariff No.", Rec.Code) then
            StatisticIndicationCZL.Delete(false);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Statistic Indication CZL", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Statistic Indication CZL", 'OnBeforeRenameEvent', '', false, false)]
    local procedure SyncOnBeforeRenameStatisticIndicationCZL(var Rec: Record "Statistic Indication CZL"; var xRec: Record "Statistic Indication CZL")
    var
        StatisticIndication: Record "Statistic Indication";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Statistic Indication CZL", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Statistic Indication", 0);
        if StatisticIndication.Get(xRec."Tariff No.", xRec.Code) then
            StatisticIndication.Rename(Rec."Tariff No.", Rec.Code);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Statistic Indication", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Statistic Indication CZL", 'OnAfterInsertEvent', '', false, false)]
    local procedure SyncOnAfterInsertStatisticIndicationCZL(var Rec: Record "Statistic Indication CZL")
    begin
        SyncStatisticIndicationCZL(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Statistic Indication CZL", 'OnAfterModifyEvent', '', false, false)]
    local procedure SyncOnAfterModifyStatisticIndicationCZL(var Rec: Record "Statistic Indication CZL")
    begin
        SyncStatisticIndicationCZL(Rec);
    end;

    local procedure SyncStatisticIndicationCZL(var Rec: Record "Statistic Indication CZL")
    var
        StatisticIndication: Record "Statistic Indication";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if NavApp.IsInstalling() then
            exit;
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Statistic Indication CZL", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Statistic Indication", 0);
        if not StatisticIndication.Get(Rec."Tariff No.", Rec.Code) then begin
            StatisticIndication.Init();
            StatisticIndication."Tariff No." := Rec."Tariff No.";
            StatisticIndication.Code := Rec.Code;
            StatisticIndication.Insert(false);
        end;
        StatisticIndication.Description := CopyStr(Rec.Description, 1, MaxStrLen(StatisticIndication.Description));
        StatisticIndication.Modify(false);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Statistic Indication", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Statistic Indication CZL", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure SyncOnBeforeDeleteStatisticIndicationCZL(var Rec: Record "Statistic Indication CZL")
    var
        StatisticIndication: Record "Statistic Indication";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if Rec.IsTemporary() then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Statistic Indication CZL", 0) then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Statistic Indication", 0);
        if StatisticIndication.Get(Rec."Tariff No.", Rec.Code) then
            StatisticIndication.Delete(false);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Statistic Indication", 0);
    end;
}
