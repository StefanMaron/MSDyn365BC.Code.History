codeunit 4001 "Hybrid Cloud Management"
{
    Permissions = tabledata "Webhook Subscription" = rimd;

    var
        SubscriptionFormatTxt: Label '%1_IntelligentCloud', Comment = '%1 - The source product id', Locked = true;
        ServiceSubscriptionFormatTxt: Label 'IntelligentCloudService_%1', Comment = '%1 - The source product id', Locked = true;

    procedure CanHandleNotification(SubscriptionId: Text; ProductId: Text): Boolean
    var
        ExpectedSubscriptionId: Text;
    begin
        ExpectedSubscriptionId := StrSubstNo(SubscriptionFormatTxt, ProductId);
        exit((StrPos(SubscriptionId, ExpectedSubscriptionId) > 0) OR
            CanHandleServiceNotification(SubscriptionId, ProductId));
    end;

    procedure CanHandleServiceNotification(SubscriptionId: Text; ProductId: Text): Boolean
    var
        ExpectedServiceSubscriptionId: Text;
    begin
        ExpectedServiceSubscriptionId := StrSubstNo(ServiceSubscriptionFormatTxt, ProductId);
        exit(StrPos(SubscriptionId, ExpectedServiceSubscriptionId) > 0);
    end;

    procedure CanSetupIntelligentCloud(): Boolean
    var
        UserPermissions: Codeunit "User Permissions";
        CanSetup: Boolean;
    begin
        CanSetup := UserPermissions.IsSuper(UserSecurityId()) and TaskScheduler.CanCreateTask();
        OnCanSetupIntelligentCloud(CanSetup);
        exit(CanSetup);
    end;

    procedure CreateCompanies()
    var
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        CanCreateCompanies: Boolean;
    begin
        CanCreateCompanies := true;
        OnCanCreateCompanies(CanCreateCompanies);

        if not CanCreateCompanies then
            exit;

        IntelligentCloudSetup.LockTable();
        IntelligentCloudSetup.Get();
        IntelligentCloudSetup."Company Creation Task Status" := IntelligentCloudSetup."Company Creation Task Status"::InProgress;

        IntelligentCloudSetup."Company Creation Task ID" := TaskScheduler.CreateTask(
            Codeunit::"Create Companies IC",
            Codeunit::"Handle Create Company Failure", true, '', 0DT);

        IntelligentCloudSetup.Modify();
    end;

    procedure GetTotalFailedTables() Count: Integer
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        HybridReplicationDetail: Record "Hybrid Replication Detail";
        HybridCompany: Record "Hybrid Company";
    begin
        HybridReplicationSummary.SetCurrentKey("Start Time");
        HybridReplicationSummary.SetRange(Status, HybridReplicationSummary.Status::Completed);
        if not HybridReplicationSummary.FindLast() then
            exit;

        HybridReplicationDetail.SetRange("Run ID", HybridReplicationSummary."Run ID");
        HybridReplicationDetail.SetFilter(Status, '%1|%2', HybridReplicationDetail.Status::Failed, HybridReplicationDetail.Status::Warning);
        HybridCompany.SetRange(Replicate, true);
        if HybridReplicationDetail.FindSet() then
            repeat
                HybridCompany.SetRange(Name, HybridReplicationDetail."Company Name");
                if (HybridReplicationDetail."Company Name" = '') or not HybridCompany.IsEmpty() then
                    Count += 1;
            until HybridReplicationDetail.Next() = 0;
    end;

    procedure GetTotalSuccessfulTables() Count: Integer
    var
        HybridReplicationDetail: Record "Hybrid Replication Detail";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        PreviousRecord: Record "Hybrid Replication Detail";
    begin
        HybridReplicationDetail.SetCurrentKey("Table Name", "Company Name");
        HybridReplicationDetail.SetRange(Status, HybridReplicationDetail.Status::Successful);
        if HybridReplicationDetail.FindFirst() then
            repeat
                HybridReplicationSummary.Get(HybridReplicationDetail."Run ID");

                if HybridReplicationSummary.ReplicationType IN [HybridReplicationSummary.ReplicationType::Full, HybridReplicationSummary.ReplicationType::Normal] then begin
                    if (HybridReplicationDetail."Company Name" <> PreviousRecord."Company Name") or (HybridReplicationDetail."Table Name" <> PreviousRecord."Table Name") then
                        Count += 1;

                    PreviousRecord := HybridReplicationDetail;
                end;
            until HybridReplicationDetail.Next() = 0
    end;

    procedure GetTotalTablesNotMigrated() TotalTables: Integer;
    var
        HybridCompany: Record "Hybrid Company";
        TableMetadata: Record "Table Metadata";
    begin
        TableMetadata.RESET();
        TableMetadata.SETRANGE(ReplicateData, false);
        TableMetadata.SetFilter(ID, '<%1|>%2', 2000000000, 2000000300);
        TableMetadata.SetFilter(Name, '<>*Buffer');
        HybridCompany.Reset();
        HybridCompany.SetRange(Replicate, true);
        if HybridCompany.FindSet() then
            repeat
                IF TableMetadata.CHANGECOMPANY(HybridCompany.Name) THEN // CHANGECOMPANY should transfer the range to the new company
                    TotalTables := TotalTables + TableMetadata.CountApprox();
            until HybridCompany.Next() = 0;

        // Now add the system tables
        TableMetadata.RESET();
        TableMetadata.SETRANGE(ReplicateData, false);
        TableMetadata.SETRANGE(DataPerCompany, false);
        TableMetadata.SetFilter(ID, '<%1|>%2', 2000000000, 2000000300);
        TableMetadata.SetFilter(Name, '<>*Buffer');
        if TableMetadata.FindSet() then
            TotalTables := TotalTables + TableMetadata.Count();
    end;

    procedure GetSaasWizardRedirectUrl(var IntelligentCloudSetup: Record "Intelligent Cloud Setup") RedirectUrl: Text
    var
        baseUrl: Text;
        filterUrl: Text;
        noDomainUrl: Text;
        saasDomainFromatTxt: Label 'https://businesscentral.dynamics.com/%1';
    begin
        IntelligentCloudSetup.SetRange("Primary Key", GetRedirectFilter());

        baseUrl := GetUrl(ClientType::Web);
        filterUrl := GetUrl(CLIENTTYPE::Web, '', OBJECTTYPE::Page, Page::"Hybrid Cloud Setup Wizard", IntelligentCloudSetup, true);
        noDomainUrl := DelChr(filterUrl, '<', baseUrl);

        RedirectUrl := StrSubstNo(saasDomainFromatTxt, noDomainUrl);
    end;

    procedure GetRedirectFilter() RedirectFilter: Text
    begin
        RedirectFilter := 'FROMONPREM';
    end;

    procedure GetChosenProductName(): Text
    var
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
    begin
        if not IntelligentCloudSetup.Get() then
            exit('');

        exit(GetHybridProductName(IntelligentCloudSetup."Product ID"));
    end;

    procedure GetHybridProductName(ProductId: Text) ProductName: Text
    begin
        OnGetHybridProductName(ProductId, ProductName);
    end;

    procedure HandleShowCompanySelectionStep(var HybridProductType: Record "Hybrid Product Type"; SqlConnectionString: Text; SqlServerType: Text; IRName: Text)
    var
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        HybridDeployment: Codeunit "Hybrid Deployment";
        HandledExternally: Boolean;
        DeployedVersion: Text;
        LatestVersion: Text;
    begin
        OnBeforeShowCompanySelectionStep(HybridProductType, SqlConnectionString, SqlServerType, IRName, HandledExternally);
        if HandledExternally then
            exit;

        HybridDeployment.Initialize(HybridProductType.ID);
        HybridDeployment.EnableReplication(SqlConnectionString, SqlServerType, IRName);

        HybridDeployment.GetVersionInformation(DeployedVersion, LatestVersion);
        IntelligentCloudSetup.SetDeployedVersion(DeployedVersion);
        IntelligentCloudSetup.SetLatestVersion(LatestVersion);
    end;

    procedure HandleShowIRInstructionsStep(var HybridProductType: Record "Hybrid Product Type"; var IRName: Text; var PrimaryKey: Text)
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
        HandledExternally: Boolean;
    begin
        OnBeforeShowIRInstructionsStep(HybridProductType, IRName, PrimaryKey, HandledExternally);
        if HandledExternally OR (IRName <> '') then
            exit;

        HybridDeployment.Initialize(HybridProductType.ID);
        HybridDeployment.CreateIntegrationRuntime(IRName, PrimaryKey);
    end;

    procedure RefreshReplicationStatus()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        HybridDeployment: Codeunit "Hybrid Deployment";
        HybridMessageManagement: Codeunit "Hybrid Message Management";
        Status: Text;
        Errors: Text;
    begin
        HybridReplicationSummary.SetRange("Run ID", '');
        HybridReplicationSummary.DeleteAll();
        HybridReplicationSummary.SetRange("Run ID");

        HybridReplicationSummary.SetRange(Status, HybridReplicationSummary.Status::InProgress);
        if HybridReplicationSummary.FindSet(true) then begin
            IntelligentCloudSetup.Get();
            HybridDeployment.Initialize(IntelligentCloudSetup."Product ID");
            repeat
                HybridDeployment.GetReplicationRunStatus(HybridReplicationSummary."Run ID", Status, Errors);
                if Status <> Format(HybridReplicationSummary.Status::InProgress) then begin
                    HybridReplicationSummary.EvaluateStatus(Status);
                    if not (Errors in ['', '[]']) then begin
                        Errors := HybridMessageManagement.ResolveMessageCode('', Errors);
                        HybridReplicationSummary.SetDetails(Errors);
                    end;

                    HybridReplicationSummary.Modify();
                end;
            until HybridReplicationSummary.Next() = 0;
        end;
    end;

    procedure RunReplication(ReplicationType: Option) RunId: Text;
    var
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        IntelligentCloudSetup.Get();
        HybridDeployment.Initialize(IntelligentCloudSetup."Product ID");
        if ReplicationType = HybridReplicationSummary.ReplicationType::Full then
            HybridDeployment.ResetCloudData();

        HybridDeployment.RunReplication(RunId, ReplicationType);
        HybridReplicationSummary.CreateInProgressRecord(RunId, ReplicationType);
    end;

    local procedure AddWebhookSubscription(SubscriptionId: Text[150]; ClientState: Text[50])
    var
        WebhookSubscription: Record "Webhook Subscription";
        SubscriptionExists: Boolean;
    begin
        WebhookSubscription.LockTable();
        SubscriptionExists := WebhookSubscription.GET(SubscriptionId, '');
        WebhookSubscription."Application ID" := CopyStr(ApplicationIdentifier(), 1, 20);
        WebhookSubscription."Client State" := ClientState;
        WebhookSubscription."Company Name" := CopyStr(CompanyName(), 1, 30);
        WebhookSubscription."Run Notification As" := UserSecurityId();
        WebhookSubscription."Subscription ID" := SubscriptionId;

        if SubscriptionExists then
            WebhookSubscription.Modify()
        else
            WebhookSubscription.Insert();

        Commit();
    end;

    procedure ConstructTableName(Name: Text[30]; TableID: Integer) TableName: Text[250]
    var
        NavAppObjectMetadata: Record "NAV App Object Metadata";
        NavApp: Record "NAV App";
        AppID: Text[50];
    begin
        TableName := Name;
        NavAppObjectMetadata.Reset();
        NavAppObjectMetadata.SetRange("Object Type", NavAppObjectMetadata."Object Type"::Table);
        NavAppObjectMetadata.SetRange("Object ID", TableID);
        if NavAppObjectMetadata.FindFirst() then begin
            NavApp.Reset();
            NavApp.SetRange("Package ID", NavAppObjectMetadata."App Package ID");
            If NavApp.FindFirst() then begin
                AppID := CopyStr(Lowercase(CopyStr(NavApp.ID, 2, (StrLen(NavApp.ID) - 2))), 1, 50);
                TableName := CopyStr(TableName + '$' + AppID, 1, 250);
            end;
        end;
        exit(TableName);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowIRInstructionsStep(var HybridProductType: Record "Hybrid Product Type"; var IRName: Text; var PrimaryKey: Text; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowCompanySelectionStep(var HybridProductType: Record "Hybrid Product Type"; SqlConnectionString: Text; SqlServerType: Text; IRName: Text; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnGetHybridProductType(var HybridProductType: Record "Hybrid Product Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnGetHybridProductName(ProductId: Text; var ProductName: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnShowProductTypeStep(var HybridProductType: Record "Hybrid Product Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnShowSQLServerTypeStep(var HybridProductType: Record "Hybrid Product Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnShowScheduleStep(var HybridProductType: Record "Hybrid Product Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnShowDoneStep(var HybridProductType: Record "Hybrid Product Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCanSetupIntelligentCloud(var CanSetup: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnReplicationRunCompleted(RunId: Text[50]; SubscriptionId: Text; NotificationText: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCanCreateCompanies(var CanCreateCompanies: Boolean)
    begin
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure AddIntelligentCloudToAssistedSetupInCompany()
    var
        HybridCloudInstall: Codeunit "Hybrid Cloud Install";
        HybridCueSetupManagement: Codeunit "Hybrid Cue Setup Management";
        PermissionManager: Codeunit "Permission Manager";
    begin
        HybridCloudInstall.AddIntelligentCloudToAssistedSetup(PermissionManager.IsIntelligentCloud());
        HybridCueSetupManagement.InsertDataForReplicationSuccessRateCue();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnBeforeEnableReplication', '', false, false)]
    local procedure CreateWebhookSubscriptionOnEnableReplication(ProductId: Text; var NotificationUrl: Text; var SubscriptionId: Text[150]; var ClientState: Text[50]; var ServiceNotificationUrl: Text; var ServiceSubscriptionId: Text[150]; var ServiceClientState: Text[50])
    var
        WebhookManagement: Codeunit "Webhook Management";
    begin
        NotificationUrl := WebhookManagement.GetNotificationUrl();
        SubscriptionId := COPYSTR(STRSUBSTNO(SubscriptionFormatTxt, ProductId), 1, 150);
        ClientState := CreateGuid();

        ServiceNotificationUrl := WebhookManagement.GetNotificationUrl();
        ServiceSubscriptionId := COPYSTR(STRSUBSTNO(ServiceSubscriptionFormatTxt, ProductId), 1, 150);
        ServiceClientState := CreateGuid();

        AddWebhookSubscription(SubscriptionId, ClientState);
        AddWebhookSubscription(ServiceSubscriptionId, ServiceClientState);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Company", 'OnAfterRenameEvent', '', false, false)]
    local procedure HandleCompanyRename(var Rec: Record Company; var xRec: Record Company; RunTrigger: Boolean)
    var
        Company: Record Company;
        WebhookSubscription: Record "Webhook Subscription";
        FilterStr: Text;
    begin
        FilterStr := StrSubstNo(SubscriptionFormatTxt, '*') + '|' + StrSubstNo(ServiceSubscriptionFormatTxt, '*');
        WebhookSubscription.SetFilter("Subscription ID", FilterStr);

        if WebhookSubscription.FindSet() then
            repeat
                if not Company.Get(WebhookSubscription."Company Name") then begin
                    WebhookSubscription."Company Name" := Rec.Name;
                    WebhookSubscription.Modify();
                end;
            until WebhookSubscription.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Company", 'OnAfterDeleteEvent', '', false, false)]
    local procedure HandleCompanyDelete(var Rec: Record Company; RunTrigger: Boolean)
    var
        Company: Record Company;
        WebhookSubscription: Record "Webhook Subscription";
        HybridCompany: Record "Hybrid Company";
        FilterStr: Text;
        ReplacementCompanyName: Text[30];
    begin
        FilterStr := StrSubstNo(SubscriptionFormatTxt, '*') + '|' + StrSubstNo(ServiceSubscriptionFormatTxt, '*');
        WebhookSubscription.SetRange("Company Name", Rec.Name);
        WebhookSubscription.SetFilter("Subscription ID", FilterStr);

        if not WebhookSubscription.IsEmpty() and Company.FindSet() then begin
            ReplacementCompanyName := Company.Name;

            repeat
                if not HybridCompany.Get(Company.Name) then begin
                    ReplacementCompanyName := Company.Name;
                    break;
                end;
            until Company.Next() = 0;

            WebhookSubscription.ModifyAll("Company Name", ReplacementCompanyName);
        end;
    end;
}