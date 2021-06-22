codeunit 5498 "Graph Mgt - Unit Of Measure"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit will be removed. The functionality was replaced with systemId';
    ObsoleteTag = '18.0';

    trigger OnRun()
    begin
    end;

    [Obsolete('Integration Records will be replaced by SystemID and SystemModifiedAt ', '17.0')]
    procedure UpdateIntegrationRecords(OnlyUofMWithoutId: Boolean)
    var
        DummyUnitOfMeasure: Record "Unit of Measure";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        UnitOfMeasureRecordRef: RecordRef;
    begin
        UnitOfMeasureRecordRef.Open(DATABASE::"Unit of Measure");
        GraphMgtGeneralTools.UpdateIntegrationRecords(UnitOfMeasureRecordRef, DummyUnitOfMeasure.FieldNo(Id), OnlyUofMWithoutId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIntegrationRecords(false);
    end;
}

