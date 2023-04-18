codeunit 7207 "CDS Set Coupled Flags"
{
    SingleInstance = true;

    trigger OnRun()
    begin
        SetCoupledFlags();
    end;

    local procedure SetCoupledFlags()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CommitCounter: Integer;
    begin
        if CRMIntegrationRecord.FindSet() then
            repeat
                if CRMIntegrationManagement.SetCoupledFlag(CRMIntegrationRecord, true, false) then
                    CommitCounter += 1;

                if CommitCounter = 1000 then begin
                    Commit();
                    CommitCounter := 0;
                end;
            until CRMIntegrationRecord.Next() = 0;
    end;
}