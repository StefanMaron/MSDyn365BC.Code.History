codeunit 1882 "Sandbox Deploymt. Cleanup"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Codeunit will be made internal. Use OnClearConfiguration in "Sandbox Cleanup" instead.';
    ObsoleteTag = '17.0';

    trigger OnRun()
    begin
        RaiseEventForEveryCompany;
    end;

    var
        nullGUID: Guid;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sandbox Cleanup", 'OnClearCompanyConfiguration', '', false, false)]
    local procedure ClearCompanyConfiguration(CompanyName: Text)
    var
        OCRServiceSetup: Record "OCR Service Setup";
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
        GraphMailSetup: Record "Graph Mail Setup";
        SMTPMailSetup: Record "SMTP Mail Setup";
        CRMConnectionSetup: Record "CRM Connection Setup";
        ServiceConnection: Record "Service Connection";
        MarketingSetup: Record "Marketing Setup";
        ExchangeSync: Record "Exchange Sync";
    begin
        OCRServiceSetup.ChangeCompany(CompanyName);
        OCRServiceSetup.ModifyAll("Password Key", nullGUID);

        DocExchServiceSetup.ChangeCompany(CompanyName);
        DocExchServiceSetup.ModifyAll(Enabled, false);

        CurrExchRateUpdateSetup.ChangeCompany(CompanyName);
        CurrExchRateUpdateSetup.ModifyAll(Enabled, false);

        VATRegNoSrvConfig.ChangeCompany(CompanyName);
        VATRegNoSrvConfig.ModifyAll(Enabled, false);

        GraphMailSetup.ChangeCompany(CompanyName);
        GraphMailSetup.ModifyAll(Enabled, false);

        SMTPMailSetup.ChangeCompany(CompanyName);
        SMTPMailSetup.ModifyAll("SMTP Server", '');

        CRMConnectionSetup.ChangeCompany(CompanyName);
        CRMConnectionSetup.ModifyAll("Is Enabled", false);

        ServiceConnection.ChangeCompany(CompanyName);
        ServiceConnection.ModifyAll(Status, ServiceConnection.Status::Disabled);

        MarketingSetup.ChangeCompany(CompanyName);
        MarketingSetup.ModifyAll("Exchange Service URL", '');

        ExchangeSync.ChangeCompany(CompanyName);
        ExchangeSync.ModifyAll(Enabled, false);

        OnClearConfiguration(CompanyName);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sandbox Cleanup", 'OnClearDatabaseConfiguration', '', false, false)]
    local procedure ClearDatabaseConfiguration()
    var
        FlowServiceConfiguration: Record "Flow Service Configuration";
        SatisfactionSurveyMgt: Codeunit "Satisfaction Survey Mgt.";
    begin
        SatisfactionSurveyMgt.ResetState;
        FlowServiceConfiguration.ModifyAll("Flow Service", FlowServiceConfiguration."Flow Service"::"Testing Service (TIP 1)");
        OnClearConfiguration('');
    end;

    [Obsolete('Use OnClearConfiguration in codeunit "Sandbox Cleanup" from "System Application', '17.0')]
    [IntegrationEvent(false, false)]
    local procedure OnClearConfiguration(CompanyToBlock: Text)
    begin
    end;

    [Obsolete('Use OnClearConfiguration in codeunit "Sandbox Cleanup" from "System Application', '17.0')]
    local procedure RaiseEventForEveryCompany()
    var
        Company: Record Company;
    begin
        if Company.FindSet then
            repeat
                OnClearConfiguration(Company.Name);
            until Company.Next = 0;
        OnClearConfiguration('');
    end;
}

