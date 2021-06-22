codeunit 5491 "Graph Mgt - Shipment Method"
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
        ShipmentMethod: Record "Shipment Method";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        ShipmentMethodRecordRef: RecordRef;
    begin
        ShipmentMethodRecordRef.Open(DATABASE::"Shipment Method");
        GraphMgtGeneralTools.UpdateIntegrationRecords(ShipmentMethodRecordRef, ShipmentMethod.FieldNo(Id), OnlyItemsWithoutId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIntegrationRecords(false);
    end;
}

