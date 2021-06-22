codeunit 5485 "Graph Mgt - Currency"
{

    trigger OnRun()
    begin
    end;

    [Obsolete('Integration Records will be replaced by SystemID and SystemLastDateTimeModified', '17.0')]
    procedure UpdateIntegrationRecords(OnlyItemsWithoutId: Boolean)
    var
        DummyCurrency: Record Currency;
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        CurrencyRecordRef: RecordRef;
    begin
        CurrencyRecordRef.Open(DATABASE::Currency);
        GraphMgtGeneralTools.UpdateIntegrationRecords(CurrencyRecordRef, DummyCurrency.FieldNo(Id), OnlyItemsWithoutId);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5465, 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIntegrationRecords(false);
    end;
}

