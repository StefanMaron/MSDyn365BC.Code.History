codeunit 5502 "Graph Mgt - Unlinked Att."
{

    trigger OnRun()
    begin
    end;

    procedure UpdateIntegrationRecords(OnlyItemsWithoutId: Boolean)
    var
        DummyUnlinkedAttachment: Record "Unlinked Attachment";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        RecRef: RecordRef;
    begin
        RecRef.Open(DATABASE::"Unlinked Attachment");
        GraphMgtGeneralTools.UpdateIntegrationRecords(RecRef, DummyUnlinkedAttachment.FieldNo(Id), OnlyItemsWithoutId);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5465, 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIntegrationRecords(false);
    end;
}

