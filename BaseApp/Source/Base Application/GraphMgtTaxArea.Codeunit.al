codeunit 5504 "Graph Mgt - Tax Area"
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
        DummyTaxArea: Record "Tax Area";
        DummyVATBusinessPostingGroup: Record "VAT Business Posting Group";
        DummyVATClause: Record "VAT Clause";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        TaxAreaRecordRef: RecordRef;
        VATBusinessPostingGroupRecordRef: RecordRef;
        VATClauseRecordRef: RecordRef;
    begin
        TaxAreaRecordRef.Open(DATABASE::"Tax Area");
        GraphMgtGeneralTools.UpdateIntegrationRecords(TaxAreaRecordRef, DummyTaxArea.FieldNo(Id), OnlyItemsWithoutId);

        VATBusinessPostingGroupRecordRef.Open(DATABASE::"VAT Business Posting Group");
        GraphMgtGeneralTools.UpdateIntegrationRecords(
          VATBusinessPostingGroupRecordRef, DummyVATBusinessPostingGroup.FieldNo(Id), OnlyItemsWithoutId);

        VATClauseRecordRef.Open(DATABASE::"VAT Clause");
        GraphMgtGeneralTools.UpdateIntegrationRecords(VATClauseRecordRef, DummyVATClause.FieldNo(Id), OnlyItemsWithoutId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIntegrationRecords(false);
    end;
}

