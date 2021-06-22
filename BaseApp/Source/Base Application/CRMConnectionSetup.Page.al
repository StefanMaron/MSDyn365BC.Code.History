page 5330 "CRM Connection Setup"
{
    AccessByPermission = TableData "CRM Connection Setup" = IM;
    ApplicationArea = Suite;
    Caption = 'Microsoft Dynamics 365 Connection Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PromotedActionCategories = 'New,Connection,Mapping,Synchronization,Encryption';
    ShowFilter = false;
    SourceTable = "CRM Connection Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(NAVToCRM)
            {
                Caption = 'Connection from Dynamics 365 Business Central to Dynamics 365 Sales';
                field("Server Address"; "Server Address")
                {
                    ApplicationArea = Suite;
                    Editable = IsEditable;
                    ToolTip = 'Specifies the URL of the Dynamics 365 Sales server that hosts the Dynamics 365 Sales solution that you want to connect to.';

                    trigger OnValidate()
                    begin
                        ConnectionString := GetConnectionString;
                    end;
                }
                field("User Name"; "User Name")
                {
                    ApplicationArea = Suite;
                    Editable = IsEditable;
                    ToolTip = 'Specifies the user name of a Dynamics 365 Sales account.';

                    trigger OnValidate()
                    begin
                        ConnectionString := GetConnectionString;
                    end;
                }
                field(Password; CRMPassword)
                {
                    ApplicationArea = Suite;
                    Enabled = IsEditable;
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the password of a Dynamics 365 Sales user account.';

                    trigger OnValidate()
                    begin
                        if (CRMPassword <> '') and (not EncryptionEnabled) then
                            if Confirm(EncryptionIsNotActivatedQst) then
                                PAGE.RunModal(PAGE::"Data Encryption Management");
                        SetPassword(CRMPassword);
                    end;
                }
                field("Is Enabled"; "Is Enabled")
                {
                    ApplicationArea = Suite;
                    Caption = 'Enabled', Comment = 'Name of tickbox which shows whether the connection is enabled or disabled';
                    ToolTip = 'Specifies if the connection to Dynamics 365 Sales is enabled.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(ScheduledSynchJobsActive; ScheduledSynchJobsRunning)
                {
                    ApplicationArea = Suite;
                    Caption = 'Active scheduled synchronization jobs';
                    Editable = false;
                    StyleExpr = ScheduledSynchJobsRunningStyleExpr;
                    ToolTip = 'Specifies how many of the default integration synchronization job queue entries ready to automatically synchronize data between Dynamics 365 and Dynamics 365 Sales.';

                    trigger OnDrillDown()
                    var
                        ScheduledSynchJobsRunningMsg: Text;
                    begin
                        if TotalJobs = 0 then
                            ScheduledSynchJobsRunningMsg := JobQueueIsNotRunningMsg
                        else
                            if ActiveJobs = TotalJobs then
                                ScheduledSynchJobsRunningMsg := AllScheduledJobsAreRunningMsg
                            else
                                ScheduledSynchJobsRunningMsg := StrSubstNo(PartialScheduledJobsAreRunningMsg, ActiveJobs, TotalJobs);
                        Message(ScheduledSynchJobsRunningMsg);
                    end;
                }
                field(SDKVersion; "Proxy Version")
                {
                    ApplicationArea = Suite;
                    AssistEdit = true;
                    Caption = 'Dynamics 365 SDK Version';
                    Editable = false;
                    Enabled = IsEditable;
                    ToolTip = 'Specifies the Microsoft Dynamics 365 (CRM) software development kit version that is used to connect to Dynamics 365 Sales.';

                    trigger OnAssistEdit()
                    var
                        TempStack: Record TempStack temporary;
                    begin
                        if PAGE.RunModal(PAGE::"SDK Version List", TempStack) = ACTION::LookupOK then begin
                            Validate("Proxy Version", TempStack.StackOrder);
                            ConnectionString := GetConnectionString;
                            CurrPage.Update(true);
                        end;
                    end;
                }
            }
            group(CRMToNAV)
            {
                Caption = 'Connection from Dynamics 365 Sales to Dynamics 365 Business Central';
                Visible = "Is Enabled";
                field(NAVURL; "Dynamics NAV URL")
                {
                    ApplicationArea = Suite;
                    Caption = 'Dynamics 365 Business Central Web Client URL';
                    Enabled = "Is CRM Solution Installed";
                    ToolTip = 'Specifies the URL to the Business Central web client. From records in Dynamics 365 Sales, such as an account or product, users can open a corresponding (coupled) record in Business Central. Set this field to the URL of the Business Central web client instance to use.';
                }
                field(ItemAvailabilityWebServEnabled; WebServiceEnabled)
                {
                    ApplicationArea = Suite;
                    Caption = 'Item Availability Web Service Enabled';
                    Editable = false;
                    StyleExpr = WebServiceEnabledStyleExpr;
                    ToolTip = 'Specifies that the Item Availability web service for Business Central is enabled.';

                    trigger OnDrillDown()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        if WebServiceEnabled then
                            CRMIntegrationManagement.UnPublishOnWebService(Rec)
                        else
                            CRMIntegrationManagement.PublishWebService(Rec);
                        CurrPage.Update(true);
                    end;
                }
                label(Control34)
                {
                    ApplicationArea = Suite;
                    ShowCaption = false;
                    Caption = '';
                }
                field(NAVODataURL; "Dynamics NAV OData URL")
                {
                    ApplicationArea = Suite;
                    Caption = 'Dynamics 365 Business Central OData Web Service URL';
                    Enabled = "Is CRM Solution Installed";
                    ToolTip = 'Specifies the URL of Business Central OData web services. From sales order records in Dynamics 365 Sales, users can retrieve item availability information for items in Business Central that are coupled to sales order detail records in Dynamics 365 Sales. Set this field to the URL of the Business Central OData web services to use.';
                }
                field(NAVODataUsername; "Dynamics NAV OData Username")
                {
                    ApplicationArea = Suite;
                    Caption = 'Dynamics 365 Business Central OData Web Service Username';
                    Enabled = "Is CRM Solution Installed";
                    Lookup = true;
                    LookupPageID = Users;
                    ToolTip = 'Specifies the user name to access Dynamics 365 OData web services.';
                }
                field(NAVODataAccesskey; "Dynamics NAV OData Accesskey")
                {
                    ApplicationArea = Suite;
                    Caption = 'Dynamics 365 Business Central OData Web Service Accesskey';
                    Editable = false;
                    Enabled = "Is CRM Solution Installed";
                    ToolTip = 'Specifies the access key to access Dynamics 365 OData web services.';
                }
            }
            group(CRMSettings)
            {
                Caption = 'Dynamics 365 Sales Settings';
                Visible = "Is Enabled";
                field("CRM Version"; "CRM Version")
                {
                    ApplicationArea = Suite;
                    Caption = 'Version';
                    Editable = false;
                    StyleExpr = CRMVersionStyleExpr;
                    ToolTip = 'Specifies the version of Dynamics 365 Sales.';

                    trigger OnDrillDown()
                    begin
                        if IsVersionValid then
                            Message(FavorableCRMVersionMsg, CRMProductName.SHORT)
                        else
                            Message(UnfavorableCRMVersionMsg, PRODUCTNAME.Short, CRMProductName.SHORT);
                    end;
                }
                field("Is CRM Solution Installed"; "Is CRM Solution Installed")
                {
                    ApplicationArea = Suite;
                    Caption = 'Dynamics 365 Business Central Integration Solution Imported';
                    Editable = false;
                    StyleExpr = CRMSolutionInstalledStyleExpr;
                    ToolTip = 'Specifies if the Integration Solution is installed and configured in Dynamics 365 Sales. You cannot change this setting.';

                    trigger OnDrillDown()
                    begin
                        if "Is CRM Solution Installed" then
                            Message(FavorableCRMSolutionInstalledMsg, PRODUCTNAME.Short, CRMProductName.SHORT)
                        else
                            Message(UnfavorableCRMSolutionInstalledMsg, PRODUCTNAME.Short);
                    end;
                }
                field("Is S.Order Integration Enabled"; "Is S.Order Integration Enabled")
                {
                    ApplicationArea = Suite;
                    Caption = 'Sales Order Integration Enabled';
                    ToolTip = 'Specifies that it is possible for Dynamics 365 Sales users to submit sales orders that can then be viewed and imported in Dynamics 365.';

                    trigger OnValidate()
                    begin
                        SetAutoCreateSalesOrdersEditable;
                    end;
                }
                field("Auto Create Sales Orders"; "Auto Create Sales Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Automatically Create Sales Orders';
                    Editable = IsAutoCreateSalesOrdersEditable;
                    ToolTip = 'Specifies that sales orders will be created automatically from sales orders that are submitted in Dynamics 365 Sales.';
                }
                field("Auto Process Sales Quotes"; "Auto Process Sales Quotes")
                {
                    ApplicationArea = Suite;
                    Caption = 'Automatically Process Sales Quotes';
                    ToolTip = 'Specifies that sales quotes will be automatically processed on sales quotes creation/revision/winning submitted in Dynamics 365 Sales quotes entities.';
                }
            }
            group(AdvancedSettings)
            {
                Caption = 'Advanced Settings';
                Visible = "Is Enabled";
                field("Is User Mapping Required"; "Is User Mapping Required")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that Dynamics 365 users must have a matching user account in Dynamics 365 Sales to have Dynamics 365 Sales integration capabilities in the user interface.';

                    trigger OnValidate()
                    begin
                        UpdateIsEnabledState;
                        SetStyleExpr;
                    end;
                }
                field("Is User Mapped To CRM User"; "Is User Mapped To CRM User")
                {
                    ApplicationArea = Suite;
                    Caption = 'Current Business Central User is Mapped to a Dynamics 365 Sales User';
                    Editable = false;
                    StyleExpr = UserMappedToCRMUserStyleExpr;
                    ToolTip = 'Specifies that the user account that you used to sign in with has a matching user account in Dynamics 365 Sales.';
                    Visible = "Is User Mapping Required";

                    trigger OnDrillDown()
                    begin
                        if "Is User Mapped To CRM User" then
                            Message(CurrentuserIsMappedToCRMUserMsg, UserId, PRODUCTNAME.Short, CRMProductName.SHORT)
                        else
                            Message(CurrentuserIsNotMappedToCRMUserMsg, UserId, PRODUCTNAME.Short, CRMProductName.SHORT);
                    end;
                }
                field("Use Newest UI"; "Use Newest UI")
                {
                    ApplicationArea = Suite;
                    Caption = 'Open Coupled Entities in Dynamics 365 Sales Hub';
                    ToolTip = 'Specifies that coupled Dynamics 365 Sales entities should open in Sales Hub.';
                }
                label(Control30)
                {
                    ApplicationArea = Suite;
                    ShowCaption = false;
                    Caption = '';
                }
            }
            group(AuthTypeDetails)
            {
                Caption = 'Authentication Type Details';
                Visible = NOT SoftwareAsAService;
                field("Authentication Type"; "Authentication Type")
                {
                    ApplicationArea = Advanced;
                    Editable = NOT "Is Enabled";
                    ToolTip = 'Specifies the authentication type that will be used to authenticate with Dynamics 365 Sales';

                    trigger OnValidate()
                    begin
                        SetIsConnectionStringEditable;
                        ConnectionString := GetConnectionString;
                    end;
                }
                field(Domain; Domain)
                {
                    ApplicationArea = Advanced;
                    ToolTip = 'Specifies the domain name of your Dynamics 365 Sales deployment.';
                }
                field("Connection String"; ConnectionString)
                {
                    ApplicationArea = Advanced;
                    Caption = 'Connection String';
                    Editable = IsConnectionStringEditable;
                    ToolTip = 'Specifies the connection string that will be used to connect to Dynamics 365 Sales';

                    trigger OnValidate()
                    begin
                        SetConnectionString(ConnectionString);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Assisted Setup")
            {
                ApplicationArea = Suite;
                Caption = 'Assisted Setup';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Runs Dynamics 365 Connection Setup Wizard.';

                trigger OnAction()
                var
                    AssistedSetup: Codeunit "Assisted Setup";
                begin
                    AssistedSetup.Run(Page::"CRM Connection Setup Wizard");
                    CurrPage.Update(false);
                end;
            }
            action("Test Connection")
            {
                ApplicationArea = Suite;
                Caption = 'Test Connection', Comment = 'Test is a verb.';
                Image = ValidateEmailLoggingSetup;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Tests the connection to Dynamics 365 Sales using the specified settings.';

                trigger OnAction()
                begin
                    PerformTestConnection;
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
                ToolTip = 'Opens the integration table mapping list.';

                trigger OnAction()
                begin
                    Page.Run(Page::"Integration Table Mapping List");
                end;
            }
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
                    DeployCRMSolution(true);
                end;
            }
            action(ResetConfiguration)
            {
                ApplicationArea = Suite;
                Caption = 'Use Default Synchronization Setup';
                Enabled = "Is Enabled";
                Image = ResetStatus;
                ToolTip = 'Resets the integration table mappings and synchronization jobs to the default values for a connection with Dynamics 365 Sales. All current mappings are deleted.';

                trigger OnAction()
                var
                    CRMSetupDefaults: Codeunit "CRM Setup Defaults";
                begin
                    EnsureCDSConnectionIsEnabled();
                    if Confirm(ResetIntegrationTableMappingConfirmQst, false, CRMProductName.SHORT) then begin
                        CRMSetupDefaults.ResetConfiguration(Rec);
                        Message(SetupSuccessfulMsg, CRMProductName.SHORT);
                    end;
                    RefreshDataFromCRM;
                end;
            }
            action(CoupleUsers)
            {
                ApplicationArea = Suite;
                Caption = 'Couple Salespersons';
                Image = CoupledUsers;
                Promoted = true;
                PromotedCategory = "Report";
                ToolTip = 'Open the list of users in Dynamics 365 Sales for manual coupling to salespersons in Business Central.';

                trigger OnAction()
                var
                    CRMSystemuserList: Page "CRM Systemuser List";
                begin
                    CRMSystemuserList.Initialize(true);
                    CRMSystemuserList.Run;
                end;
            }
            action(StartInitialSynchAction)
            {
                ApplicationArea = Suite;
                Caption = 'Run Full Synchronization';
                Enabled = "Is Enabled For User";
                Image = RefreshLines;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                ToolTip = 'Start all the default integration jobs for synchronizing Business Central record types and Dynamics 365 Sales entities, as defined on the Integration Table Mappings page.';

                trigger OnAction()
                begin
                    PAGE.Run(PAGE::"CRM Full Synch. Review");
                end;
            }
            action("Reset Web Client URL")
            {
                ApplicationArea = Suite;
                Caption = 'Reset Web Client URL';
                Enabled = IsWebCliResetEnabled;
                Image = ResetStatus;
                ToolTip = 'Undo your change and enter the default URL in the Business Central web Client URL field.';

                trigger OnAction()
                begin
                    PerformWebClientUrlReset;
                    Message(WebClientUrlResetMsg, PRODUCTNAME.Short);
                end;
            }
            action(SynchronizeNow)
            {
                ApplicationArea = Suite;
                Caption = 'Synchronize Modified Records';
                Enabled = "Is Enabled For User";
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                ToolTip = 'Synchronize records that have been modified since the last time they were synchronized.';

                trigger OnAction()
                var
                    IntegrationSynchJobList: Page "Integration Synch. Job List";
                begin
                    if not Confirm(SynchronizeModifiedQst) then
                        exit;

                    SynchronizeNow(false);
                    Message(SyncNowSuccessMsg, IntegrationSynchJobList.Caption);
                end;
            }
            action("Generate Integration IDs")
            {
                ApplicationArea = Suite;
                Caption = 'Generate Integration IDs';
                Image = Reconcile;
                ToolTip = 'Create integration IDs for new records that were added while the connection was disabled, for example, after you re-enable a Dynamics 365 Sales connection.';

                trigger OnAction()
                var
                    IntegrationManagement: Codeunit "Integration Management";
                begin
                    if Confirm(ConfirmGenerateIntegrationIdsQst, true) then begin
                        IntegrationManagement.SetupIntegrationTables;
                        Message(GenerateIntegrationIdsSuccessMsg);
                    end;
                end;
            }
        }
        area(navigation)
        {
            action("Integration Table Mappings")
            {
                ApplicationArea = Suite;
                Caption = 'Integration Table Mappings';
                Image = Relationship;
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Page "Integration Table Mapping List";
                RunPageMode = Edit;
                ToolTip = 'View entries that map integration tables to business data tables in Business Central. Integration tables are set up to act as interfaces for synchronizing data between an external database table, such as Dynamics 365 Sales, and a corresponding business data table in Business Central.';
            }
            action("Synch. Job Queue Entries")
            {
                ApplicationArea = Suite;
                Caption = 'Synch. Job Queue Entries';
                Image = JobListSetup;
                Promoted = true;
                PromotedCategory = Category4;
                ToolTip = 'View the job queue entries that manage the scheduled synchronization between Dynamics 365 Sales and Business Central.';

                trigger OnAction()
                var
                    JobQueueEntry: Record "Job Queue Entry";
                begin
                    JobQueueEntry.FilterGroup := 2;
                    JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
                    JobQueueEntry.SetFilter("Object ID to Run", GetJobQueueEntriesObjectIDToRunFilter);
                    JobQueueEntry.FilterGroup := 0;

                    PAGE.Run(PAGE::"Job Queue Entries", JobQueueEntry);
                end;
            }
            action(SkippedSynchRecords)
            {
                ApplicationArea = Suite;
                Caption = 'Skipped Synch. Records';
                Enabled = "Is Enabled";
                Image = NegativeLines;
                Promoted = true;
                PromotedCategory = Category4;
                RunObject = Page "CRM Skipped Records";
                RunPageMode = View;
                ToolTip = 'View the list of records that will be skipped for synchronization.';
            }
            action(EncryptionManagement)
            {
                ApplicationArea = Advanced;
                Caption = 'Encryption Management';
                Image = EncryptionKeys;
                Promoted = true;
                PromotedCategory = Category5;
                PromotedIsBig = true;
                RunObject = Page "Data Encryption Management";
                RunPageMode = View;
                ToolTip = 'Enable or disable data encryption. Data encryption helps make sure that unauthorized users cannot read business data.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        RefreshData;
    end;

    trigger OnInit()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        ApplicationAreaMgmtFacade.CheckAppAreaOnlyBasic;
        SoftwareAsAService := EnvironmentInfo.IsSaaS;
        CRMIntegrationManagement.RegisterAssistedSetup();
    end;

    trigger OnOpenPage()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        EnsureCDSConnectionIsEnabled();

        if not Get then begin
            Init;
            InitializeDefaultProxyVersion;
            Insert;
            LoadConnectionStringElementsFromCDSConnectionSetup();
            UpdateConnectionString();
        end else begin
            CRMPassword := GetPassword();
            if not "Is Enabled" then begin
                LoadConnectionStringElementsFromCDSConnectionSetup();
                UpdateConnectionString();
            end;
            ConnectionString := GetConnectionString;
            UnregisterConnection;
            if "Proxy Version" = 0 then begin
                InitializeDefaultProxyVersion;
                Modify;
            end;
            if "Is Enabled" then
                RegisterUserConnection
            else
                if "Disable Reason" <> '' then
                    CRMIntegrationManagement.SendConnectionDisabledNotification("Disable Reason");
        end;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not "Is Enabled" then
            if not Confirm(StrSubstNo(EnableServiceQst, CurrPage.Caption), true) then
                exit(false);
    end;

    var
        CRMProductName: Codeunit "CRM Product Name";
        CRMPassword: Text;
        ResetIntegrationTableMappingConfirmQst: Label 'This will delete all existing integration table mappings and %1 synchronization jobs and install the default integration table mappings and jobs for %1 synchronization.\\Are you sure that you want to continue?', Comment = '%1 = CRM product name';
        ConfirmGenerateIntegrationIdsQst: Label 'You are about to add integration data to tables. This process may take several minutes. Do you want to continue?';
        GenerateIntegrationIdsSuccessMsg: Label 'The integration data has been added to the tables.';
        EncryptionIsNotActivatedQst: Label 'Data encryption is currently not enabled. We recommend that you encrypt data. \Do you want to open the Data Encryption Management window?';
        WebClientUrlResetMsg: Label 'The %1 Web Client URL has been reset to the default value.', Comment = '%1 - product name';
        SyncNowSuccessMsg: Label 'Synchronize Modified Records completed.\See the %1 window for details.', Comment = '%1 = Page 5338 Caption';
        UnfavorableCRMVersionMsg: Label 'This version of %2 might not work correctly with %1. We recommend you upgrade to a supported version.', Comment = '%1 - product name, %2 = CRM product name';
        FavorableCRMVersionMsg: Label 'The version of %1 is valid.', Comment = '%1 = CRM product name';
        UnfavorableCRMSolutionInstalledMsg: Label 'The %1 Integration Solution was not detected.', Comment = '%1 - product name';
        FavorableCRMSolutionInstalledMsg: Label 'The %1 Integration Solution is installed in %2.', Comment = '%1 - product name, %2 = CRM product name';
        SynchronizeModifiedQst: Label 'This will synchronize all modified records in all Integration Table Mappings.\\Do you want to continue?';
        ReadyScheduledSynchJobsTok: Label '%1 of %2', Comment = '%1 = Count of scheduled job queue entries in ready or in process state, %2 count of all scheduled jobs';
        ScheduledSynchJobsRunning: Text;
        CurrentuserIsMappedToCRMUserMsg: Label '%2 user (%1) is mapped to a %3 user.', Comment = '%1 = Current User ID, %2 - product name, %3 = CRM product name';
        CurrentuserIsNotMappedToCRMUserMsg: Label 'Because the %2 Users Must Map to %3 Users field is set, %3 integration is not enabled for %1.\\To enable %3 integration for %2 user %1, the authentication email must match the primary email of a %3 user.', Comment = '%1 = Current User ID, %2 - product name, %3 = CRM product name';
        EnableServiceQst: Label 'The %1 is not enabled. Are you sure you want to exit?', Comment = '%1 = This Page Caption (Microsoft Dynamics 365 Connection Setup)';
        PartialScheduledJobsAreRunningMsg: Label 'An active job queue is available but only %1 of the %2 scheduled synchronization jobs are ready or in process.', Comment = '%1 = Count of scheduled job queue entries in ready or in process state, %2 count of all scheduled jobs';
        JobQueueIsNotRunningMsg: Label 'There is no job queue started. Scheduled synchronization jobs require an active job queue to process jobs.\\Contact your administrator to get a job queue configured and started.';
        AllScheduledJobsAreRunningMsg: Label 'An job queue is started and all scheduled synchronization jobs are ready or already processing.';
        SetupSuccessfulMsg: Label 'The default setup for %1 synchronization has completed successfully.', Comment = '%1 = CRM product name';
        ScheduledSynchJobsRunningStyleExpr: Text;
        CRMSolutionInstalledStyleExpr: Text;
        CRMVersionStyleExpr: Text;
        UserMappedToCRMUserStyleExpr: Text;
        ConnectionString: Text;
        WebServiceEnabledStyleExpr: Text;
        ActiveJobs: Integer;
        TotalJobs: Integer;
        IsEditable: Boolean;
        IsWebCliResetEnabled: Boolean;
        SoftwareAsAService: Boolean;
        IsConnectionStringEditable: Boolean;
        IsAutoCreateSalesOrdersEditable: Boolean;
        WebServiceEnabled: Boolean;

    local procedure RefreshData()
    begin
        UpdateIsEnabledState;
        SetIsConnectionStringEditable;
        RefreshDataFromCRM;
        SetAutoCreateSalesOrdersEditable;
        RefreshSynchJobsData;
        UpdateEnableFlags;
        if not WebServiceEnabled then
            Clear("Dynamics NAV OData URL");
        SetStyleExpr;
    end;

    local procedure RefreshSynchJobsData()
    begin
        CountCRMJobQueueEntries(ActiveJobs, TotalJobs);
        ScheduledSynchJobsRunning := StrSubstNo(ReadyScheduledSynchJobsTok, ActiveJobs, TotalJobs);
        ScheduledSynchJobsRunningStyleExpr := GetRunningJobsStyleExpr;
    end;

    local procedure SetStyleExpr()
    begin
        CRMSolutionInstalledStyleExpr := GetStyleExpr("Is CRM Solution Installed");
        CRMVersionStyleExpr := GetStyleExpr(IsVersionValid);
        UserMappedToCRMUserStyleExpr := GetStyleExpr("Is User Mapped To CRM User");
        WebServiceEnabledStyleExpr := GetStyleExpr(WebServiceEnabled);
    end;

    local procedure SetIsConnectionStringEditable()
    begin
        IsConnectionStringEditable :=
          not "Is Enabled";
    end;

    local procedure SetAutoCreateSalesOrdersEditable()
    begin
        IsAutoCreateSalesOrdersEditable := "Is S.Order Integration Enabled";
    end;

    local procedure GetRunningJobsStyleExpr() StyleExpr: Text
    begin
        if ActiveJobs < TotalJobs then
            StyleExpr := 'Ambiguous'
        else
            StyleExpr := GetStyleExpr((ActiveJobs = TotalJobs) and (TotalJobs <> 0))
    end;

    local procedure GetStyleExpr(Favorable: Boolean) StyleExpr: Text
    begin
        if Favorable then
            StyleExpr := 'Favorable'
        else
            StyleExpr := 'Unfavorable'
    end;

    local procedure UpdateEnableFlags()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
    begin
        IsEditable := not "Is Enabled" and not CDSIntegrationImpl.IsIntegrationEnabled();
        IsWebCliResetEnabled := "Is CRM Solution Installed" and "Is Enabled For User";
        WebServiceEnabled := CRMIntegrationManagement.IsItemAvailabilityWebServiceEnabled;
    end;

    local procedure InitializeDefaultProxyVersion()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        Validate("Proxy Version", CRMIntegrationManagement.GetLastProxyVersionItem);
    end;
}

