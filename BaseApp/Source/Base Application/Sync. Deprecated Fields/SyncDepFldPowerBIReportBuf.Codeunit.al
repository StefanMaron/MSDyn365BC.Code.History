codeunit 9314 "Sync.Dep.Fld-PowerBIReportBuf"
{
    // This codeunit is used to synchronization between obsolete pending fields 
    // and their alternative fields in the Base Application or other extensions

    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit will be removed once the fields are marked as removed.';
    Access = Internal;
    ObsoleteTag = '16.0';

    [EventSubscriber(ObjectType::Table, Database::"Power BI Report Buffer", 'OnAfterValidateEvent', 'EmbedUrl', false, false)]
    local procedure SyncOnAfterValidateEmbedUrlInPBIReportBuffer(var Rec: Record "Power BI Report Buffer"; var xRec: Record "Power BI Report Buffer"; CurrFieldNo: Integer)
    var
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if IsFieldSynchronizationSkipped(SyncLoopingHelper, Rec.FieldNo(EmbedUrl)) then
            exit;

        SkipFieldSynchronization(SyncLoopingHelper, Rec.FieldNo(ReportEmbedUrl));
        Rec.Validate(ReportEmbedUrl, Rec.EmbedUrl);
        RestoreFieldSynchronization(SyncLoopingHelper, Rec.FieldNo(ReportEmbedUrl));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Power BI Report Buffer", 'OnAfterValidateEvent', 'ReportEmbedUrl', false, false)]
    local procedure SyncOnAfterValidateReportEmbedUrlInPBIReportBuffer(var Rec: Record "Power BI Report Buffer"; var xRec: Record "Power BI Report Buffer"; CurrFieldNo: Integer)
    var
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if IsFieldSynchronizationSkipped(SyncLoopingHelper, Rec.FieldNo(ReportEmbedUrl)) then
            exit;

        SkipFieldSynchronization(SyncLoopingHelper, Rec.FieldNo(EmbedUrl));
        if StrLen(Rec.ReportEmbedUrl) <= MaxStrLen(Rec.EmbedUrl) then
            Rec.Validate(EmbedUrl, Rec.ReportEmbedUrl)
        else
            Rec.Validate(EmbedUrl, '');
        RestoreFieldSynchronization(SyncLoopingHelper, Rec.FieldNo(EmbedUrl));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Power BI Report Buffer", 'OnBeforeInsertEvent', '', false, false)]
    local procedure SyncOnBeforeInsertPBIReportBuffer(RunTrigger: Boolean; var Rec: Record "Power BI Report Buffer")
    var
        SyncDepFldPowerBIUrlUtils: Codeunit "Sync.Dep.Fld-PowerBIUrlUtils";
    begin
        SyncDepFldPowerBIUrlUtils.SyncUrlFields(Rec.EmbedUrl, Rec.ReportEmbedUrl);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Power BI Report Buffer", 'OnBeforeModifyEvent', '', false, false)]
    local procedure SyncOnBeforeModifyPBIReportBuffer(RunTrigger: Boolean; var Rec: Record "Power BI Report Buffer"; var xRec: Record "Power BI Report Buffer")
    var
        PreviousPowerBiReportBuffer: Record "Power BI Report Buffer";
        SyncDepFldPowerBIUrlUtils: codeunit "Sync.Dep.Fld-PowerBIUrlUtils";
        SyncDepFldUtilities: codeunit "Sync.Dep.Fld-Utilities";
        PreviousRecordRef: RecordRef;
    begin
        if SyncDepFldUtilities.GetPreviousRecord(Rec, PreviousRecordRef) then begin
            PreviousRecordRef.SetTable(PreviousPowerBiReportBuffer);
            SyncDepFldPowerBIUrlUtils.SyncUrlFields(Rec.EmbedUrl, Rec.ReportEmbedUrl, PreviousPowerBiReportBuffer.EmbedUrl, PreviousPowerBiReportBuffer.ReportEmbedUrl);
        end else
            // Follow the same flow as OnBeforeInsert, the previous record does not exist
            SyncDepFldPowerBIUrlUtils.SyncUrlFields(Rec.EmbedUrl, Rec.ReportEmbedUrl);
    end;

    local procedure SkipFieldSynchronization(var SyncLoopingHelper: Codeunit "Sync. Looping Helper"; FieldNo: Integer)
    begin
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Power BI Report Buffer", FieldNo);
    end;

    local procedure RestoreFieldSynchronization(var SyncLoopingHelper: Codeunit "Sync. Looping Helper"; FieldNo: Integer)
    begin
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Power BI Report Buffer", FieldNo);
    end;

    local procedure IsFieldSynchronizationSkipped(var SyncLoopingHelper: Codeunit "Sync. Looping Helper"; FieldNo: Integer): Boolean
    begin
        exit(SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Power BI Report Buffer", FieldNo));
    end;
}