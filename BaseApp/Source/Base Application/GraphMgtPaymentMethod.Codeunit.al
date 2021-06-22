codeunit 5486 "Graph Mgt - Payment Method"
{

    trigger OnRun()
    begin
    end;

    [Obsolete('Integration Records will be replaced by SystemID and SystemLastDateTimeModified', '17.0')]
    procedure UpdateIntegrationRecords(OnlyItemsWithoutId: Boolean)
    var
        DummyPaymentMethod: Record "Payment Method";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        PaymentMethodRecordRef: RecordRef;
    begin
        PaymentMethodRecordRef.Open(DATABASE::"Payment Method");
        GraphMgtGeneralTools.UpdateIntegrationRecords(PaymentMethodRecordRef, DummyPaymentMethod.FieldNo(Id), OnlyItemsWithoutId);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5465, 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIntegrationRecords(false);
    end;
}

