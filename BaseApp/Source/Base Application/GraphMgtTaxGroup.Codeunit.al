codeunit 5481 "Graph Mgt - Tax Group"
{

    trigger OnRun()
    begin
    end;

    procedure UpdateIntegrationRecords(OnlyItemsWithoutId: Boolean)
    var
        DummyTaxGroup: Record "Tax Group";
        DummyVATProductPostingGroup: Record "VAT Product Posting Group";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        TaxGroupRecordRef: RecordRef;
        VATProductPostingGroupRecordRef: RecordRef;
    begin
        TaxGroupRecordRef.Open(DATABASE::"Tax Group");
        GraphMgtGeneralTools.UpdateIntegrationRecords(TaxGroupRecordRef, DummyTaxGroup.FieldNo(Id), OnlyItemsWithoutId);

        VATProductPostingGroupRecordRef.Open(DATABASE::"VAT Product Posting Group");
        GraphMgtGeneralTools.UpdateIntegrationRecords(
          VATProductPostingGroupRecordRef, DummyVATProductPostingGroup.FieldNo(Id), OnlyItemsWithoutId);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5465, 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIntegrationRecords(false);
    end;
}

