#if not CLEAN24
#pragma warning disable AL0432
codeunit 12145 "Sync. Dep. Fld. - NoSeriesLine"
{
    Access = Internal;
    ObsoleteReason = 'The codeunit is used to syncronize obsolete fields. Once they are removed this is no longer needed.';
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';

    #region CRUD
    [EventSubscriber(ObjectType::Table, Database::"No. Series Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure SyncOnAfterInsertNoSeriesLine(var Rec: Record "No. Series Line"; RunTrigger: Boolean)
    var
        NoSeriesLineSales: Record "No. Series Line Sales";
        NoSeriesLinePurchase: Record "No. Series Line Purchase";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
        SyncDepFldUtilities: Codeunit "Sync.Dep.Fld-Utilities";
    begin
        if Rec.IsTemporary() then
            exit;

        if SyncDepFldUtilities.IsFieldSynchronizationDisabled() then
            exit;

        Rec.CalcFields("No. Series Type");
        case Rec."No. Series Type" of
            Enum::"No. Series Type"::Normal:
                exit;
            Enum::"No. Series Type"::Sales:
                SyncToDeprecatedTable(Rec, NoSeriesLineSales, RunTrigger, true, SyncLoopingHelper);
            Enum::"No. Series Type"::Purchase:
                SyncToDeprecatedTable(Rec, NoSeriesLinePurchase, RunTrigger, true, SyncLoopingHelper);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"No. Series Line", 'OnAfterModifyEvent', '', false, false)]
    local procedure SyncOnAfterModifyNoSeriesLine(var Rec: Record "No. Series Line"; var xRec: Record "No. Series Line"; RunTrigger: Boolean)
    var
        NoSeriesLineSales: Record "No. Series Line Sales";
        NoSeriesLinePurchase: Record "No. Series Line Purchase";
        SyncDepFldUtilities: Codeunit "Sync.Dep.Fld-Utilities";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
        PreviousRecordRef: RecordRef;
    begin
        if Rec.IsTemporary() then
            exit;

        if SyncDepFldUtilities.IsFieldSynchronizationDisabled() then
            exit;

        if SyncDepFldUtilities.GetPreviousRecord(Rec, PreviousRecordRef) then
            PreviousRecordRef.SetTable(xRec);

        Rec.CalcFields("No. Series Type");
        case Rec."No. Series Type" of
            Enum::"No. Series Type"::Normal:
                exit;
            Enum::"No. Series Type"::Sales:
                SyncToDeprecatedTable(Rec, NoSeriesLineSales, RunTrigger, false, SyncLoopingHelper);
            Enum::"No. Series Type"::Purchase:
                SyncToDeprecatedTable(Rec, NoSeriesLinePurchase, RunTrigger, false, SyncLoopingHelper);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"No. Series Line", 'OnAfterRenameEvent', '', false, false)]
    local procedure SyncOnAfterRenameNoSeriesLine(var Rec: Record "No. Series Line"; var xRec: Record "No. Series Line")
    var
        NoSeriesLineSales: Record "No. Series Line Sales";
        NoSeriesLinePurchase: Record "No. Series Line Purchase";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
        SyncDepFldUtilities: Codeunit "Sync.Dep.Fld-Utilities";
    begin
        if Rec.IsTemporary() then
            exit;

        if SyncDepFldUtilities.IsFieldSynchronizationDisabled() then
            exit;

        Rec.CalcFields("No. Series Type");
        case Rec."No. Series Type" of
            Enum::"No. Series Type"::Normal:
                exit;
            Enum::"No. Series Type"::Sales:
                RenameDeprecatedTable(Rec, xRec, NoSeriesLineSales, SyncLoopingHelper);
            Enum::"No. Series Type"::Purchase:
                RenameDeprecatedTable(Rec, xRec, NoSeriesLinePurchase, SyncLoopingHelper);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"No. Series Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure SyncOnAfterDeleteNoSeriesLine(var Rec: Record "No. Series Line"; RunTrigger: Boolean)
    var
        NoSeriesLineSales: Record "No. Series Line Sales";
        NoSeriesLinePurchase: Record "No. Series Line Purchase";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
        SyncDepFldUtilities: Codeunit "Sync.Dep.Fld-Utilities";
    begin
        if Rec.IsTemporary() then
            exit;

        if SyncDepFldUtilities.IsFieldSynchronizationDisabled() then
            exit;

        Rec.CalcFields("No. Series Type");
        case Rec."No. Series Type" of
            Enum::"No. Series Type"::Normal:
                exit;
            Enum::"No. Series Type"::Sales:
                DeleteDeprecatedTable(Rec, NoSeriesLineSales, RunTrigger, SyncLoopingHelper);
            Enum::"No. Series Type"::Purchase:
                DeleteDeprecatedTable(Rec, NoSeriesLinePurchase, RunTrigger, SyncLoopingHelper);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"No. Series Line Sales", 'OnAfterInsertEvent', '', false, false)]
    local procedure SyncOnAfterInsertNoSeriesLineSales(var Rec: Record "No. Series Line Sales"; RunTrigger: Boolean)
    var
        NoSeriesLine: Record "No. Series Line";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
        SyncDepFldUtilities: Codeunit "Sync.Dep.Fld-Utilities";
    begin
        if Rec.IsTemporary() then
            exit;

        if SyncDepFldUtilities.IsFieldSynchronizationDisabled() then
            exit;

        SyncFromDeprecatedTable(Rec, NoSeriesLine, RunTrigger, true, SyncLoopingHelper);
    end;

    [EventSubscriber(ObjectType::Table, Database::"No. Series Line Sales", 'OnAfterModifyEvent', '', false, false)]
    local procedure SyncOnAfterModifyNoSeriesLineSales(var Rec: Record "No. Series Line Sales"; RunTrigger: Boolean)
    var
        NoSeriesLine: Record "No. Series Line";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
        SyncDepFldUtilities: Codeunit "Sync.Dep.Fld-Utilities";
    begin
        if Rec.IsTemporary() then
            exit;

        if SyncDepFldUtilities.IsFieldSynchronizationDisabled() then
            exit;

        NoSeriesLine.ChangeCompany(Rec.CurrentCompany());
        if NoSeriesLine.Get(Rec."Series Code", Rec."Line No.") then
            SyncFromDeprecatedTable(Rec, NoSeriesLine, RunTrigger, false, SyncLoopingHelper);
    end;

    [EventSubscriber(ObjectType::Table, Database::"No. Series Line Sales", 'OnAfterRenameEvent', '', false, false)]
    local procedure SyncOnAfterRenameNoSeriesLineSales(var Rec: Record "No. Series Line Sales"; var xRec: Record "No. Series Line Sales")
    var
        NoSeriesLine: Record "No. Series Line";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
        SyncDepFldUtilities: Codeunit "Sync.Dep.Fld-Utilities";
    begin
        if Rec.IsTemporary() then
            exit;

        if SyncDepFldUtilities.IsFieldSynchronizationDisabled() then
            exit;

        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"No. Series Line") then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"No. Series Line");

        NoSeriesLine.ChangeCompany(xRec.CurrentCompany());
        if NoSeriesLine.Get(xRec."Series Code", xRec."Line No.") then
            NoSeriesLine.Rename(Rec."Series Code", Rec."Line No.");

        SyncLoopingHelper.RestoreFieldSynchronization(Database::"No. Series Line");
    end;

    [EventSubscriber(ObjectType::Table, Database::"No. Series Line Sales", 'OnAfterDeleteEvent', '', false, false)]
    local procedure SyncOnAfterDeleteNoSeriesLineSales(var Rec: Record "No. Series Line Sales"; RunTrigger: Boolean)
    var
        NoSeriesLine: Record "No. Series Line";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
        SyncDepFldUtilities: Codeunit "Sync.Dep.Fld-Utilities";
    begin
        if Rec.IsTemporary() then
            exit;

        if SyncDepFldUtilities.IsFieldSynchronizationDisabled() then
            exit;

        NoSeriesLine.ChangeCompany(Rec.CurrentCompany());
        if not NoSeriesLine.Get(Rec."Series Code", Rec."Line No.") then
            exit;

        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"No. Series Line") then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"No. Series Line");

        NoSeriesLine.Delete(RunTrigger);

        SyncLoopingHelper.RestoreFieldSynchronization(Database::"No. Series Line");
    end;

    [EventSubscriber(ObjectType::Table, Database::"No. Series Line Purchase", 'OnAfterInsertEvent', '', false, false)]
    local procedure SyncOnAfterInsertNoSeriesLinePurchase(var Rec: Record "No. Series Line Purchase"; RunTrigger: Boolean)
    var
        NoSeriesLine: Record "No. Series Line";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
        SyncDepFldUtilities: Codeunit "Sync.Dep.Fld-Utilities";
    begin
        if Rec.IsTemporary() then
            exit;

        if SyncDepFldUtilities.IsFieldSynchronizationDisabled() then
            exit;

        SyncFromDeprecatedTable(Rec, NoSeriesLine, RunTrigger, true, SyncLoopingHelper);
    end;

    [EventSubscriber(ObjectType::Table, Database::"No. Series Line Purchase", 'OnAfterModifyEvent', '', false, false)]
    local procedure SyncOnAfterModifyNoSeriesLinePurchase(var Rec: Record "No. Series Line Purchase"; RunTrigger: Boolean)
    var
        NoSeriesLine: Record "No. Series Line";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
        SyncDepFldUtilities: Codeunit "Sync.Dep.Fld-Utilities";
    begin
        if Rec.IsTemporary() then
            exit;

        if SyncDepFldUtilities.IsFieldSynchronizationDisabled() then
            exit;

        NoSeriesLine.ChangeCompany(Rec.CurrentCompany());
        if NoSeriesLine.Get(Rec."Series Code", Rec."Line No.") then
            SyncFromDeprecatedTable(Rec, NoSeriesLine, RunTrigger, false, SyncLoopingHelper);
    end;

    [EventSubscriber(ObjectType::Table, Database::"No. Series Line Purchase", 'OnAfterRenameEvent', '', false, false)]
    local procedure SyncOnAfterRenameNoSeriesLinePurchase(var Rec: Record "No. Series Line Purchase"; var xRec: Record "No. Series Line Purchase")
    var
        NoSeriesLine: Record "No. Series Line";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
        SyncDepFldUtilities: Codeunit "Sync.Dep.Fld-Utilities";
    begin
        if Rec.IsTemporary() then
            exit;

        if SyncDepFldUtilities.IsFieldSynchronizationDisabled() then
            exit;

        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"No. Series Line") then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"No. Series Line");

        NoSeriesLine.ChangeCompany(xRec.CurrentCompany());
        if NoSeriesLine.Get(xRec."Series Code", xRec."Line No.") then
            NoSeriesLine.Rename(Rec."Series Code", Rec."Line No.");

        SyncLoopingHelper.RestoreFieldSynchronization(Database::"No. Series Line");
    end;

    [EventSubscriber(ObjectType::Table, Database::"No. Series Line Purchase", 'OnAfterDeleteEvent', '', false, false)]
    local procedure SyncOnAfterDeleteNoSeriesLinePurchase(var Rec: Record "No. Series Line Purchase"; RunTrigger: Boolean)
    var
        NoSeriesLine: Record "No. Series Line";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
        SyncDepFldUtilities: Codeunit "Sync.Dep.Fld-Utilities";
    begin
        if Rec.IsTemporary() then
            exit;

        if SyncDepFldUtilities.IsFieldSynchronizationDisabled() then
            exit;

        NoSeriesLine.ChangeCompany(Rec.CurrentCompany());
        if not NoSeriesLine.Get(Rec."Series Code", Rec."Line No.") then
            exit;

        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"No. Series Line") then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"No. Series Line");

        NoSeriesLine.Delete(RunTrigger);

        SyncLoopingHelper.RestoreFieldSynchronization(Database::"No. Series Line");
    end;
    #endregion

    #region sync
    local procedure SyncToDeprecatedTable(NoSeriesLine: Record "No. Series Line"; NoSeriesLineSales: Record "No. Series Line Sales"; RunTrigger: Boolean; InsertRecord: Boolean; var SyncLoopingHelper: Codeunit "Sync. Looping Helper")
    begin
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"No. Series Line Sales") then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"No. Series Line") then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"No. Series Line Sales");

        NoSeriesLineSales.ChangeCompany(NoSeriesLine.CurrentCompany());
        TransferFieldsToNoSeriesLineSales(NoSeriesLine, NoSeriesLineSales);
        if InsertRecord then
            NoSeriesLineSales.Insert(RunTrigger)
        else
            if not NoSeriesLineSales.Modify(RunTrigger) then
                NoSeriesLineSales.Insert(RunTrigger);

        SyncLoopingHelper.RestoreFieldSynchronization(Database::"No. Series Line Sales");
    end;

    local procedure SyncToDeprecatedTable(NoSeriesLine: Record "No. Series Line"; NoSeriesLinePurchase: Record "No. Series Line Purchase"; RunTrigger: Boolean; InsertRecord: Boolean; var SyncLoopingHelper: Codeunit "Sync. Looping Helper")
    begin
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"No. Series Line Purchase") then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"No. Series Line") then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"No. Series Line Purchase");

        NoSeriesLinePurchase.ChangeCompany(NoSeriesLine.CurrentCompany());
        TransferFieldsToNoSeriesLinePurchase(NoSeriesLine, NoSeriesLinePurchase);
        if InsertRecord then
            NoSeriesLinePurchase.Insert(RunTrigger)
        else
            if not NoSeriesLinePurchase.Modify(RunTrigger) then
                NoSeriesLinePurchase.Insert(RunTrigger);

        SyncLoopingHelper.RestoreFieldSynchronization(Database::"No. Series Line Purchase");
    end;

    local procedure RenameDeprecatedTable(NoSeriesLine: Record "No. Series Line"; xRecNoSeriesLine: Record "No. Series Line"; NoSeriesLineSales: Record "No. Series Line Sales"; var SyncLoopingHelper: Codeunit "Sync. Looping Helper")
    begin
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"No. Series Line Sales") then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"No. Series Line") then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"No. Series Line Sales");

        NoSeriesLineSales.ChangeCompany(xRecNoSeriesLine.CurrentCompany());
        if NoSeriesLineSales.Get(xRecNoSeriesLine."Series Code", xRecNoSeriesLine."Line No.") then
            NoSeriesLineSales.Rename(NoSeriesLine."Series Code", NoSeriesLine."Line No.");

        SyncLoopingHelper.RestoreFieldSynchronization(Database::"No. Series Line Sales");
    end;

    local procedure RenameDeprecatedTable(NoSeriesLine: Record "No. Series Line"; xRecNoSeriesLine: Record "No. Series Line"; NoSeriesLinePurchase: Record "No. Series Line Purchase"; var SyncLoopingHelper: Codeunit "Sync. Looping Helper")
    begin
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"No. Series Line Purchase") then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"No. Series Line") then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"No. Series Line Purchase");

        NoSeriesLinePurchase.ChangeCompany(xRecNoSeriesLine.CurrentCompany());
        if NoSeriesLinePurchase.Get(xRecNoSeriesLine."Series Code", xRecNoSeriesLine."Line No.") then
            NoSeriesLinePurchase.Rename(NoSeriesLine."Series Code", NoSeriesLine."Line No.");

        SyncLoopingHelper.RestoreFieldSynchronization(Database::"No. Series Line Purchase");
    end;

    local procedure DeleteDeprecatedTable(NoSeriesLine: Record "No. Series Line"; NoSeriesLineSales: Record "No. Series Line Sales"; RunTrigger: Boolean; var SyncLoopingHelper: Codeunit "Sync. Looping Helper")
    begin
        NoSeriesLineSales.ChangeCompany(NoSeriesLine.CurrentCompany());
        if not NoSeriesLineSales.Get(NoSeriesLine."Series Code", NoSeriesLine."Line No.") then
            exit;

        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"No. Series Line Sales") then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"No. Series Line") then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"No. Series Line Sales");

        NoSeriesLineSales.Delete(RunTrigger);

        SyncLoopingHelper.RestoreFieldSynchronization(Database::"No. Series Line Sales");
    end;

    local procedure DeleteDeprecatedTable(NoSeriesLine: Record "No. Series Line"; NoSeriesLinePurchase: Record "No. Series Line Purchase"; RunTrigger: Boolean; var SyncLoopingHelper: Codeunit "Sync. Looping Helper")
    begin
        NoSeriesLinePurchase.ChangeCompany(NoSeriesLine.CurrentCompany());
        if not NoSeriesLinePurchase.Get(NoSeriesLine."Series Code", NoSeriesLine."Line No.") then
            exit;

        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"No. Series Line Purchase") then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"No. Series Line") then
            exit;

        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"No. Series Line Purchase");

        NoSeriesLinePurchase.Delete(RunTrigger);

        SyncLoopingHelper.RestoreFieldSynchronization(Database::"No. Series Line Purchase");
    end;

    local procedure SyncFromDeprecatedTable(NoSeriesLineSales: Record "No. Series Line Sales"; NoSeriesLine: Record "No. Series Line"; RunTrigger: Boolean; InsertRecord: Boolean; var SyncLoopingHelper: Codeunit "Sync. Looping Helper")
    var
        UpgradeBaseApp: Codeunit "Upgrade - BaseApp";
    begin
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"No. Series Line") then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"No. Series Line Sales") then
            exit;

        NoSeriesLine.ChangeCompany(NoSeriesLineSales.CurrentCompany());
        UpgradeBaseApp.TransferFieldsFromNoSeriesLineSales(NoSeriesLineSales, NoSeriesLine);
        NoSeriesLine.CalcFields("No. Series Type");
        if NoSeriesLine."No. Series Type" = NoSeriesLine."No. Series Type"::Normal then
            exit;

        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"No. Series Line");
        if InsertRecord then
            NoSeriesLine.Insert(RunTrigger)
        else
            NoSeriesLine.Modify(RunTrigger);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"No. Series Line");
    end;

    local procedure SyncFromDeprecatedTable(NoSeriesLinePurchase: Record "No. Series Line Purchase"; NoSeriesLine: Record "No. Series Line"; RunTrigger: Boolean; InsertRecord: Boolean; var SyncLoopingHelper: Codeunit "Sync. Looping Helper")
    var
        UpgradeBaseApp: Codeunit "Upgrade - BaseApp";
    begin
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"No. Series Line") then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"No. Series Line Purchase") then
            exit;

        NoSeriesLine.ChangeCompany(NoSeriesLinePurchase.CurrentCompany());
        UpgradeBaseApp.TransferFieldsFromNoSeriesLinePurchase(NoSeriesLinePurchase, NoSeriesLine);
        NoSeriesLine.CalcFields("No. Series Type");
        if NoSeriesLine."No. Series Type" = NoSeriesLine."No. Series Type"::Normal then
            exit;

        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"No. Series Line");
        if InsertRecord then
            NoSeriesLine.Insert(RunTrigger)
        else
            NoSeriesLine.Modify(RunTrigger);
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"No. Series Line");
    end;

    local procedure TransferFieldsToNoSeriesLineSales(FromNoSeriesLine: Record "No. Series Line"; var ToNoSeriesLineSales: Record "No. Series Line Sales")
    begin
        ToNoSeriesLineSales."Series Code" := FromNoSeriesLine."Series Code";
        ToNoSeriesLineSales."Line No." := FromNoSeriesLine."Line No.";
        ToNoSeriesLineSales."Starting Date" := FromNoSeriesLine."Starting Date";
        ToNoSeriesLineSales."Starting No." := FromNoSeriesLine."Starting No.";
        ToNoSeriesLineSales."Ending No." := FromNoSeriesLine."Ending No.";
        ToNoSeriesLineSales."Warning No." := FromNoSeriesLine."Warning No.";
        ToNoSeriesLineSales."Increment-by No." := FromNoSeriesLine."Increment-by No.";
        ToNoSeriesLineSales."Last No. Used" := FromNoSeriesLine."Last No. Used";
        ToNoSeriesLineSales.Open := FromNoSeriesLine.Open;
        ToNoSeriesLineSales."Last Date Used" := FromNoSeriesLine."Last Date Used";

        OnAfterTransferFieldsToNoSeriesLineSales(FromNoSeriesLine, ToNoSeriesLineSales);
    end;

    local procedure TransferFieldsToNoSeriesLinePurchase(FromNoSeriesLine: Record "No. Series Line"; var ToNoSeriesLinePurchase: Record "No. Series Line Purchase")
    begin
        ToNoSeriesLinePurchase."Series Code" := FromNoSeriesLine."Series Code";
        ToNoSeriesLinePurchase."Line No." := FromNoSeriesLine."Line No.";
        ToNoSeriesLinePurchase."Starting Date" := FromNoSeriesLine."Starting Date";
        ToNoSeriesLinePurchase."Starting No." := FromNoSeriesLine."Starting No.";
        ToNoSeriesLinePurchase."Ending No." := FromNoSeriesLine."Ending No.";
        ToNoSeriesLinePurchase."Warning No." := FromNoSeriesLine."Warning No.";
        ToNoSeriesLinePurchase."Increment-by No." := FromNoSeriesLine."Increment-by No.";
        ToNoSeriesLinePurchase."Last No. Used" := FromNoSeriesLine."Last No. Used";
        ToNoSeriesLinePurchase.Open := FromNoSeriesLine.Open;
        ToNoSeriesLinePurchase."Last Date Used" := FromNoSeriesLine."Last Date Used";

        OnAfterTransferFieldsToNoSeriesLinePurchase(FromNoSeriesLine, ToNoSeriesLinePurchase);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFieldsToNoSeriesLineSales(FromNoSeriesLine: Record "No. Series Line"; ToNoSeriesLineSales: Record "No. Series Line Sales")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFieldsToNoSeriesLinePurchase(FromNoSeriesLine: Record "No. Series Line"; ToNoSeriesLinePurchase: Record "No. Series Line Purchase")
    begin
    end;
    #endregion
}
#pragma warning restore AL0432
#endif