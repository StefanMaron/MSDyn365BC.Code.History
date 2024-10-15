#if not CLEAN23
#pragma warning disable AL0432
codeunit 10526 "Sync.Dep.Fld-Payment Practices"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit exists for syncing data from local GB fields into fields moved to W1. It will no longer be needed after those fields are obsoleted.';
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

        SyncDepFldUtilities.SyncFields(Rec."Exclude from Pmt. Pract. Rep.", Rec."Exclude from Pmt. Practices", PreviousRecord."Exclude from Pmt. Pract. Rep.", PreviousRecord."Exclude from Pmt. Practices");
    end;

    [EventSubscriber(ObjectType::Table, Database::Vendor, 'OnAfterValidateEvent', 'Exclude from Pmt. Pract. Rep.', false, false)]
    local procedure SyncOnAfterValidateExcludefromPmtPractRep(var Rec: Record Vendor)
    begin
        Rec."Exclude from Pmt. Practices" := Rec."Exclude from Pmt. Pract. Rep.";
    end;

    [EventSubscriber(ObjectType::Table, Database::Vendor, 'OnAfterValidateEvent', 'Exclude from Pmt. Practices', false, false)]
    local procedure SyncOnAfterValidateExcludefromPmtPractices(var Rec: Record Vendor)
    begin
        Rec."Exclude from Pmt. Pract. Rep." := Rec."Exclude from Pmt. Practices";
    end;
    #endregion

    #region VendorLedgerEntry
    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", 'OnBeforeInsertEvent', '', false, false)]
    local procedure SyncOnBeforeInsertVendorLedgerEntry(var Rec: Record "Vendor Ledger Entry")
    begin
        SyncDeprecatedFields(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", 'OnBeforeModifyEvent', '', false, false)]
    local procedure SyncOnBeforeModifyVendorLedgerEntry(var Rec: Record "Vendor Ledger Entry")
    begin
        SyncDeprecatedFields(Rec);
    end;

    local procedure SyncDeprecatedFields(var Rec: Record "Vendor Ledger Entry")
    var
        PreviousRecord: Record "Vendor Ledger Entry";
        SyncDepFldUtilities: Codeunit "Sync.Dep.Fld-Utilities";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if IsFieldSynchronizationDisabled() then
            exit;

        if Rec.IsTemporary() then
            exit;

        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Vendor Ledger Entry") then
            exit;

        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Vendor Ledger Entry");

        SyncDepFldUtilities.SyncFields(Rec."Invoice Receipt Date", Rec."Invoice Received Date", PreviousRecord."Invoice Receipt Date", PreviousRecord."Invoice Received Date");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", 'OnAfterValidateEvent', 'Invoice Receipt Date', false, false)]
    local procedure SyncOnAfterValidateInvoiceReceiptDate_VLE(var Rec: Record "Vendor Ledger Entry")
    begin
        Rec."Invoice Received Date" := Rec."Invoice Receipt Date";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", 'OnAfterValidateEvent', 'Invoice Received Date', false, false)]
    local procedure SyncOnAfterValidateInvoiceRcptDate_VLE(var Rec: Record "Vendor Ledger Entry")
    begin
        Rec."Invoice Receipt Date" := Rec."Invoice Received Date";
    end;
    #endregion

    #region PurchaseHeader
    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnBeforeInsertEvent', '', false, false)]
    local procedure SyncOnBeforeInsertPurchaseHeader(var Rec: Record "Purchase Header")
    begin
        SyncDeprecatedFields(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnBeforeModifyEvent', '', false, false)]
    local procedure SyncOnBeforeModifyPurchaseHeader(var Rec: Record "Purchase Header")
    begin
        SyncDeprecatedFields(Rec);
    end;

    local procedure SyncDeprecatedFields(var Rec: Record "Purchase Header")
    var
        PreviousRecord: Record "Purchase Header";
        SyncDepFldUtilities: Codeunit "Sync.Dep.Fld-Utilities";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if IsFieldSynchronizationDisabled() then
            exit;

        if Rec.IsTemporary() then
            exit;

        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Purchase Header") then
            exit;

        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Purchase Header");

        SyncDepFldUtilities.SyncFields(Rec."Invoice Receipt Date", Rec."Invoice Received Date", PreviousRecord."Invoice Receipt Date", PreviousRecord."Invoice Received Date");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterValidateEvent', 'Invoice Receipt Date', false, false)]
    local procedure SyncOnAfterValidateInvoiceReceiptDate_PurchaseHeader(var Rec: Record "Purchase Header")
    begin
        Rec."Invoice Received Date" := Rec."Invoice Receipt Date";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterValidateEvent', 'Invoice Received Date', false, false)]
    local procedure SyncOnAfterValidateInvoiceRcptDate_PurchaseHeader(var Rec: Record "Purchase Header")
    begin
        Rec."Invoice Receipt Date" := Rec."Invoice Received Date";
    end;
    #endregion

    #region PostedGenJournalLine
    [EventSubscriber(ObjectType::Table, Database::"Posted Gen. Journal Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure SyncOnBeforeInsertPostedGenJournalLine(var Rec: Record "Posted Gen. Journal Line")
    begin
        SyncDeprecatedFields(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Posted Gen. Journal Line", 'OnBeforeModifyEvent', '', false, false)]
    local procedure SyncOnBeforeModifyPostedGenJournalLine(var Rec: Record "Posted Gen. Journal Line")
    begin
        SyncDeprecatedFields(Rec);
    end;

    local procedure SyncDeprecatedFields(var Rec: Record "Posted Gen. Journal Line")
    var
        PreviousRecord: Record "Posted Gen. Journal Line";
        SyncDepFldUtilities: Codeunit "Sync.Dep.Fld-Utilities";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if IsFieldSynchronizationDisabled() then
            exit;

        if Rec.IsTemporary() then
            exit;

        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Posted Gen. Journal Line") then
            exit;

        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Posted Gen. Journal Line");

        SyncDepFldUtilities.SyncFields(Rec."Invoice Receipt Date", Rec."Invoice Received Date", PreviousRecord."Invoice Receipt Date", PreviousRecord."Invoice Received Date");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Posted Gen. Journal Line", 'OnAfterValidateEvent', 'Invoice Receipt Date', false, false)]
    local procedure SyncOnAfterValidateInvoiceReceiptDate_PostedGJL(var Rec: Record "Posted Gen. Journal Line")
    begin
        Rec."Invoice Received Date" := Rec."Invoice Receipt Date";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Posted Gen. Journal Line", 'OnAfterValidateEvent', 'Invoice Received Date', false, false)]
    local procedure SyncOnAfterValidateInvoiceRcptDate_PostedGJL(var Rec: Record "Posted Gen. Journal Line")
    begin
        Rec."Invoice Receipt Date" := Rec."Invoice Received Date";
    end;
    #endregion

    #region PostedGenJournalLine
    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure SyncOnBeforeInsertGenJournalLine(var Rec: Record "Gen. Journal Line")
    begin
        SyncDeprecatedFields(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnBeforeModifyEvent', '', false, false)]
    local procedure SyncOnBeforeModifyGenJournalLine(var Rec: Record "Gen. Journal Line")
    begin
        SyncDeprecatedFields(Rec);
    end;

    local procedure SyncDeprecatedFields(var Rec: Record "Gen. Journal Line")
    var
        PreviousRecord: Record "Gen. Journal Line";
        SyncDepFldUtilities: Codeunit "Sync.Dep.Fld-Utilities";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if IsFieldSynchronizationDisabled() then
            exit;

        if Rec.IsTemporary() then
            exit;

        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Gen. Journal Line") then
            exit;

        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Gen. Journal Line");

        SyncDepFldUtilities.SyncFields(Rec."Invoice Receipt Date", Rec."Invoice Received Date", PreviousRecord."Invoice Receipt Date", PreviousRecord."Invoice Received Date");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterValidateEvent', 'Invoice Receipt Date', false, false)]
    local procedure SyncOnAfterValidateInvoiceReceiptDate_GJL(var Rec: Record "Gen. Journal Line")
    begin
        Rec."Invoice Received Date" := Rec."Invoice Receipt Date";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterValidateEvent', 'Invoice Received Date', false, false)]
    local procedure SyncOnAfterValidateInvoiceRcptDate_GJL(var Rec: Record "Gen. Journal Line")
    begin
        Rec."Invoice Receipt Date" := Rec."Invoice Received Date";
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
