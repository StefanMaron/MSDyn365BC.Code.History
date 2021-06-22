codeunit 5492 "Graph Mgt - Item Category"
{

    trigger OnRun()
    begin
    end;

    procedure UpdateIntegrationRecords(OnlyItemsWithoutId: Boolean)
    var
        DummyItemCategory: Record "Item Category";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        ItemCategoryRecordRef: RecordRef;
    begin
        ItemCategoryRecordRef.Open(DATABASE::"Item Category");
        GraphMgtGeneralTools.UpdateIntegrationRecords(ItemCategoryRecordRef, DummyItemCategory.FieldNo(Id), OnlyItemsWithoutId);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5465, 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIntegrationRecords(false);
    end;
}

