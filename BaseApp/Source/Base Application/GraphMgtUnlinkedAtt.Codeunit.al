codeunit 5502 "Graph Mgt - Unlinked Att."
{

    trigger OnRun()
    begin
    end;

    procedure UpdateIntegrationRecords(OnlyItemsWithoutId: Boolean)
    var
        DummyUnlinkedAttachment: Record "Unlinked Attachment";
        RecRef: RecordRef;
    begin
        RecRef.Open(DATABASE::"Unlinked Attachment");
        UpdateIntegrationRecords(RecRef, DummyUnlinkedAttachment.FieldNo(Id), false);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5465, 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIntegrationRecords(false);
    end;

    procedure UpdateIntegrationRecords(var SourceRecordRef: RecordRef; FieldNumber: Integer; OnlyRecordsWithoutID: Boolean)
    var
        IntegrationRecord: Record "Integration Record";
        UpdatedIntegrationRecord: Record "Integration Record";
        IntegrationManagement: Codeunit "Integration Management";
        FilterFieldRef: FieldRef;
        IDFieldRef: FieldRef;
        NullGuid: Guid;
        SystemId: Guid;
        IDField: Guid;
    begin
        if not IntegrationManagement.GetIntegrationIsEnabledOnTheSystem() then
            exit;

        if OnlyRecordsWithoutID then begin
            FilterFieldRef := SourceRecordRef.Field(FieldNumber);
            FilterFieldRef.SetRange(NullGuid);
        end;

        if SourceRecordRef.FindSet() then
            repeat
                IDFieldRef := SourceRecordRef.Field(FieldNumber);
                Evaluate(SystemId, Format(SourceRecordRef.Field(SourceRecordRef.SystemIdNo).Value));
                Evaluate(IDField, Format(IDFieldRef.Value));
                if SystemId <> IDField then
                    SourceRecordRef.Rename(SystemId);

                if not IntegrationRecord.Get(IDFieldRef.Value) then begin
                    IntegrationManagement.InsertUpdateIntegrationRecord(SourceRecordRef, CurrentDateTime);
                    if IsNullGuid(Format(IDFieldRef.Value)) then begin
                        UpdatedIntegrationRecord.SetRange("Record ID", SourceRecordRef.RecordId);
                        UpdatedIntegrationRecord.FindFirst();
                        IDFieldRef.Value := IntegrationManagement.GetIdWithoutBrackets(UpdatedIntegrationRecord."Integration ID");
                    end;

                    SourceRecordRef.Modify(false);
                end;
            until SourceRecordRef.Next() = 0;
    end;
}

