page 7200 "CDS Connection Setup"
{
    AccessByPermission = TableData "CDS Connection Setup" = IM;
    ApplicationArea = Suite;
    Caption = 'Dataverse Connection Setup', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PromotedActionCategories = 'New,Connection,Integration,Encryption,Advanced,Synchronization';
    ShowFilter = false;
    SourceTable = "CDS Connection Setup";
    UsageCategory = Administration;
    Extensible = false;

    layout
    {
        area(content)
        {
            group(Connection)
            {
                Caption = 'Connection from Dynamics 365 Business Central to the Dataverse environment';
                field("Server Address"; "Server Address")
                {
                    ApplicationArea = Suite;
                    Enabled = IsEditable;
                    Editable = IsEditable;
                    ToolTip = 'Specifies the URL of the Dataverse environment that you want to connect to.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
                    AssistEdit = true;

                    trigger OnValidate()
                    begin
                        if "Server Address" <> xRec."Server Address" then
                            InitializeDefaultBusinessUnit();
                    end;

                    trigger OnAssistEdit()
                    var
                        CDSEnvironment: Codeunit "CDS Environment";
                    begin
                        CDSEnvironment.SelectTenantEnvironment(Rec, CDSEnvironment.GetGlobalDiscoverabilityToken(), false);

                        if "Server Address" <> xRec."Server Address" then
                            InitializeDefaultBusinessUnit();

                        CurrPage.Update();
                    end;
                }
                field("User Name"; "User Name")
                {
                    ApplicationArea = Suite;
                    Editable = IsEditable;
                    Visible = IsUserNamePasswordVisible;
                    ToolTip = 'Specifies the name of the user that will be used to connect to the Dataverse environment and synchronize data. This must not be the administrator user account.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
                }
                field(Password; UserPassword)
                {
                    ApplicationArea = Suite;
                    Editable = IsEditable;
                    Visible = IsUserNamePasswordVisible;
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the password of the user that will be used to connect to the Dataverse environment and synchronize data.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                    trigger OnValidate()
                    begin
                        if not IsTemporary() then
                            if (UserPassword <> '') and (not EncryptionEnabled()) then
                                if Confirm(EncryptionIsNotActivatedQst) then
                                    PAGE.RunModal(PAGE::"Data Encryption Management");
                        SetPassword(UserPassword);
                    end;
                }
                field("Client Id"; "Client Id")
                {
                    ApplicationArea = Suite;
                    Editable = IsEditable;
                    Visible = IsClientIdClientSecretVisible;
                    ToolTip = 'Specifies the ID of the Azure Active Directory application that will be used to connect to the Dataverse environment.', Comment = 'Dataverse and Azure Active Directory are names of a Microsoft service and a Microsoft Azure resource and should not be translated.';
                }
                field("Client Secret"; ClientSecret)
                {
                    ApplicationArea = Suite;
                    Caption = 'Client Secret';
                    Editable = IsEditable;
                    Visible = IsClientIdClientSecretVisible;
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the secret of the Azure Active Directory application that will be used to connect to the Dataverse environment.', Comment = 'Dataverse and Azure Active Directory are names of a Microsoft service and a Microsoft Azure resource and should not be translated.';

                    trigger OnValidate()
                    begin
                        if not IsTemporary() then
                            if (ClientSecret <> '') and (not EncryptionEnabled()) then
                                if Confirm(EncryptionIsNotActivatedQst) then
                                    PAGE.RunModal(PAGE::"Data Encryption Management");
                        SetClientSecret(ClientSecret);
                    end;
                }
                field("Redirect URL"; "Redirect URL")
                {
                    ApplicationArea = Suite;
                    Editable = IsEditable;
                    Visible = IsClientIdClientSecretVisible;
                    ToolTip = 'Specifies the Redirect URL of the Azure Active Directory app registration that will be used to connect to the Dataverse environment.', Comment = 'Dataverse and Azure Active Directory are names of a Microsoft service and a Microsoft Azure resource and should not be translated.';
                }
                field("SDK Version"; "Proxy Version")
                {
                    ApplicationArea = Suite;
                    AssistEdit = true;
                    Caption = 'SDK Version';
                    Visible = not SoftwareAsAService;
                    Editable = false;
                    Enabled = IsEditable;
                    ToolTip = 'Specifies the software development kit version that is used to connect to the Dataverse environment.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                    trigger OnAssistEdit()
                    begin
                        if CDSIntegrationImpl.SelectSDKVersion(Rec) then begin
                            RefreshStatuses := true;
                            CurrPage.Update(true);
                        end;
                    end;
                }
                field("Is Enabled"; "Is Enabled")
                {
                    ApplicationArea = Suite;
                    Caption = 'Enabled', Comment = 'Name of the check box that shows whether the connection to the Dataverse environment is enabled.';
                    ToolTip = 'Specifies whether the connection to the Dataverse environment is enabled. When you select this check box, you will be prompted to sign-in with an administrator user account and give consent to the app registration that will be used to connect to Dataverse. The account will be used one time to install and configure components that the integration requires.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                    trigger OnValidate()
                    var
                        CRMIntegrationRecord: Record "CRM Integration Record";
                        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
                    begin
                        RefreshStatuses := true;
                        CurrPage.Update(true);
                        if "Is Enabled" then begin
                            Session.LogMessage('0000CDE', CDSConnEnabledOnPageTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                            if "Ownership Model" = "Ownership Model"::Person then
                                if Confirm(DoYouWantToMakeSalesPeopleMappingQst, true) then
                                    CDSSetupDefaults.RunCoupleSalespeoplePage();
                        end else begin
                            CRMIntegrationRecord.SetFilter("Table ID", '<>0');
                            if not CRMIntegrationRecord.IsEmpty() then begin
                                if not Confirm(DisableIntegrationQst) then
                                    Error('');
                                Session.LogMessage('0000DRF', CDSConnDisabledOnPageTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                            end else
                                Session.LogMessage('0000DRG', CDSConnDisabledOnPageTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                        end;
                    end;
                }
            }
            group(Status)
            {
                Caption = 'Integration Solution Settings';
                Visible = "Is Enabled";
                field("CDS Version"; CDSVersion)
                {
                    ApplicationArea = Suite;
                    Caption = 'Dataverse Version';
                    Editable = false;
                    StyleExpr = CDSVersionStatusStyleExpr;
                    ToolTip = 'Specifies the version of Dataverse that you are connected to.';

                    trigger OnDrillDown()
                    begin
                        if CDSVersionStatus then
                            Message(FavorableCDSVersionMsg)
                        else
                            Message(UnfavorableCDSVersionMsg);
                    end;
                }
                field("Solution Version"; SolutionVersion)
                {
                    ApplicationArea = Suite;
                    Caption = 'Solution Version';
                    Editable = false;
                    StyleExpr = SolutionVersionStatusStyleExpr;
                    ToolTip = 'Specifies whether an integration solution is installed and configured in Dataverse. You cannot change this setting.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                    trigger OnDrillDown()
                    begin
                        if SolutionVersionStatus then
                            Message(FavorableSolutionMsg)
                        else
                            Message(UnfavorableSolutionMsg);
                    end;
                }
                field("User Status"; UserStatus)
                {
                    ApplicationArea = Suite;
                    Caption = 'User Roles checked';
                    Editable = false;
                    StyleExpr = UserStatusStyleExpr;
                    ToolTip = 'Specifies whether the integration user has the required roles in Dataverse. You cannot change this setting.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                    trigger OnDrillDown()
                    begin
                        if UserStatus then
                            Message(FavorableUserRolesMsg)
                        else
                            Message(UnfavorableUserRolesMsg);
                    end;
                }
                field("Team Status"; TeamStatus)
                {
                    ApplicationArea = Suite;
                    Caption = 'Team Roles checked';
                    Editable = false;
                    StyleExpr = TeamStatusStyleExpr;
                    ToolTip = 'Specifies whether the team that owns the selected business unit has the required roles in Dataverse. You cannot change this setting.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                    trigger OnDrillDown()
                    begin
                        if TeamStatus then
                            Message(FavorableTeamRolesMsg)
                        else
                            Message(UnfavorableTeamRolesMsg);
                    end;
                }
                field("Entities Status"; EntitiesStatus)
                {
                    ApplicationArea = Suite;
                    Caption = 'Entities availability checked';
                    Editable = false;
                    StyleExpr = EntitiesStatusStyleExpr;
                    ToolTip = 'Specifies whether the tables are available in Dataverse. You cannot change this setting.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                    trigger OnDrillDown()
                    begin
                        if EntitiesStatus then
                            Message(FavorableEntitiesMsg)
                        else
                            Message(UnfavorableEntitiesMsg);
                    end;
                }
            }
            group(AuthTypeDetails)
            {
                Caption = 'Authentication Type Details';
                Visible = not SoftwareAsAService;
                field("Authentication Type"; "Authentication Type")
                {
                    ApplicationArea = Advanced;
                    Editable = IsEditable;
                    ToolTip = 'Specifies the authentication type that will be used to authenticate with the Dataverse environment.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
                }
                field("Connection String"; "Connection String")
                {
                    ApplicationArea = Advanced;
                    Caption = 'Connection String';
                    Editable = IsEditable;
                    ToolTip = 'Specifies the connection string that will be used to connect to the Dataverse environment.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                    trigger OnValidate()
                    begin
                        CDSIntegrationImpl.SetConnectionString(Rec, "Connection String");
                    end;
                }
            }
            group(Advanced)
            {
                Caption = 'Advanced Settings';

                field("Ownership Model"; "Ownership Model")
                {
                    ApplicationArea = Suite;
                    Editable = IsEditable;
                    ToolTip = 'Specifies the type of owner that will be assigned to any row that is created while synchronizing from Business Central to Dataverse.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                    trigger OnValidate()
                    begin
                        RefreshStatuses := true;
                        CurrPage.Update(true);
                    end;
                }
                field("Business Unit Name"; "Business Unit Name")
                {
                    ApplicationArea = Suite;
                    AssistEdit = true;
                    Caption = 'Coupled Business Unit';
                    Editable = false;
                    Enabled = IsEditable;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the business unit that you want to connect to in the Dataverse environment.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                    trigger OnAssistEdit()
                    begin
                        CDSIntegrationImpl.CheckConnectionRequiredFields(Rec, false);
                        if CDSIntegrationImpl.SelectBusinessUnit(Rec) then begin
                            RefreshStatuses := true;
                            CurrPage.Update(true);
                        end;
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Assisted Setup")
            {
                ApplicationArea = Suite;
                Caption = 'Assisted Setup';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = IsEditable;
                ToolTip = 'Start the Dataverse Connection Setup guide.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                trigger OnAction()
                var
                    GuidedExperience: Codeunit "Guided Experience";
                    GuidedExperienceType: Enum "Guided Experience Type";
                begin
                    CDSIntegrationImpl.RegisterAssistedSetup();
                    Commit(); // Make sure all data is committed before we run the wizard
                    GuidedExperience.Run(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"CDS Connection Setup Wizard");
                    CurrPage.Update(false);
                    RefreshStatuses := true;
                end;
            }
            action("Test Connection")
            {
                ApplicationArea = Suite;
                Caption = 'Test Connection', Comment = 'Test is a verb.';
                Image = ValidateEmailLoggingSetup;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Test the connection to Dataverse using the specified settings.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                trigger OnAction()
                begin
                    if CDSIntegrationImpl.TestConnection(Rec) then
                        Message(ConnectionSuccessMsg)
                    else
                        Message(ConnectionFailedMsg, GetLastErrorText());
                end;
            }
            action("Use Certificate Authentication")
            {
                ApplicationArea = Suite;
                Caption = 'Use Cerificate Authentication';
                Image = Certificate;
                Visible = SoftwareAsAService;
                Promoted = true;
                Enabled = Rec."Is Enabled";
                PromotedCategory = Process;
                ToolTip = 'Upgrades the connection to Dataverse to use certificate-based OAuth2 service-to-service authentication.';

                trigger OnAction()
                var
                    TempCDSConnectionSetup: Record "CDS Connection Setup" temporary;
                    CRMConnectionSetup: Record "CRM Connection Setup";
                    CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
                begin
                    TempCDSConnectionSetup."Server Address" := "Server Address";
                    TempCDSConnectionSetup."User Name" := "User Name";
                    TempCDSConnectionSetup."Proxy Version" := CDSIntegrationImpl.GetLastProxyVersionItem();
                    TempCDSConnectionSetup."Authentication Type" := TempCDSConnectionSetup."Authentication Type"::Office365;
                    TempCDSConnectionSetup.Insert();

                    CDSIntegrationImpl.SetupCertificateAuthentication(TempCDSConnectionSetup);

                    if (TempCDSConnectionSetup."Connection String".IndexOf('{CERTIFICATE}') > 0) and (TempCDSConnectionSetup."User Name" <> "User Name") then begin
                        if CRMConnectionSetup.IsEnabled() then begin
                            CRMConnectionSetup."User Name" := TempCDSConnectionSetup."User Name";
                            CRMConnectionSetup.SetPassword('');
                            CRMConnectionSetup."Proxy Version" := TempCDSConnectionSetup."Proxy Version";
                            CRMConnectionSetup.SetConnectionString(TempCDSConnectionSetup."Connection String");
                        end;

                        "User Name" := TempCDSConnectionSetup."User Name";
                        SetPassword('');
                        "Proxy Version" := TempCDSConnectionSetup."Proxy Version";
                        "Connection String" := TempCDSConnectionSetup."Connection String";
                        Modify();
                        CurrPage.Update(false);
                        Session.LogMessage('0000FB4', CertificateConnectionSetupTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                        Message(StrSubstNo(CertificateConnectionSetupMsg, "User Name"));
                    end;
                end;
            }
            action(ResetConfiguration)
            {
                ApplicationArea = Suite;
                Caption = 'Use Default Synchronization Setup';
                Enabled = "Is Enabled";
                Image = ResetStatus;
                ToolTip = 'Resets the integration table mappings and synchronization jobs to the default values for a connection with Dataverse. All current mappings are deleted.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                trigger OnAction()
                var
                    CDSSetupDefaults: Codeunit "CDS Setup Defaults";
                begin
                    if Confirm(ResetIntegrationTableMappingConfirmQst, false) then begin
                        CDSSetupDefaults.ResetConfiguration(Rec);
                        Message(SetupSuccessfulMsg);
                        RefreshStatuses := true;
                    end;
                end;
            }
            action(CoupleUsers)
            {
                ApplicationArea = Suite;
                Caption = 'Couple Salespersons';
                Enabled = "Is Enabled" and ("Ownership Model" = "Ownership Model"::Person);
                Image = CoupledUsers;
                Promoted = true;
                PromotedCategory = "Report";
                ToolTip = 'Open the list of users in Dataverse to manually couple them with salespersons in Business Central.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                trigger OnAction()
                var
                    CRMSystemuserList: Page "CRM Systemuser List";
                begin
                    CRMSystemuserList.Initialize(true);
                    CRMSystemuserList.Run();
                end;
            }
            action(AddUsersToTeam)
            {
                ApplicationArea = Suite;
                Caption = 'Add Coupled Users to Team';
                Enabled = "Is Enabled" and ("Ownership Model" = "Ownership Model"::Person);
                Image = LinkAccount;
                Promoted = true;
                PromotedCategory = "Report";
                ToolTip = 'Add the coupled Dataverse users to the default owning team.';

                trigger OnAction()
                var
                    Added: Integer;
                begin
                    Added := CDSIntegrationImpl.AddCoupledUsersToDefaultOwningTeam(Rec);
                    Message(UsersAddedToTeamMsg, Added);
                end;
            }
            action(StartInitialSynchAction)
            {
                ApplicationArea = Suite;
                Caption = 'Run Full Synchronization';
                Enabled = "Is Enabled";
                Image = RefreshLines;
                Promoted = true;
                PromotedCategory = Category6;
                PromotedIsBig = true;
                ToolTip = 'Start all of the default integration jobs for synchronizing Business Central record types and Dataverse tables. Data is synchronized according to the mappings defined on the Integration Table Mappings page.';

                trigger OnAction()
                begin
                    PAGE.Run(PAGE::"CRM Full Synch. Review");
                end;
            }
            action(SynchronizeNow)
            {
                ApplicationArea = Suite;
                Caption = 'Synchronize Modified Records';
                Enabled = "Is Enabled";
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Category6;
                PromotedIsBig = true;
                ToolTip = 'Synchronize records that have been modified since the last time they were synchronized.';

                trigger OnAction()
                var
                    IntegrationSynchJobList: Page "Integration Synch. Job List";
                begin
                    if not Confirm(SynchronizeModifiedQst) then
                        exit;

                    SynchronizeNow(false);
                    Message(SyncNowScheduledMsg, IntegrationSynchJobList.Caption());
                end;
            }
        }
        area(Reporting)
        {
            action("Redeploy Solution")
            {
                ApplicationArea = Suite;
                Caption = 'Redeploy Integration Solution';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Report;
                Enabled = IsEditable;
                ToolTip = 'Redeploy and reconfigure the base integration solution.';

                trigger OnAction()
                begin
                    CDSIntegrationImpl.ImportAndConfigureIntegrationSolution(Rec, true, true);

                    if CDSIntegrationImpl.CheckIntegrationRequirements(Rec, true) then begin
                        Session.LogMessage('0000CDH', SuccessfullyRedeployedSolutionTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                        Message(DeploySucceedMsg)
                    end else begin
                        Session.LogMessage('0000CDI', UnsuccessfullyRedeployedSolutionTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                        Message(DeployFailedMsg);
                    end;
                    RefreshStatuses := true;
                    CurrPage.Update(true);
                end;
            }
            action("Integration Solutions")
            {
                ApplicationArea = Suite;
                Caption = 'Integration Solutions';
                Image = UserSetup;
                Promoted = true;
                PromotedCategory = Report;
                Enabled = "Is Enabled";
                ToolTip = 'View the integration solutions that help business apps synchronize data with Business Central through Dataverse.';

                trigger OnAction()
                begin
                    CDSIntegrationImpl.CheckConnectionRequiredFields(Rec, false);
                    Page.RunModal(PAGE::"CDS Integration Solutions");
                end;
            }
            action("Integration User Roles")
            {
                ApplicationArea = Suite;
                Caption = 'Integration User Roles';
                Image = UserSetup;
                Promoted = true;
                PromotedCategory = Report;
                Enabled = "Is Enabled";
                ToolTip = 'View the roles assigned to the integration user. The integration user is the user account in Dataverse that business apps use to synchronize data with Business Central through Dataverse.';

                trigger OnAction()
                begin
                    CDSIntegrationImpl.CheckConnectionRequiredFields(Rec, false);
                    Page.RunModal(PAGE::"CDS Integration User Roles");
                end;
            }
            action("Owning Team Roles")
            {
                ApplicationArea = Suite;
                Caption = 'Owning Team Roles';
                Image = UserSetup;
                Promoted = true;
                PromotedCategory = Report;
                Enabled = "Is Enabled";
                ToolTip = 'View the roles assigned to the team in Dataverse that owns the coupled entities. This requires that you are using the Team ownership model.';

                trigger OnAction()
                begin
                    CDSIntegrationImpl.CheckConnectionRequiredFields(Rec, false);
                    Page.RunModal(PAGE::"CDS Owning Team Roles");
                end;
            }
            action("Dataverse Integration User")
            {
                ApplicationArea = Suite;
                Caption = 'Dataverse Integration User';
                Image = UserSetup;
                Promoted = true;
                PromotedCategory = Report;
                Enabled = "Is Enabled";
                ToolTip = 'Open the Dataverse integration user.';

                trigger OnAction()
                begin
                    CDSIntegrationImpl.ShowIntegrationUser(Rec);
                end;
            }
            action("Dataverse Owning Team")
            {
                ApplicationArea = Suite;
                Caption = 'Dataverse Owning Team';
                Image = UserSetup;
                Promoted = true;
                PromotedCategory = Report;
                Enabled = "Is Enabled";
                ToolTip = 'Open the Dataverse owning team.';

                trigger OnAction()
                begin
                    CDSIntegrationImpl.ShowOwningTeam(Rec);
                end;
            }
        }
        area(Navigation)
        {
            action(EncryptionManagement)
            {
                ApplicationArea = Advanced;
                Caption = 'Encryption Management';
                Image = EncryptionKeys;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                RunObject = Page "Data Encryption Management";
                RunPageMode = View;
                ToolTip = 'Enable or disable data encryption. Data encryption helps make sure that unauthorized users cannot read business data.';
            }
            action(SkippedSynchRecords)
            {
                ApplicationArea = Suite;
                Caption = 'Skipped Synch. Records';
                Enabled = "Is Enabled";
                Image = NegativeLines;
                Promoted = true;
                PromotedCategory = Category6;
                RunObject = Page "CRM Skipped Records";
                RunPageMode = View;
                ToolTip = 'View the list of records that synchronization will skip.';
            }
            action("Synch. Job Queue Entries")
            {
                ApplicationArea = Suite;
                Caption = 'Synch. Job Queue Entries';
                Image = JobListSetup;
                Promoted = true;
                PromotedCategory = Category6;
                ToolTip = 'View the job queue entries that manage the scheduled synchronization between Dataverse and Business Central.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                trigger OnAction()
                var
                    JobQueueEntry: Record "Job Queue Entry";
                begin
                    JobQueueEntry.FilterGroup := 2;
                    JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
                    JobQueueEntry.SetFilter("Object ID to Run", GetJobQueueEntriesObjectIDToRunFilter());
                    JobQueueEntry.FilterGroup := 0;

                    PAGE.Run(PAGE::"Job Queue Entries", JobQueueEntry);
                end;
            }
            action(IntegrationTableMappings)
            {
                ApplicationArea = Suite;
                Caption = 'Integration Table Mappings';
                Enabled = "Is Enabled";
                Image = MapAccounts;
                Promoted = true;
                PromotedCategory = "Report";
                ToolTip = 'View the list of integration table mappings.';

                trigger OnAction()
                begin
                    Page.Run(Page::"Integration Table Mapping List");
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        RefreshData();
    end;

    trigger OnInit()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        ApplicationAreaMgmtFacade.CheckAppAreaOnlyBasic();
        SoftwareAsAService := EnvironmentInfo.IsSaaSInfrastructure();
        if SoftwareAsAService then
            CDSIntegrationImpl.RegisterAssistedSetup();
        SolutionKey := CDSIntegrationImpl.GetBaseSolutionUniqueName();
        SolutionName := CDSIntegrationImpl.GetBaseSolutionDisplayName();
        DefaultBusinessUnitName := CDSIntegrationImpl.GetDefaultBusinessUnitName();
        RefreshStatuses := true;
        SetVisibilityFlags();
    end;

    trigger OnOpenPage()
    begin
        if not Get() then begin
            Init();
            InitializeDefaultAuthenticationType();
            InitializeDefaultProxyVersion();
            InitializeDefaultOwnershipModel();
            InitializeDefaultBusinessUnit();
            InitializeDefaultRedirectUrl();
            Insert();
            LoadConnectionStringElementsFromCRMConnectionSetup();
        end else begin
            UserPassword := GetPassword();
            ClientSecret := GetClientSecret();
            if "Redirect URL" = '' then
                InitializeDefaultRedirectUrl();
            if (not IsValidAuthenticationType()) or (not IsValidProxyVersion()) or (not IsValidOwnershipModel() or (not IsValidBusinessUnit())) then begin
                CDSIntegrationImpl.UnregisterConnection();
                if not IsValidAuthenticationType() then
                    InitializeDefaultAuthenticationType();
                if not IsValidProxyVersion() then
                    InitializeDefaultProxyVersion();
                if not IsValidOwnershipModel() then
                    InitializeDefaultOwnershipModel();
                if not IsValidBusinessUnit() then
                    InitializeDefaultBusinessUnit();
                Modify();
            end;
            LoadConnectionStringElementsFromCRMConnectionSetup();
            if "Is Enabled" then
                CDSIntegrationImpl.RegisterConnection(Rec, true)
            else begin
                CDSIntegrationImpl.UnregisterConnection();
                if "Disable Reason" <> '' then
                    CDSIntegrationImpl.SendConnectionDisabledNotification("Disable Reason");
            end;
        end;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not "Is Enabled" then
            if not Confirm(StrSubstNo(EnableServiceQst, CurrPage.Caption()), true) then
                exit(false);
    end;

    var
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        SolutionKey: Text;
        SolutionName: Text;
        DefaultBusinessUnitName: Text;
        [NonDebuggable]
        UserPassword: Text;
        [NonDebuggable]
        ClientSecret: Text;
        ResetIntegrationTableMappingConfirmQst: Label 'This will restore the default integration table mappings and synchronization jobs for Dataverse. All customizations to mappings and jobs will be deleted. The default mappings and jobs will be used the next time data is synchronized. Do you want to continue?';
        EncryptionIsNotActivatedQst: Label 'Data encryption is currently not enabled. We recommend that you encrypt data. \Do you want to open the Data Encryption Management window?';
        EnableServiceQst: Label 'The %1 is not enabled. Are you sure you want to exit?', Comment = '%1 = This Page Caption (Dataverse Connection Setup)';
        UnfavorableCDSVersionMsg: Label 'This version of Dataverse might not work correctly with the Dataverse Base Integration solution. We recommend you upgrade to a supported version.';
        FavorableCDSVersionMsg: Label 'The version of Dataverse is valid.';
        UnfavorableSolutionMsg: Label 'The base integration solution was not detected in Dataverse.';
        FavorableSolutionMsg: Label 'The base integration solution is installed in Dataverse.';
        UnfavorableUserRolesMsg: Label 'Some base roles are not correctly assigned to the integration user.';
        FavorableEntitiesMsg: Label 'The base entities are available.';
        UnfavorableEntitiesMsg: Label 'Some base entities are not available.';
        FavorableUserRolesMsg: Label 'The base roles are correctly assigned to the integration user.';
        UnfavorableTeamRolesMsg: Label 'The base roles are not correctly assigned to the default owning team.';
        FavorableTeamRolesMsg: Label 'The base roles are correctly assigned to the default owning team.';
        DeploySucceedMsg: Label 'The solution, user roles, and entities have been deployed.';
        DeployFailedMsg: Label 'The deployment of the solution, user roles, and entities failed.';
        ConnectionSuccessMsg: Label 'The connection test was successful. The settings are valid.';
        ConnectionFailedMsg: Label 'The connection test has failed. %1.', Comment = '%1 = Connection test failure error message';
        SynchronizeModifiedQst: Label 'This will synchronize all modified records in all integration table mappings.\The synchronization will run in the background so you can continue with other tasks.\\Do you want to continue?';
        SyncNowScheduledMsg: Label 'Synchronization of modified records is scheduled.\You can view details on the %1 page.', Comment = '%1 = The localized caption of page Integration Synch. Job List';
        SetupSuccessfulMsg: Label 'The default setup for Dataverse synchronization has completed successfully.';
        DoYouWantToMakeSalesPeopleMappingQst: Label 'Do you want to map salespeople to users in Dataverse?';
        UsersAddedToTeamMsg: Label 'Count of users added to the default owning team: %1.', Comment = '%1 - count of users.';
        Office365AuthTxt: Label 'AuthType=Office365', Locked = true;
        CategoryTok: Label 'AL Dataverse Integration', Locked = true;
        DisableIntegrationQst: Label 'You are about to disable your integration with Dataverse, but some records are still coupled. If you will re-enable the integration later, you must remove all couplings before you disable the integration.\\Do you want to continue anyway?';
        CDSConnEnabledOnPageTxt: Label 'Dataverse Connection has been enabled from Dataverse Connection Setup page', Locked = true;
        CDSConnDisabledOnPageTxt: Label 'The connection to Dataverse has been disabled from the Dataverse Connection Setup page', Locked = true;
        SuccessfullyRedeployedSolutionTxt: Label 'The Dataverse solution has been successfully redeployed', Locked = true;
        UnsuccessfullyRedeployedSolutionTxt: Label 'The Dataverse solution has failed to be redeployed', Locked = true;
        CertificateConnectionSetupTelemetryMsg: Label 'User has successfully set up the certificate connection to Dataverse.', Locked = true;
        CertificateConnectionSetupMsg: Label 'You have successfully upgraded the connection to Dataverse to use certificate-based OAuth2 service-to-service authentication. Business Central has auto-generated a new integration user with user name %1 in your Dataverse environment. This user does not require a license.', Comment = '%1 - user name';
        IsEditable: Boolean;
        IsUserNamePasswordVisible: Boolean;
        IsClientIdClientSecretVisible: Boolean;
        SoftwareAsAService: Boolean;
        CDSVersion: Text;
        CDSVersionStatus: Boolean;
        SolutionVersion: Text;
        SolutionVersionStatus: Boolean;
        UserStatus: Boolean;
        TeamStatus: Boolean;
        EntitiesStatus: Boolean;
        CDSVersionStatusStyleExpr: Text;
        SolutionVersionStatusStyleExpr: Text;
        UserStatusStyleExpr: Text;
        TeamStatusStyleExpr: Text;
        EntitiesStatusStyleExpr: Text;
        RefreshStatuses: Boolean;

    local procedure RefreshData()
    begin
        UpdateEnableFlags();
        RefreshDataFromCDS();
    end;

    local procedure RefreshDataFromCDS()
    begin
        if not "Is Enabled" then
            exit;

        if not RefreshStatuses then
            exit;

        if CDSIntegrationImpl.TryCheckCredentials(Rec) then
            if CDSIntegrationImpl.GetCDSVersion(Rec, CDSVersion) then
                CDSVersionStatus := CDSIntegrationImpl.IsCDSVersionValid(CDSVersion)
            else
                CDSVersionStatus := false;
        if CDSIntegrationImpl.GetSolutionVersion(Rec, SolutionVersion) then
            SolutionVersionStatus := CDSIntegrationImpl.CheckIntegrationSolutionRequirements(Rec, true)
        else
            SolutionVersionStatus := false;
        UserStatus := CDSIntegrationImpl.CheckIntegrationUserRequirements(Rec, true);
        TeamStatus := CDSIntegrationImpl.CheckOwningTeamRequirements(Rec, true);
        EntitiesStatus := CDSIntegrationImpl.CheckEntitiesAvailability(Rec, true);
        SetStyleExpr();
        RefreshStatuses := false;
        CDSIntegrationImpl.ActivateConnection();
    end;

    local procedure SetStyleExpr()
    begin
        CDSVersionStatusStyleExpr := GetStyleExpr(CDSVersionStatus);
        SolutionVersionStatusStyleExpr := GetStyleExpr(SolutionVersionStatus);
        UserStatusStyleExpr := GetStyleExpr(UserStatus);
        TeamStatusStyleExpr := GetStyleExpr(TeamStatus);
        EntitiesStatusStyleExpr := GetStyleExpr(EntitiesStatus);
    end;

    local procedure GetStyleExpr(Status: Boolean): Text
    begin
        if Status then
            exit('Favorable');
        exit('Unfavorable');
    end;

    local procedure UpdateEnableFlags()
    begin
        IsEditable := not "Is Enabled";
    end;

    local procedure SetVisibilityFlags()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        IsUserNamePasswordVisible := true;
        IsClientIdClientSecretVisible := not SoftwareAsAService;

        if not CDSConnectionSetup.Get() then begin
            IsUserNamePasswordVisible := false;
            exit;
        end;

        if CDSConnectionSetup."Authentication Type" <> CDSConnectionSetup."Authentication Type"::Office365 then
            IsClientIdClientSecretVisible := false
        else
            if not "Connection String".Contains(Office365AuthTxt) then
                IsUserNamePasswordVisible := false;
    end;

    local procedure InitializeDefaultProxyVersion()
    begin
        Validate("Proxy Version", CDSIntegrationImpl.GetLastProxyVersionItem());
    end;

    local procedure InitializeDefaultOwnershipModel()
    begin
        Validate("Ownership Model", "Ownership Model"::Team);
    end;

    local procedure InitializeDefaultBusinessUnit()
    begin
        if "Server Address" = '' then
            "Business Unit Name" := ''
        else
            "Business Unit Name" := CopyStr(DefaultBusinessUnitName, 1, MaxStrLen("Business Unit Name"));
        Clear("Business Unit Id");
    end;

    local procedure InitializeDefaultRedirectUrl()
    var
        OAuth2: Codeunit "OAuth2";
        RedirectUrl: Text;
    begin
        OAuth2.GetDefaultRedirectUrl(RedirectUrl);
        "Redirect URL" := CopyStr(RedirectUrl, 1, MaxStrLen("Redirect URL"));
    end;

    local procedure InitializeDefaultAuthenticationType()
    begin
        Validate("Authentication Type", "Authentication Type"::Office365);
    end;

    local procedure IsValidAuthenticationType(): Boolean
    begin
        if SoftwareAsAService then
            exit("Authentication Type" = "Authentication Type"::Office365);
        exit(true);
    end;

    local procedure IsValidBusinessUnit(): Boolean
    begin
        exit(not IsNullGuid("Business Unit Id") and ("Business Unit Name" <> ''));
    end;

    local procedure IsValidProxyVersion(): Boolean
    begin
        exit("Proxy Version" <> 0);
    end;

    local procedure IsValidOwnershipModel(): Boolean
    begin
        exit("Ownership Model" in ["Ownership Model"::Person, "Ownership Model"::Team]);
    end;

    local procedure GetJobQueueEntriesObjectIDToRunFilter(): Text
    begin
        exit(
          StrSubstNo('%1|%2', Codeunit::"Integration Synch. Job Runner", Codeunit::"Int. Uncouple Job Runner"));
    end;
}
