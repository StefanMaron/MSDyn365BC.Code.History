codeunit 5480 "Graph Mgt - Account"
{

    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit will be removed. The functionality was replaced with systemId';
    ObsoleteTag = '18.0';

    trigger OnRun()
    begin
    end;

    local procedure EnableAccountODataWebService()
    begin
        UpdateIntegrationRecords(false);
    end;

    [Obsolete('Integration Records will be replaced by SystemID and SystemModifiedAt ', '17.0')]
    procedure UpdateIntegrationRecords(OnlyItemsWithoutId: Boolean)
    var
        GLAccount: Record "G/L Account";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        GLAccountRecordRef: RecordRef;
    begin
        GLAccountRecordRef.Open(DATABASE::"G/L Account");
        GraphMgtGeneralTools.UpdateIntegrationRecords(GLAccountRecordRef, GLAccount.FieldNo(Id), OnlyItemsWithoutId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        EnableAccountODataWebService;
    end;
}

