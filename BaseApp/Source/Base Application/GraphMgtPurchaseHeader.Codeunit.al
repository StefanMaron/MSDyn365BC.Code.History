codeunit 5499 "Graph Mgt - Purchase Header"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit will be removed. The functionality was replaced with systemId';
    ObsoleteTag = '18.0';

    trigger OnRun()
    begin
    end;

    [Obsolete('Integration Records will be replaced by SystemID and SystemModifiedAt ', '18.0')]
    procedure UpdateIntegrationRecords(OnlyItemsWithoutId: Boolean)
    var
        DummyPurchaseHeader: Record "Purchase Header";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        PurchaseHeaderRecordRef: RecordRef;
    begin
        PurchaseHeaderRecordRef.Open(DATABASE::"Purchase Header");
        GraphMgtGeneralTools.UpdateIntegrationRecords(PurchaseHeaderRecordRef, DummyPurchaseHeader.FieldNo(Id), OnlyItemsWithoutId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIntegrationRecords(false);
    end;
}

