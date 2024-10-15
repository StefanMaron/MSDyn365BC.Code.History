codeunit 5502 "Graph Mgt - Unlinked Att."
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit will be removed. The functionality was replaced with systemId';
    ObsoleteTag = '18.0';

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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
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
        ID: Guid;
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

                ID := IDFieldRef.Value();
                if not IntegrationRecord.Get(ID) then begin
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

