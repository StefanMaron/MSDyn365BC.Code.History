codeunit 5499 "Graph Mgt - Purchase Header"
{

    trigger OnRun()
    begin
    end;

    procedure UpdateIntegrationRecords(OnlyItemsWithoutId: Boolean)
    var
        DummyPurchaseHeader: Record "Purchase Header";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        PurchaseHeaderRecordRef: RecordRef;
    begin
        PurchaseHeaderRecordRef.Open(DATABASE::"Purchase Header");
        GraphMgtGeneralTools.UpdateIntegrationRecords(PurchaseHeaderRecordRef, DummyPurchaseHeader.FieldNo(Id), OnlyItemsWithoutId);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5465, 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIntegrationRecords(false);
    end;
}

