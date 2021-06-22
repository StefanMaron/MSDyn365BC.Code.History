codeunit 5504 "Graph Mgt - Tax Area"
{

    trigger OnRun()
    begin
    end;

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

    [EventSubscriber(ObjectType::Codeunit, 5465, 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIntegrationRecords(false);
    end;
}

