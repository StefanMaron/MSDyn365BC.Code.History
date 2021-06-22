codeunit 5487 "Graph Mgt - Dimension"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit will be removed. The functionality was replaced with systemId';
    ObsoleteTag = '18.0';

    trigger OnRun()
    begin
    end;

    [Obsolete('Integration Records will be replaced by SystemID and SystemModifiedAt ', '17.0')]
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIntegrationRecords(false);
    end;
}

