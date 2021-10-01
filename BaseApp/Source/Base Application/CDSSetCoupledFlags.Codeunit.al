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
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CommitCounter: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetSetCoupledFlagsUpgradeTag()) then
            exit;

        if CRMIntegrationRecord.FindSet() then
            repeat
                if CRMIntegrationManagement.SetCoupledFlag(CRMIntegrationRecord, true) then
                    CommitCounter += 1;

                if CommitCounter = 1000 then begin
                    Commit();
                    CommitCounter := 0;
                end;
            until CRMIntegrationRecord.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetSetCoupledFlagsUpgradeTag());
    end;
}