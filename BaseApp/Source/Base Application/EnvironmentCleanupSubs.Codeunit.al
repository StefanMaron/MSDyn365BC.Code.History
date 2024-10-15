namespace System.Environment;

using Microsoft.CRM.Outlook;
using Microsoft.Integration.SyncEngine;
#if not CLEAN22
using Microsoft.CRM.Setup;
#endif
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Currency;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.D365Sales;
using Microsoft.Utilities;
using System.DataAdministration;
using System.Threading;
using System.Automation;
using System.Feedback;
using System.Reflection;

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

        CleanCDSIntegration();

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

    local procedure CleanCDSIntegration()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CDSIntegrationSyncJob: Record "Integration Synch. Job";
        CDSIntegrationsSyncJobErrors: Record "Integration Synch. Job Errors";
        TableKey: Codeunit "Table Key";
        DisableCleanup: Boolean;
    begin
        // Here we delete the setup records
        CDSConnectionSetup.DeleteAll();
        CRMConnectionSetup.DeleteAll();

        // Here we delete the integration links
        CDSIntegrationSyncJob.DeleteAll();
        CDSIntegrationsSyncJobErrors.DeleteAll();

        OnBeforeCleanCRMIntegrationRecords(DisableCleanup);
        if DisableCleanup then
            exit;

        // Deleting all couplings can timeout so disable the keys before deleting
        TableKey.DisableAll(Database::"CRM Integration Record");
        CRMIntegrationRecord.DeleteAll();
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
        Commit();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Cleanup", 'OnClearDatabaseConfig', '', false, false)]
    local procedure ClearDatabaseConfigProdToProd(SourceEnv: Enum "Environment Type"; DestinationEnv: Enum "Environment Type")
    begin
        // Example on how to enfore a specific scenario. For instance prod to prod. 
        if (SourceEnv <> SourceEnv::Production) or (DestinationEnv <> DestinationEnv::Production) then
            exit;

        // Prod to prod copy cleanup code goes here

    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCleanCRMIntegrationRecords(var DisableCleanup: Boolean)
    begin
    end;
}