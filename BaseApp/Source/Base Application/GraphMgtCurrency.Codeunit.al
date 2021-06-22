codeunit 5485 "Graph Mgt - Currency"
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
        DummyCurrency: Record Currency;
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        CurrencyRecordRef: RecordRef;
    begin
        CurrencyRecordRef.Open(DATABASE::Currency);
        GraphMgtGeneralTools.UpdateIntegrationRecords(CurrencyRecordRef, DummyCurrency.FieldNo(Id), OnlyItemsWithoutId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIntegrationRecords(false);
    end;
}

