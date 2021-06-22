codeunit 5487 "Graph Mgt - Dimension"
{

    trigger OnRun()
    begin
    end;

    procedure UpdateIntegrationRecords(OnlyItemsWithoutId: Boolean)
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        DimensionRecordRef: RecordRef;
        DimensionValueRecordRef: RecordRef;
    begin
        DimensionRecordRef.Open(DATABASE::Dimension);
        GraphMgtGeneralTools.UpdateIntegrationRecords(DimensionRecordRef, Dimension.FieldNo(Id), OnlyItemsWithoutId);

        DimensionValueRecordRef.Open(DATABASE::"Dimension Value");
        GraphMgtGeneralTools.UpdateIntegrationRecords(DimensionValueRecordRef, DimensionValue.FieldNo(Id), OnlyItemsWithoutId);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5465, 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIntegrationRecords(false);
    end;
}

