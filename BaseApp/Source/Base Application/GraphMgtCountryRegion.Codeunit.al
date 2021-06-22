codeunit 5494 "Graph Mgt - Country/Region"
{

    trigger OnRun()
    begin
    end;

    procedure UpdateIntegrationRecords(OnlyItemsWithoutId: Boolean)
    var
        DummyCountryRegion: Record "Country/Region";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        CountryRegionRecordRef: RecordRef;
    begin
        CountryRegionRecordRef.Open(DATABASE::"Country/Region");
        GraphMgtGeneralTools.UpdateIntegrationRecords(CountryRegionRecordRef, DummyCountryRegion.FieldNo(Id), OnlyItemsWithoutId);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5465, 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIntegrationRecords(false);
    end;
}

