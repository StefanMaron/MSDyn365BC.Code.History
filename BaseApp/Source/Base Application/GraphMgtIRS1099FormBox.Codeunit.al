codeunit 10900 "Graph Mgt - IRS 1099 Form-Box"
{

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure UpdateIntegrationRecords(OnlyItemsWithoutId: Boolean)
    var
        DummyIRS1099FormBox: Record "IRS 1099 Form-Box";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        IRS1099FormBoxRecordRef: RecordRef;
    begin
        IRS1099FormBoxRecordRef.Open(DATABASE::"IRS 1099 Form-Box");
        GraphMgtGeneralTools.UpdateIntegrationRecords(IRS1099FormBoxRecordRef, DummyIRS1099FormBox.FieldNo(Id), OnlyItemsWithoutId);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5150, 'OnIsIntegrationRecord', '', false, false)]
    local procedure HandleIsIntegrationRecord(TableID: Integer; var isIntegrationRecord: Boolean)
    begin
        if isIntegrationRecord then
            exit;

        if TableID = DATABASE::"IRS 1099 Form-Box" then
            isIntegrationRecord := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5150, 'OnUpdateReferencedIdField', '', false, false)]
    local procedure HandleUpdateReferencedIdFieldOnItem(var RecRef: RecordRef; NewId: Guid; var Handled: Boolean)
    var
        DummyIRS1099FormBox: Record "IRS 1099 Form-Box";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(RecRef, NewId, Handled,
          DATABASE::"IRS 1099 Form-Box", DummyIRS1099FormBox.FieldNo(Id));
    end;

    [EventSubscriber(ObjectType::Codeunit, 5465, 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIntegrationRecords(false);
    end;
}

