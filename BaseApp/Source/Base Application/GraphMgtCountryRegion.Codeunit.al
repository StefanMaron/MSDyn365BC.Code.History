codeunit 5494 "Graph Mgt - Country/Region"
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
        DummyCountryRegion: Record "Country/Region";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        CountryRegionRecordRef: RecordRef;
    begin
        CountryRegionRecordRef.Open(DATABASE::"Country/Region");
        GraphMgtGeneralTools.UpdateIntegrationRecords(CountryRegionRecordRef, DummyCountryRegion.FieldNo(Id), OnlyItemsWithoutId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIntegrationRecords(false);
    end;
}

