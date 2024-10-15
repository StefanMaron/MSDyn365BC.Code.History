codeunit 5490 "Graph Mgt - Payment Terms"
{

    trigger OnRun()
    begin
    end;

    [Obsolete('Integration Records will be replaced by SystemID and SystemLastDateTimeModified', '17.0')]
    procedure UpdateIntegrationRecords(OnlyItemsWithoutId: Boolean)
    var
        PaymentTerms: Record "Payment Terms";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        PaymentTermsRecordRef: RecordRef;
    begin
        PaymentTermsRecordRef.Open(DATABASE::"Payment Terms");
        GraphMgtGeneralTools.UpdateIntegrationRecords(PaymentTermsRecordRef, PaymentTerms.FieldNo(Id), OnlyItemsWithoutId);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5465, 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIntegrationRecords(false);
    end;
}

