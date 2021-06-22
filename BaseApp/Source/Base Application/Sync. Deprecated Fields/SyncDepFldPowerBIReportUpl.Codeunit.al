codeunit 9316 "Sync.Dep.Fld-PowerBIReportUpl"
{
    // This codeunit is used to synchronization between obsolete pending fields 
    // and their alternative fields in the Base Application or other extensions

    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit will be removed once the fields are marked as removed.';
    Access = Internal;
    ObsoleteTag = '16.0';

    [EventSubscriber(ObjectType::Table, Database::"Power BI Report Uploads", 'OnAfterValidateEvent', 'Embed Url', false, false)]
    local procedure SyncOnAfterValidateEmbedUrlInPBIReportBuffer(var Rec: Record "Power BI Report Uploads"; var xRec: Record "Power BI Report Uploads"; CurrFieldNo: Integer)
    var
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if IsFieldSynchronizationSkipped(SyncLoopingHelper, Rec.FieldNo("Embed Url")) then
            exit;

        SkipFieldSynchronization(SyncLoopingHelper, Rec.FieldNo("Report Embed Url"));
        Rec.Validate("Report Embed Url", Rec."Embed Url");
        RestoreFieldSynchronization(SyncLoopingHelper, Rec.FieldNo("Report Embed Url"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Power BI Report Uploads", 'OnAfterValidateEvent', 'Report Embed Url', false, false)]
    local procedure SyncOnAfterValidateReportEmbedUrlInPBIReportBuffer(var Rec: Record "Power BI Report Uploads"; var xRec: Record "Power BI Report Uploads"; CurrFieldNo: Integer)
    var
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if IsFieldSynchronizationSkipped(SyncLoopingHelper, Rec.FieldNo("Report Embed Url")) then
            exit;

        SkipFieldSynchronization(SyncLoopingHelper, Rec.FieldNo("Embed Url"));
        if StrLen(Rec."Report Embed Url") <= MaxStrLen(Rec."Embed Url") then
            Rec.Validate("Embed Url", Rec."Report Embed Url")
        else
            Rec.Validate("Embed Url", '');
        RestoreFieldSynchronization(SyncLoopingHelper, Rec.FieldNo("Embed Url"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Power BI Report Uploads", 'OnBeforeInsertEvent', '', false, false)]
    local procedure SyncOnBeforeInsertPBIReportBuffer(RunTrigger: Boolean; var Rec: Record "Power BI Report Uploads")
    var
        SyncDepFldPowerBIUrlUtils: Codeunit "Sync.Dep.Fld-PowerBIUrlUtils";
    begin
        SyncDepFldPowerBIUrlUtils.SyncUrlFields(Rec."Embed Url", Rec."Report Embed Url");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Power BI Report Uploads", 'OnBeforeModifyEvent', '', false, false)]
    local procedure SyncOnBeforeModifyPBIReportBuffer(RunTrigger: Boolean; var Rec: Record "Power BI Report Uploads"; var xRec: Record "Power BI Report Uploads")
    var
        PreviousPowerBiReportUploads: Record "Power BI Report Uploads";
        SyncDepFldPowerBIUrlUtils: codeunit "Sync.Dep.Fld-PowerBIUrlUtils";
        SyncDepFldUtilities: codeunit "Sync.Dep.Fld-Utilities";
        PreviousRecordRef: RecordRef;
    begin
        if SyncDepFldUtilities.GetPreviousRecord(Rec, PreviousRecordRef) then begin
            PreviousRecordRef.SetTable(PreviousPowerBiReportUploads);
            SyncDepFldPowerBIUrlUtils.SyncUrlFields(Rec."Embed Url", Rec."Report Embed Url", PreviousPowerBiReportUploads."Embed Url", PreviousPowerBiReportUploads."Report Embed Url");
        end else
            // Follow the same flow as OnBeforeInsert, the previous record does not exist
            SyncDepFldPowerBIUrlUtils.SyncUrlFields(Rec."Embed Url", Rec."Report Embed Url");
    end;

    local procedure SkipFieldSynchronization(var SyncLoopingHelper: Codeunit "Sync. Looping Helper"; FieldNo: Integer)
    begin
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Power BI Report Uploads", FieldNo);
    end;

    local procedure RestoreFieldSynchronization(var SyncLoopingHelper: Codeunit "Sync. Looping Helper"; FieldNo: Integer)
    begin
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Power BI Report Uploads", FieldNo);
    end;

    local procedure IsFieldSynchronizationSkipped(var SyncLoopingHelper: Codeunit "Sync. Looping Helper"; FieldNo: Integer): Boolean
    begin
        exit(SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Power BI Report Uploads", FieldNo));
    end;
}