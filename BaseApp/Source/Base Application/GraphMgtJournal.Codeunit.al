codeunit 5482 "Graph Mgt - Journal"
{

    trigger OnRun()
    begin
    end;

    procedure GetDefaultJournalLinesTemplateName(): Text[10]
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        GenJnlTemplate.Reset();
        GenJnlTemplate.SetRange("Page ID", PAGE::"General Journal");
        GenJnlTemplate.SetRange(Recurring, false);
        GenJnlTemplate.SetRange(Type, 0);
        GenJnlTemplate.FindFirst;
        exit(GenJnlTemplate.Name);
    end;

    procedure GetDefaultCustomerPaymentsTemplateName(): Text[10]
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        GenJnlTemplate.Reset();
        GenJnlTemplate.SetRange("Page ID", PAGE::"Cash Receipt Journal");
        GenJnlTemplate.SetRange(Recurring, false);
        GenJnlTemplate.SetRange(Type, 3);
        GenJnlTemplate.FindFirst;
        exit(GenJnlTemplate.Name);
    end;

    procedure UpdateIntegrationRecords(OnlyItemsWithoutId: Boolean)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        GenJournalBatchRecordRef: RecordRef;
    begin
        GenJournalBatchRecordRef.Open(DATABASE::"Gen. Journal Batch");
        GraphMgtGeneralTools.UpdateIntegrationRecords(GenJournalBatchRecordRef, GenJournalBatch.FieldNo(Id), OnlyItemsWithoutId);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5465, 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIntegrationRecords(false);
    end;
}

