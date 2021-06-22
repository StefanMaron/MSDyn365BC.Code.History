codeunit 1882 "Sandbox Deploymt. Cleanup"
{

    trigger OnRun()
    begin
        RaiseEventForEveryCompany;
    end;

    var
        nullGUID: Guid;

    [EventSubscriber(ObjectType::Codeunit, 1882, 'OnClearConfiguration', '', false, false)]
    local procedure ClearConfiguration(CompanyToBlock: Text)
    var
        OCRServiceSetup: Record "OCR Service Setup";
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        FlowServiceConfiguration: Record "Flow Service Configuration";
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
        GraphMailSetup: Record "Graph Mail Setup";
        SMTPMailSetup: Record "SMTP Mail Setup";
        CRMConnectionSetup: Record "CRM Connection Setup";
        ServiceConnection: Record "Service Connection";
        MarketingSetup: Record "Marketing Setup";
        ExchangeSync: Record "Exchange Sync";
        SatisfactionSurveyMgt: Codeunit "Satisfaction Survey Mgt.";
    begin
        if CompanyToBlock <> '' then begin
            OCRServiceSetup.ChangeCompany(CompanyToBlock);
            OCRServiceSetup.ModifyAll("Password Key", nullGUID);

            DocExchServiceSetup.ChangeCompany(CompanyToBlock);
            DocExchServiceSetup.ModifyAll(Enabled, false);

            CurrExchRateUpdateSetup.ChangeCompany(CompanyToBlock);
            CurrExchRateUpdateSetup.ModifyAll(Enabled, false);

            VATRegNoSrvConfig.ChangeCompany(CompanyToBlock);
            VATRegNoSrvConfig.ModifyAll(Enabled, false);

            GraphMailSetup.ChangeCompany(CompanyToBlock);
            GraphMailSetup.ModifyAll(Enabled, false);

            SMTPMailSetup.ChangeCompany(CompanyToBlock);
            SMTPMailSetup.ModifyAll("SMTP Server", '');

            CRMConnectionSetup.ChangeCompany(CompanyToBlock);
            CRMConnectionSetup.ModifyAll("Is Enabled", false);

            ServiceConnection.ChangeCompany(CompanyToBlock);
            ServiceConnection.ModifyAll(Status, ServiceConnection.Status::Disabled);

            MarketingSetup.ChangeCompany(CompanyToBlock);
            MarketingSetup.ModifyAll("Exchange Service URL", '');

            ExchangeSync.ChangeCompany(CompanyToBlock);
            ExchangeSync.ModifyAll(Enabled, false);
        end else begin
            SatisfactionSurveyMgt.ResetState;
            FlowServiceConfiguration.ModifyAll("Flow Service", FlowServiceConfiguration."Flow Service"::"Testing Service (TIP 1)");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnClearConfiguration(CompanyToBlock: Text)
    begin
    end;

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

