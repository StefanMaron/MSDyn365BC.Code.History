#if not CLEAN23
#pragma warning disable AL0432
codeunit 10879 "Sync.Dep.Fld-Payment Practices"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit exists for syncing data from local FR fields into fields moved to W1. It will no longer be needed after those fields are obsoleted.';
    ObsoleteTag = '23.0';

    #region Vendor
    [EventSubscriber(ObjectType::Table, Database::Vendor, 'OnBeforeInsertEvent', '', false, false)]
    local procedure SyncOnBeforeInsertVendor(var Rec: Record Vendor)
    begin
        SyncDeprecatedFields(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::Vendor, 'OnBeforeModifyEvent', '', false, false)]
    local procedure SyncOnBeforeModifyVendor(var Rec: Record Vendor)
    begin
        SyncDeprecatedFields(Rec);
    end;

    local procedure SyncDeprecatedFields(var Rec: Record Vendor)
    var
        PreviousRecord: Record Vendor;
        SyncDepFldUtilities: Codeunit "Sync.Dep.Fld-Utilities";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if IsFieldSynchronizationDisabled() then
            exit;

        if Rec.IsTemporary() then
            exit;

        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::Vendor) then
            exit;

        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::Vendor);

        SyncDepFldUtilities.SyncFields(Rec."Exclude from Payment Reporting", Rec."Exclude from Pmt. Practices", PreviousRecord."Exclude from Payment Reporting", PreviousRecord."Exclude from Pmt. Practices");
    end;

    [EventSubscriber(ObjectType::Table, Database::Vendor, 'OnAfterValidateEvent', 'Exclude from Payment Reporting', false, false)]
    local procedure SyncOnAfterValidateExcludefromPmtPractRep(var Rec: Record Vendor)
    begin
        Rec."Exclude from Pmt. Practices" := Rec."Exclude from Payment Reporting";
    end;

    [EventSubscriber(ObjectType::Table, Database::Vendor, 'OnAfterValidateEvent', 'Exclude from Pmt. Practices', false, false)]
    local procedure SyncOnAfterValidateExcludefromPmtPractices(var Rec: Record Vendor)
    begin
        Rec."Exclude from Payment Reporting" := Rec."Exclude from Pmt. Practices";
    end;
    #endregion

    #region Customer
    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnBeforeInsertEvent', '', false, false)]
    local procedure SyncOnBeforeInsertCustomer(var Rec: Record Customer)
    begin
        SyncDeprecatedFields(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnBeforeModifyEvent', '', false, false)]
    local procedure SyncOnBeforeModifyCustomer(var Rec: Record Customer)
    begin
        SyncDeprecatedFields(Rec);
    end;

    local procedure SyncDeprecatedFields(var Rec: Record Customer)
    var
        PreviousRecord: Record Customer;
        SyncDepFldUtilities: Codeunit "Sync.Dep.Fld-Utilities";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if IsFieldSynchronizationDisabled() then
            exit;

        if Rec.IsTemporary() then
            exit;

        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::Customer) then
            exit;

        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::Customer);

        SyncDepFldUtilities.SyncFields(Rec."Exclude from Payment Reporting", Rec."Exclude from Pmt. Practices", PreviousRecord."Exclude from Payment Reporting", PreviousRecord."Exclude from Pmt. Practices");
    end;

    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnAfterValidateEvent', 'Exclude from Payment Reporting', false, false)]
    local procedure SyncOnAfterValidateExcludefromPmtPractRep_Cust(var Rec: Record Customer)
    begin
        Rec."Exclude from Pmt. Practices" := Rec."Exclude from Payment Reporting";
    end;

    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnAfterValidateEvent', 'Exclude from Pmt. Practices', false, false)]
    local procedure SyncOnAfterValidateExcludefromPmtPractices_Cust(var Rec: Record Customer)
    begin
        Rec."Exclude from Payment Reporting" := Rec."Exclude from Pmt. Practices";
    end;
    #endregion

    local procedure IsFieldSynchronizationDisabled(): Boolean
    var
        SyncDepFldUtilities: Codeunit "Sync.Dep.Fld-Utilities";
    begin
        exit(SyncDepFldUtilities.IsFieldSynchronizationDisabled());
    end;
}
#pragma warning restore
#endif
