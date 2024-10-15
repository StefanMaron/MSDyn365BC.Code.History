codeunit 8898 "Map Email Source"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::Email, 'OnShowSource', '', false, false)]
    local procedure OnGetPageForSourceRecord(SourceTableId: Integer; SourceSystemId: Guid; var IsHandled: Boolean)
    var
        PageManagement: Codeunit "Page Management";
        SourceRecordRef: RecordRef;
    begin
        SourceRecordRef.Open(SourceTableId);
        if not SourceRecordRef.GetBySystemId(SourceSystemId) then
            exit;

        if PageManagement.PageRun(SourceRecordRef) then
            IsHandled := true;
    end;
}