page 7200 "CDS Connection Setup"
{
    AccessByPermission = TableData "CDS Connection Setup" = IM;
    ApplicationArea = Suite;
    Caption = 'Common Data Service Connection Setup', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';
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
                Caption = 'Connection from Dynamics 365 Business Central to the Common Data Service environment';
                field("Server Address"; "Server Address")
                {
                    ApplicationArea = Suite;
                    Enabled = IsEditable;
                    Editable = IsEditable;
                    ToolTip = 'Specifies the URL of the Common Data Service environment that you want to connect to.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';
                    AssistEdit = true;

                    trigger OnValidate()
                    begin
                        if "Server Address" <> xRec."Server Address" then
                            InitializeDefaultBusinessUnit();
                    end;

                    trigger OnAssistEdit()
                    var
                        AuthenticationType: Option Office365,AD,IFD,OAuth;
                    begin
                        AuthenticationType := "Authentication Type";
                        GetCDSEnvironment();

                        if "Server Address" <> xRec."Server Address" then
                            InitializeDefaultBusinessUnit();

                        Validate("Authentication Type", AuthenticationType);

                        CurrPage.Update();
                    end;
                }
                field("User Name"; "User Name")
                {
                    ApplicationArea = Suite;
                    Editable = IsEditable;
                    ToolTip = 'Specifies the name of the user that will be used to connect to the Common Data Service environment and synchronize data. This must not be the administrator user account.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';
                }
                field(Password; UserPassword)
                {
                    ApplicationArea = Suite;
                    Editable = IsEditable;
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the password of the user that will be used to connect to the Common Data ServiceS environment and synchronize data.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';

                    trigger OnValidate()
                    begin
                        if not IsTemporary() then
                            if (UserPassword <> '') and (not EncryptionEnabled()) then
                                if Confirm(EncryptionIsNotActivatedQst) then
                                    PAGE.RunModal(PAGE::"Data Encryption Management");
                        SetPassword(UserPassword);
                    end;
                }
                field("SDK Version"; "Proxy Version")
                {
                    ApplicationArea = Suite;
                    AssistEdit = true;
                    Caption = 'SDK Version';
                    Visible = not SoftwareAsAService;
                    Editable = false;
                    Enabled = IsEditable;
                    ToolTip = 'Specifies the software development kit version that is used to connect to the Common Data Service environment.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';

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
                    Caption = 'Enabled', Comment = 'Name of the check box that shows whether the connection to the Common Data Service environment is enabled.';
                    ToolTip = 'Specifies whether the connection to the Common Data Service environment is enabled.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';

                    trigger OnValidate()
                    var
                        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
                    begin
                        RefreshStatuses := true;
                        CurrPage.Update(true);
                        if ("Is Enabled") and ("Ownership Model" = "Ownership Model"::Person) then
                            if Confirm(DoYouWantToMakeSalesPeopleMappingQst, true) then
                                CDSSetupDefaults.RunCoupleSalespeoplePage();
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
                    Caption = 'Common Data Service Version';
                    Editable = false;
                    StyleExpr = CDSVersionStatusStyleExpr;
                    ToolTip = 'Specifies the version of the Common Data Service.';

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
		    ToolTip = 'Specifies whether an integration solution is installed and configured in Common Data Service. You cannot change this setting.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';

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
                    ToolTip = 'Specifies whether the integration user has the required roles in Common Data Service. You cannot change this setting.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';

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
                    ToolTip = 'Specifies whether the team that owns the selected business unit has the required roles in Common Data Service. You cannot change this setting.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';

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
                    ToolTip = 'Specifies whether the entities are available in Common Data Service. You cannot change this setting.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';

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
                    ToolTip = 'Specifies the authentication type that will be used to authenticate with the Common Data Service environment.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';
                }
                field("Connection String"; "Connection String")
                {
                    ApplicationArea = Advanced;
                    Caption = 'Connection String';
                    Editable = IsEditable;
                    ToolTip = 'Specifies the connection string that will be used to connect to the Common Data Service environment.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';

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
                    ToolTip = 'Specifies the type of owner that will be assigned to any record that is created while synchronizing from Business Central to Common Data Service.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';

                    trigger OnValidate()
                    begin
                        IsBusinessUnitEditable := "Ownership Model" = "Ownership Model"::Team;
                        if not IsBusinessUnitEditable then
                            InitializeDefaultBusinessUnit();
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
                    Enabled = IsEditable and IsBusinessUnitEditable;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the business unit that you want to connect to in the Common Data Service environment.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';

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
            usercontrol(OAuthIntegration; OAuthControlAddIn)
            {
                ApplicationArea = Basic, Suite;
                trigger AuthorizationCodeRetrieved(code: Text)
                var
                    CDSEnvironment: Codeunit "CDS Environment";
                    Token: Text;
                begin
                    Token := CDSDiscoverabilityOauth.CompleteAuthorizationProcess(code, Rec);
                    SendTraceTag('0000BFC', GlobalDiscoOauthCategoryLbl, Verbosity::Normal, OauthCodeRetrievedMsg, DataClassification::SystemMetadata);

                    CDSEnvironment.SelectTenantEnvironment(Rec, Token, true);
                end;

                trigger AuthorizationErrorOccurred(error: Text; desc: Text);
                begin
                    SendTraceTag('0000BFD', GlobalDiscoOauthCategoryLbl, Verbosity::Error, StrSubstNo(OauthFailErrMsg, error, desc), DataClassification::SystemMetadata);
                end;

                trigger ControlAddInReady();
                begin
                    OAuthAddinReady := true;
                end;
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
                ToolTip = 'Runs Common Data Service Connection Setup Wizard.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';

                trigger OnAction()
                var
                    AssistedSetup: Codeunit "Assisted Setup";
                begin
                    Commit(); // Make sure all data is committed before we run the wizard
                    AssistedSetup.Run(Page::"CDS Connection Setup Wizard");
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
                ToolTip = 'Test the connection to Common Data Service using the specified settings.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';

                trigger OnAction()
                begin
                    if CDSIntegrationImpl.TestConnection(Rec) then
                        Message(ConnectionSuccessMsg)
                    else
                        Message(ConnectionFailedMsg, GetLastErrorText());
                end;
            }
            action(ResetConfiguration)
            {
                ApplicationArea = Suite;
                Caption = 'Use Default Synchronization Setup';
                Enabled = "Is Enabled";
                Image = ResetStatus;
                ToolTip = 'Resets the integration table mappings and synchronization jobs to the default values for a connection with Common Data Service. All current mappings are deleted.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';

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
                ToolTip = 'Open the list of users in Common Data Service to manually couple them with salespersons in Business Central.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';

                trigger OnAction()
                var
                    CRMSystemuserList: Page "CRM Systemuser List";
                begin
                    CRMSystemuserList.Initialize(true);
                    CRMSystemuserList.Run();
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
                ToolTip = 'Start all the default integration jobs for synchronizing Business Central record types and Common Data Service entities, as defined on the Integration Table Mappings page.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';

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
                    Message(SyncNowSuccessMsg, IntegrationSynchJobList.Caption());
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
                    CDSIntegrationImpl.ImportAndConfigureIntegrationSolution(Rec, true);

                    if CDSIntegrationImpl.CheckIntegrationRequirements(Rec, true) then
                        Message(DeploySucceedMsg)
                    else
                        Message(DeployFailedMsg);
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
                ToolTip = 'View the integration solutions that help business apps synchronize data with Business Central through Common Data Service.';

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
                ToolTip = 'View the roles assigned to the integration user. The integration user is the user account in Common Data Service that business apps use to synchronize data with Business Central through Common Data Service.';

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
                ToolTip = 'View the roles assigned to the team in Common Data Service that owns the coupled entities. This requires that you are using the Team ownership model.';

                trigger OnAction()
                begin
                    CDSIntegrationImpl.CheckConnectionRequiredFields(Rec, false);
                    Page.RunModal(PAGE::"CDS Owning Team Roles");
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
                ToolTip = 'View the job queue entries that manage the scheduled synchronization between Common Data Service and Business Central.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';

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
        EnvironmentInfo: Codeunit "Environment Information";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        ApplicationAreaMgmtFacade.CheckAppAreaOnlyBasic();
        SoftwareAsAService := EnvironmentInfo.IsSaaS();
        CDSIntegrationImpl.RegisterAssistedSetup();
        SolutionKey := CDSIntegrationImpl.GetBaseSolutionUniqueName();
        SolutionName := CDSIntegrationImpl.GetBaseSolutionDisplayName();
        DefaultBusinessUnitName := CDSIntegrationImpl.GetDefaultBusinessUnitName();
        RefreshStatuses := true;
    end;

    trigger OnOpenPage()
    begin
        if not Get() then begin
            Init();
            InitializeDefaultProxyVersion();
            InitializeDefaultOwnershipModel();
            InitializeDefaultBusinessUnit();
            Insert();
            LoadConnectionStringElementsFromCRMConnectionSetup();
        end else begin
            UserPassword := GetPassword();
            if (not IsValidProxyVersion()) or (not IsValidOwnershipModel() or (not IsValidBusinessUnit())) then begin
                CDSIntegrationImpl.UnregisterConnection();
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
        CDSDiscoverabilityOauth: Codeunit "CDS Discoverability Oauth";
        SolutionKey: Text;
        SolutionName: Text;
        DefaultBusinessUnitName: Text;
        UserPassword: Text;
        ResetIntegrationTableMappingConfirmQst: Label 'This will delete all existing integration table mappings and Common Data Service synchronization jobs and install the default integration table mappings and jobs for Common Data Service synchronization.\\Are you sure that you want to continue?';
        EncryptionIsNotActivatedQst: Label 'Data encryption is currently not enabled. We recommend that you encrypt data. \Do you want to open the Data Encryption Management window?';
        EnableServiceQst: Label 'The %1 is not enabled. Are you sure you want to exit?', Comment = '%1 = This Page Caption (Common Data Service Connection Setup)';
        UnfavorableCDSVersionMsg: Label 'This version of Common Data Service might not work correctly with the base integration solution. We recommend you upgrade to a supported version.';
        FavorableCDSVersionMsg: Label 'The version of Common Data Service is valid.';
        UnfavorableSolutionMsg: Label 'The base integration solution was not detected in Common Data Service.';
        FavorableSolutionMsg: Label 'The base integration solution is installed in Common Data Service.';
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
        GlobalDiscoOauthCategoryLbl: Label 'Global Discoverability OAuth', Locked = true;
        OauthFailErrMsg: Label 'Error: %1 ; Description: %2.', Comment = '%1 = OAuth error message ; %2 = description of OAuth failure error message';
        OauthCodeRetrievedMsg: Label 'OAuth authorization code retrieved.';
        SynchronizeModifiedQst: Label 'This will synchronize all modified records in all Integration Table Mappings.\\Do you want to continue?';
        SyncNowSuccessMsg: Label 'Synchronize Modified Records completed.\Open %1 window for details.', Comment = '%1 = The localized caption of page Integration Synch. Job List';
        SetupSuccessfulMsg: Label 'The default setup for Common Data Service synchronization has completed successfully.';
        DoYouWantToMakeSalesPeopleMappingQst: Label 'Do you want to map salespeople to users in Common Data Service?';
        IsBusinessUnitEditable: Boolean;
        OAuthAddinReady: Boolean;
        IsEditable: Boolean;
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

    [NonDebuggable]
    local procedure GetCDSEnvironment()
    var
        CDSEnvironment: Codeunit "CDS Environment";
        AuthRequestUrl: Text;
        Token: Text;
    begin
        Token := CDSEnvironment.GetOnBehalfAuthorizationToken();
        if CDSEnvironment.SelectTenantEnvironment(Rec, Token, true) = true then
            exit;

        if OAuthAddinReady then begin
            AuthRequestUrl := CDSDiscoverabilityOauth.StartAuthorizationProcess();

            if AuthRequestUrl <> '' then
                CurrPage.OAuthIntegration.StartAuthorization(AuthRequestUrl);
        end;
    end;

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
        IsBusinessUnitEditable := "Ownership Model" = "Ownership Model"::Team;
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
          StrSubstNo('%1', CODEUNIT::"Integration Synch. Job Runner"));
    end;
}
