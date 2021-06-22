codeunit 5481 "Graph Mgt - Tax Group"
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIntegrationRecords(false);
    end;
}

