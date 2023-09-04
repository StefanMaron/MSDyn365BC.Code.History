codeunit 5362 "Rebuild Dataverse Coupling Tbl"
{
    trigger OnRun()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecRef: RecordRef;
        CRMIntegrationRecordCorrectionDictionary: Dictionary of [Guid, Guid];
        SysIdAfterMigration: Guid;
        CRMIntegrationRecordSysId: Guid;
        CommitCounter: Integer;
    begin
        // collect all CRM Integration Record records that need to be corrected
        if CRMIntegrationRecord.FindSet() then
            repeat
                if TryOpen(RecRef, CRMIntegrationRecord."Table ID") then begin
                    if RecRef.GetBySystemId(CRMIntegrationRecord."Integration ID") then begin
                        SysIdAfterMigration := RecRef.Field(RecRef.SystemIdNo()).Value();
                        if CRMIntegrationRecord."Integration ID" <> SysIdAfterMigration then
                            CRMIntegrationRecordCorrectionDictionary.Add(CRMIntegrationRecord.SystemId, SysIdAfterMigration);
                    end;
                    RecRef.Close();
                end
            until CRMIntegrationRecord.Next() = 0;

        // loop through the correction dictionary and rename the CRM Integration Record records with new values
        foreach CRMIntegrationRecordSysId in CRMIntegrationRecordCorrectionDictionary.Keys() do begin
            CommitCounter += 1;
            CRMIntegrationRecordCorrectionDictionary.Get(CRMIntegrationRecordSysId, SysIdAfterMigration);
            CRMIntegrationRecord.GetBySystemId(CRMIntegrationRecordSysId);
            CRMIntegrationRecord.Rename(CRMIntegrationRecord."CRM ID", SysIdAfterMigration);
            if CRMIntegrationRecord."Table ID" = 0 then
                CRMIntegrationRecord.GetTableID();
            if CommitCounter = 1000 then begin
                Commit();
                CommitCounter := 0;
            end;
        end;
    end;

    [TryFunction]
    local procedure TryOpen(var RecRef: RecordRef; TableId: Integer)
    begin
        RecRef.Open(TableId);
    end;
}