codeunit 5480 "Graph Mgt - Account"
{

    trigger OnRun()
    begin
    end;

    local procedure EnableAccountODataWebService()
    begin
        UpdateIntegrationRecords(false);
    end;

    procedure UpdateIntegrationRecords(OnlyItemsWithoutId: Boolean)
    var
        GLAccount: Record "G/L Account";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        GLAccountRecordRef: RecordRef;
    begin
        GLAccountRecordRef.Open(DATABASE::"G/L Account");
        GraphMgtGeneralTools.UpdateIntegrationRecords(GLAccountRecordRef, GLAccount.FieldNo(Id), OnlyItemsWithoutId);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5465, 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        EnableAccountODataWebService;
    end;
}

