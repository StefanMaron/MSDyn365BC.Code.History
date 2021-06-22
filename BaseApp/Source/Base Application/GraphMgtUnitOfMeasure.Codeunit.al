codeunit 5498 "Graph Mgt - Unit Of Measure"
{

    trigger OnRun()
    begin
    end;

    procedure UpdateIntegrationRecords(OnlyUofMWithoutId: Boolean)
    var
        DummyUnitOfMeasure: Record "Unit of Measure";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        UnitOfMeasureRecordRef: RecordRef;
    begin
        UnitOfMeasureRecordRef.Open(DATABASE::"Unit of Measure");
        GraphMgtGeneralTools.UpdateIntegrationRecords(UnitOfMeasureRecordRef, DummyUnitOfMeasure.FieldNo(Id), OnlyUofMWithoutId);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5465, 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIntegrationRecords(false);
    end;
}

