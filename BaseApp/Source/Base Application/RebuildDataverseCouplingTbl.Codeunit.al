codeunit 5362 "Rebuild Dataverse Coupling Tbl"
{
    trigger OnRun()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationRecord: Record "Integration Record";
        RecRef: RecordRef;
        CRMIntegrationRecordCorrectionDictionary: Dictionary of [Guid, Guid];
        SysIdAfterMigration: Guid;
        CRMIntegrationRecordSysId: Guid;
        CommitCounter: Integer;
    begin
        // collect all CRM Integration Record records that need to be corrected
        if CRMIntegrationRecord.FindSet() then
            repeat
                if IntegrationRecord.Get(CRMIntegrationRecord."Integration ID") then
                    if IntegrationRecord."Table ID" <> 0 then
                        if RecRef.Get(IntegrationRecord."Record ID") then begin
                            SysIdAfterMigration := RecRef.Field(RecRef.SystemIdNo()).Value();
                            if CRMIntegrationRecord."Integration ID" <> SysIdAfterMigration then
                                CRMIntegrationRecordCorrectionDictionary.Add(CRMIntegrationRecord.SystemId, SysIdAfterMigration);
                        end;
            until CRMIntegrationRecord.Next() = 0;

        // loop through the correction dictionary and rename the CRM Integration Record records with new values
        foreach CRMIntegrationRecordSysId in CRMIntegrationRecordCorrectionDictionary.Keys() do begin
            CommitCounter += 1;
            CRMIntegrationRecordCorrectionDictionary.Get(CRMIntegrationRecordSysId, SysIdAfterMigration);
            CRMIntegrationRecord.GetBySystemId(CRMIntegrationRecordSysId);
            CRMIntegrationRecord.Rename(CRMIntegrationRecord."CRM ID", SysIdAfterMigration);
            if CommitCounter = 1000 then begin
                Commit();
                CommitCounter := 0;
            end;
        end;
    end;
}