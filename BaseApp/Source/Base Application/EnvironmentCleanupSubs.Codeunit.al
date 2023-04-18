codeunit 8912 "Environment Cleanup Subs"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Cleanup", 'OnClearCompanyConfig', '', false, false)]
    local procedure ClearCompanyConfigGeneral(CompanyName: Text; SourceEnv: Enum "Environment Type"; DestinationEnv: Enum "Environment Type")
    var
        OCRServiceSetup: Record "OCR Service Setup";
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
#if not CLEAN21
        GraphMailSetup: Record "Graph Mail Setup";
#endif
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSConnectionSetup: Record "CDS Connection Setup";
        ServiceConnection: Record "Service Connection";
#if not CLEAN22
        MarketingSetup: Record "Marketing Setup";
#endif
        ExchangeSync: Record "Exchange Sync";
        JobQueueManagement: Codeunit "Job Queue Management";
        nullGUID: Guid;
    begin
        // For behavior in all cases of copying a new env.

        OCRServiceSetup.ModifyAll("Password Key", nullGUID);

        DocExchServiceSetup.ModifyAll(Enabled, false);

        CurrExchRateUpdateSetup.ModifyAll(Enabled, false);

        VATRegNoSrvConfig.ModifyAll(Enabled, false);
#if not CLEAN21
        GraphMailSetup.ModifyAll(Enabled, false);
#endif
        CRMConnectionSetup.ModifyAll("Is Enabled", false);

        CDSConnectionSetup.ModifyAll("Is Enabled", false);

        ServiceConnection.ModifyAll(Status, ServiceConnection.Status::Disabled);
#if not CLEAN22
        MarketingSetup.ModifyAll("Exchange Service URL", '');
#endif
        ExchangeSync.ModifyAll(Enabled, false);

        JobQueueManagement.SetRecurringJobsOnHold(CompanyName);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Cleanup", 'OnClearCompanyConfig', '', false, false)]
    local procedure ClearCompanyConfigProdToProd(CompanyName: Text; SourceEnv: Enum "Environment Type"; DestinationEnv: Enum "Environment Type")
    begin
        // Example on how to enfore a specific scenario. For instance prod to prod. 
        if (SourceEnv <> SourceEnv::Production) or (DestinationEnv <> DestinationEnv::Production) then
            exit;

        // Prod to prod copy cleanup code goes here

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Cleanup", 'OnClearDatabaseConfig', '', false, false)]
    local procedure ClearDatabaseConfigGeneral(SourceEnv: Enum "Environment Type"; DestinationEnv: Enum "Environment Type")
    var
        FlowServiceConfiguration: Record "Flow Service Configuration";
        SatisfactionSurveyMgt: Codeunit "Satisfaction Survey Mgt.";
    begin
        // For behavior in all cases of copying a new env.

        SatisfactionSurveyMgt.ResetState();
        FlowServiceConfiguration.ModifyAll("Flow Service", FlowServiceConfiguration."Flow Service"::"Testing Service (TIP 1)");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Cleanup", 'OnClearDatabaseConfig', '', false, false)]
    local procedure ClearDatabaseConfigProdToProd(SourceEnv: Enum "Environment Type"; DestinationEnv: Enum "Environment Type")
    begin
        // Example on how to enfore a specific scenario. For instance prod to prod. 
        if (SourceEnv <> SourceEnv::Production) or (DestinationEnv <> DestinationEnv::Production) then
            exit;

        // Prod to prod copy cleanup code goes here

    end;

}