codeunit 5492 "Graph Mgt - Item Category"
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
        DummyItemCategory: Record "Item Category";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        ItemCategoryRecordRef: RecordRef;
    begin
        ItemCategoryRecordRef.Open(DATABASE::"Item Category");
        GraphMgtGeneralTools.UpdateIntegrationRecords(ItemCategoryRecordRef, DummyItemCategory.FieldNo(Id), OnlyItemsWithoutId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIntegrationRecords(false);
    end;
}

