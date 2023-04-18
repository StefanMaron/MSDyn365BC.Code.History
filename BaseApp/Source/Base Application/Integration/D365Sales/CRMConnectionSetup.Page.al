page 5330 "CRM Connection Setup"
{
    AccessByPermission = TableData "CRM Connection Setup" = IM;
    ApplicationArea = Suite;
    Caption = 'Microsoft Dynamics 365 Connection Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
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
                field("Server Address"; Rec."Server Address")
                {
                    ApplicationArea = Suite;
                    Editable = IsEditable;
                    ToolTip = 'Specifies the URL of the Dynamics 365 Sales server that hosts the Dynamics 365 Sales solution that you want to connect to.';

                    trigger OnValidate()
                    begin
                        ConnectionString := GetConnectionString();
                    end;
                }
                field("User Name"; Rec."User Name")
                {
                    ApplicationArea = Suite;
                    Editable = IsEditable;
                    Visible = IsUserNamePasswordVisible;
                    ToolTip = 'Specifies the user name of a Dynamics 365 Sales account.';

                    trigger OnValidate()
                    begin
                        ConnectionString := GetConnectionString();
                    end;
                }
                field(Password; CRMPassword)
                {
                    ApplicationArea = Suite;
                    Enabled = IsEditable;
                    ExtendedDatatype = Masked;
                    Visible = IsUserNamePasswordVisible;
                    ToolTip = 'Specifies the password of a Dynamics 365 Sales user account.';

                    trigger OnValidate()
                    begin
                        if (CRMPassword <> '') and (not EncryptionEnabled()) then
                            if Confirm(EncryptionIsNotActivatedQst) then
                                PAGE.RunModal(PAGE::"Data Encryption Management");
                        SetPassword(CRMPassword);
                    end;
                }
                field("Is Enabled"; Rec."Is Enabled")
                {
                    ApplicationArea = Suite;
                    Caption = 'Enabled', Comment = 'Name of tickbox which shows whether the connection is enabled or disabled';
                    ToolTip = 'Specifies if the connection to Dynamics 365 Sales is enabled. When you check this checkbox, you will be prompted to sign-in to Dataverse with an administrator user account. The account will be used one time to give consent to, install and configure applications and components that the integration requires.';

                    trigger OnValidate()
                    var
                        FeatureTelemetry: Codeunit "Feature Telemetry";
                    begin
                        CurrPage.Update(true);
                        if "Is Enabled" then begin
                            FeatureTelemetry.LogUptake('0000H7A', 'Dynamics 365 Sales', Enum::"Feature Uptake Status"::"Set up");
                            Session.LogMessage('0000CM7', CRMConnEnabledOnPageTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                        end;
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
                    Enabled = IsProxyVersionEnabled;
                    ToolTip = 'Specifies the Microsoft Dynamics 365 (CRM) software development kit version that is used to connect to Dynamics 365 Sales.';

                    trigger OnAssistEdit()
                    var
                        TempStack: Record TempStack temporary;
                    begin
                        if PAGE.RunModal(PAGE::"SDK Version List", TempStack) = ACTION::LookupOK then begin
                            Validate("Proxy Version", TempStack.StackOrder);
                            ConnectionString := GetConnectionString();
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
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This functionality is replaced with new item availability job queue entry.';
                    ObsoleteTag = '18.0';
                    Visible = false;
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
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This functionality is replaced with new item availability job queue entry.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                    ApplicationArea = Suite;
                    ShowCaption = false;
                    Caption = '';
                }
                field(NAVODataURL; "Dynamics NAV OData URL")
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This functionality is replaced with new item availability job queue entry.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                    ApplicationArea = Suite;
                    Caption = 'Dynamics 365 Business Central OData Web Service URL';
                    Enabled = "Is CRM Solution Installed";
                    ToolTip = 'Specifies the URL of Business Central OData web services. From sales order records in Dynamics 365 Sales, users can retrieve item availability information for items in Business Central that are coupled to sales order detail records in Dynamics 365 Sales. Set this field to the URL of the Business Central OData web services to use.';
                }
                field(NAVODataUsername; "Dynamics NAV OData Username")
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This functionality is replaced with new item availability job queue entry.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                    ApplicationArea = Suite;
                    Caption = 'Dynamics 365 Business Central OData Web Service Username';
                    Enabled = "Is CRM Solution Installed";
                    Lookup = true;
                    LookupPageID = Users;
                    ToolTip = 'Specifies the user name to access Dynamics 365 OData web services.';
                }
                field(NAVODataAccesskey; "Dynamics NAV OData Accesskey")
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This functionality is replaced with new item availability job queue entry.';
                    ObsoleteTag = '18.0';
                    Visible = false;
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
                field("CRM Version"; Rec."CRM Version")
                {
                    ApplicationArea = Suite;
                    Caption = 'Version';
                    Editable = false;
                    StyleExpr = CRMVersionStyleExpr;
                    ToolTip = 'Specifies the version of Dynamics 365 Sales.';

                    trigger OnDrillDown()
                    begin
                        if IsVersionValid() then
                            Message(FavorableCRMVersionMsg, CRMProductName.SHORT())
                        else
                            Message(UnfavorableCRMVersionMsg, PRODUCTNAME.Short(), CRMProductName.SHORT());
                    end;
                }
                field("Is CRM Solution Installed"; Rec."Is CRM Solution Installed")
                {
                    ApplicationArea = Suite;
                    Caption = 'Dynamics 365 Business Central Integration Solution Imported';
                    Editable = false;
                    StyleExpr = CRMSolutionInstalledStyleExpr;
                    ToolTip = 'Specifies if the Integration Solution is installed and configured in Dynamics 365 Sales. You cannot change this setting.';

                    trigger OnDrillDown()
                    begin
                        if "Is CRM Solution Installed" then
                            Message(FavorableCRMSolutionInstalledMsg, PRODUCTNAME.Short(), CRMProductName.SHORT())
                        else
                            Message(UnfavorableCRMSolutionInstalledMsg, PRODUCTNAME.Short());
                    end;
                }
                field("Is S.Order Integration Enabled"; Rec."Is S.Order Integration Enabled")
                {
                    ApplicationArea = Suite;
                    Caption = 'Legacy Sales Order Integration Enabled';
                    Enabled = not IsBidirectionalSalesOrderIntegrationEnabled;
                    ToolTip = 'Specifies that it is possible for Dynamics 365 Sales users to submit sales orders that can then be viewed and imported in Dynamics 365.';

                    trigger OnValidate()
                    begin
                        SetAutoCreateSalesOrdersEditable();
                    end;
                }
                field("Auto Create Sales Orders"; Rec."Auto Create Sales Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Automatically Create Sales Orders';
                    Editable = IsAutoCreateSalesOrdersEditable;
                    ToolTip = 'Specifies that sales orders will be created automatically from sales orders that are submitted in Dynamics 365 Sales.';
                }
                field("Auto Process Sales Quotes"; Rec."Auto Process Sales Quotes")
                {
                    ApplicationArea = Suite;
                    Caption = 'Automatically Process Sales Quotes';
                    ToolTip = 'Specifies that sales quotes will be automatically processed on sales quotes creation/revision/winning submitted in Dynamics 365 Sales quotes entities.';
                }
                field("Bidirectional Sales Order Int."; "Bidirectional Sales Order Int.")
                {
                    ApplicationArea = Suite;
                    Caption = 'Bidirectional Sales Order Int.';
                    Editable = not IsAutoCreateSalesOrdersEditable;
                    ToolTip = 'Specifies that it is possible to synchronize Sales Order bidirectionally. This feature will also enable Archiving Orders.';

                    trigger OnValidate()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        if "Bidirectional Sales Order Int." then
                            if CRMIntegrationManagement.CheckSolutionVersionOutdated() then
                                if Confirm(InstallLatestSolutionConfirmLbl) then
                                    DeployCRMSolution(true)
                                else
                                    Error('');

                        CurrPage.Update();
                    end;
                }
            }
            group(AdvancedSettings)
            {
                Caption = 'Advanced Settings';
#if not CLEAN20
                field("Is User Mapping Required"; Rec."Is User Mapping Required")
                {
                    ObsoleteTag = '20.0';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This functionality is not in use and not supported';
                    Visible = false;
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that Dynamics 365 users must have a matching user account in Dynamics 365 Sales to have Dynamics 365 Sales integration capabilities in the user interface.';

                    trigger OnValidate()
                    begin
                        UpdateIsEnabledState();
                        SetStyleExpr();
                    end;
                }
                field("Is User Mapped To CRM User"; Rec."Is User Mapped To CRM User")
                {
                    ObsoleteTag = '20.0';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This functionality is not in use and not supported';
                    ApplicationArea = Suite;
                    Caption = 'Current Business Central User is Mapped to a Dynamics 365 Sales User';
                    Editable = false;
                    ToolTip = 'Specifies that the user account that you used to sign in with has a matching user account in Dynamics 365 Sales.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        if "Is User Mapped To CRM User" then
                            Message(CurrentuserIsMappedToCRMUserMsg, UserId, PRODUCTNAME.Short(), CRMProductName.CDSServiceName())
                        else
                            Message(CurrentuserIsNotMappedToCRMUserMsg, UserId, PRODUCTNAME.Short(), CRMProductName.SHORT(), CRMProductName.CDSServiceName());
                    end;
                }
#endif
                field("Use Newest UI"; Rec."Use Newest UI")
                {
                    ApplicationArea = Suite;
                    Editable = "Is Enabled";
                    Caption = 'Open Coupled Entities in Dynamics 365 Sales Hub';
                    ToolTip = 'Specifies that coupled Dynamics 365 Sales entities should open in Sales Hub.';
                }
                field("Item Availability Enabled"; Rec."Item Availability Enabled")
                {
                    ApplicationArea = Suite;
                    Editable = "Is Enabled";
                    Caption = 'Automatically Synchronize Item Availability';
                    ToolTip = 'Specifies that item availability job queue entry will be scheduled.';
                }
                field("Unit Group Mapping Enabled"; "Unit Group Mapping Enabled")
                {
                    ApplicationArea = Suite;
                    Caption = 'Unit Group Mapping';
                    ToolTip = 'Specifies that unit group mapping is enabled.';
                    Editable = not "Is Enabled";
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
                field("Authentication Type"; Rec."Authentication Type")
                {
                    ApplicationArea = Advanced;
                    Editable = IsEditable;
                    ToolTip = 'Specifies the authentication type that will be used to authenticate with Dynamics 365 Sales';

                    trigger OnValidate()
                    begin
                        ConnectionString := GetConnectionString();
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
                    Editable = IsEditable;
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
                ToolTip = 'Runs Dynamics 365 Connection Setup Wizard.';

                trigger OnAction()
                var
                    GuidedExperience: Codeunit "Guided Experience";
                    CRMIntegrationMgt: Codeunit "CRM Integration Management";
                    GuidedExperienceType: Enum "Guided Experience Type";
                begin
                    CRMIntegrationMgt.RegisterAssistedSetup();
                    Commit(); // Make sure all data is committed before we run the wizard
                    GuidedExperience.Run(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"CRM Connection Setup Wizard");
                    CurrPage.Update(false);
                end;
            }
            action("Test Connection")
            {
                ApplicationArea = Suite;
                Caption = 'Test Connection', Comment = 'Test is a verb.';
                Image = ValidateEmailLoggingSetup;
                ToolTip = 'Tests the connection to Dynamics 365 Sales using the specified settings.';

                trigger OnAction()
                begin
                    PerformTestConnection();
                end;
            }
            action("Use Certificate Authentication")
            {
                ApplicationArea = Suite;
                Caption = 'Use Certificate Authentication';
                Image = Certificate;
                Visible = SoftwareAsAService;
                Enabled = Rec."Is Enabled";
                ToolTip = 'Upgrades the connection to Dynamics 365 Sales to use certificate-based OAuth 2.0 service-to-service authentication.';

                trigger OnAction()
                var
                    TempCDSConnectionSetup: Record "CDS Connection Setup" temporary;
                    CDSConnectionSetup: Record "CDS Connection Setup";
                    CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
                begin
                    TempCDSConnectionSetup."Server Address" := "Server Address";
                    TempCDSConnectionSetup."User Name" := "User Name";
                    TempCDSConnectionSetup."Proxy Version" := CDSIntegrationImpl.GetLastProxyVersionItem();
                    TempCDSConnectionSetup."Authentication Type" := TempCDSConnectionSetup."Authentication Type"::Office365;
                    TempCDSConnectionSetup.Insert();
                    Commit();

                    CDSIntegrationImpl.SetupCertificateAuthentication(TempCDSConnectionSetup);

                    if (TempCDSConnectionSetup."Connection String".IndexOf('{CERTIFICATE}') > 0) and (TempCDSConnectionSetup."User Name" <> "User Name") then begin
                        if CDSConnectionSetup.Get() then
                            if CDSConnectionSetup."Is Enabled" then begin
                                CDSConnectionSetup."User Name" := TempCDSConnectionSetup."User Name";
                                CDSConnectionSetup.SetPassword('');
                                CDSConnectionSetup."Proxy Version" := TempCDSConnectionSetup."Proxy Version";
                                CDSConnectionSetup."Connection String" := TempCDSConnectionSetup."Connection String";
                                CDSConnectionSetup.Modify();
                            end;
                        "User Name" := TempCDSConnectionSetup."User Name";
                        SetPassword('');
                        "Proxy Version" := TempCDSConnectionSetup."Proxy Version";
                        SetConnectionString(TempCDSConnectionSetup."Connection String");
                        CurrPage.Update(false);
                        Session.LogMessage('0000FB5', CertificateConnectionSetupTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                        Message(StrSubstNo(CertificateConnectionSetupMsg, "User Name"));
                    end;
                end;
            }
            action(IntegrationTableMappings)
            {
                ApplicationArea = Suite;
                Caption = 'Integration Table Mappings';
                Enabled = "Is Enabled";
                Image = MapAccounts;
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
                Enabled = IsCdsIntegrationEnabled and (not "Is Enabled");
                ToolTip = 'Redeploy and reconfigure the Microsoft Dynamics 365 Sales integration solution.';

                trigger OnAction()
                begin
                    Commit();
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
                    if Confirm(ResetIntegrationTableMappingConfirmQst, false, CRMProductName.SHORT()) then begin
                        CRMSetupDefaults.ResetConfiguration(Rec);
                        Message(SetupSuccessfulMsg, CRMProductName.SHORT());
                    end;
                    RefreshDataFromCRM();
                end;
            }
            action(CoupleUsers)
            {
                ApplicationArea = Suite;
                Caption = 'Couple Salespersons';
                Image = CoupledUsers;
                ToolTip = 'Open the list of users in Dynamics 365 Sales for manual coupling to salespersons in Business Central.';

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
                    PerformWebClientUrlReset();
                    Message(WebClientUrlResetMsg, PRODUCTNAME.Short());
                end;
            }
            action(SynchronizeNow)
            {
                ApplicationArea = Suite;
                Caption = 'Synchronize Modified Records';
                Enabled = "Is Enabled";
                Image = Refresh;
                ToolTip = 'Synchronize records that have been modified since the last time they were synchronized.';

                trigger OnAction()
                var
                    IntegrationSynchJobList: Page "Integration Synch. Job List";
                begin
                    if not Confirm(SynchronizeModifiedQst) then
                        exit;

                    SynchronizeNow(false);
                    Message(SyncNowScheduledMsg, IntegrationSynchJobList.Caption)
                end;
            }
#if not CLEAN22
#pragma warning disable AA0194
            action("Generate Integration IDs")
            {
                ApplicationArea = Suite;
                Caption = 'Generate Integration IDs';
                Image = Reconcile;
                ToolTip = 'Create integration IDs for new records that were added while the connection was disabled, for example, after you re-enable a Dynamics 365 Sales connection.';
                Visible = false;
                ObsoleteReason = 'This functionality is deprecated.';
                ObsoleteState = Pending;
                ObsoleteTag = '22.0';
            }
#pragma warning restore AA0194
#endif
        }
        area(navigation)
        {
            action("Integration Table Mappings")
            {
                ApplicationArea = Suite;
                Caption = 'Integration Table Mappings';
                Image = Relationship;
                RunObject = Page "Integration Table Mapping List";
                RunPageMode = Edit;
                ToolTip = 'View entries that map integration tables to business data tables in Business Central. Integration tables are set up to act as interfaces for synchronizing data between an external database table, such as Dynamics 365 Sales, and a corresponding business data table in Business Central.';
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Same action already exists in the page.';
                ObsoleteTag = '17.0';
            }
            action("Synch. Job Queue Entries")
            {
                ApplicationArea = Suite;
                Caption = 'Synch. Job Queue Entries';
                Image = JobListSetup;
                ToolTip = 'View the job queue entries that manage the scheduled synchronization between Dynamics 365 Sales and Business Central.';

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
            action(SkippedSynchRecords)
            {
                ApplicationArea = Suite;
                Caption = 'Skipped Synch. Records';
                Enabled = "Is Enabled";
                Image = NegativeLines;
                RunObject = Page "CRM Skipped Records";
                RunPageMode = View;
                ToolTip = 'View the list of records that will be skipped for synchronization.';
            }
            action(EncryptionManagement)
            {
                ApplicationArea = Advanced;
                Caption = 'Encryption Management';
                Image = EncryptionKeys;
                RunObject = Page "Data Encryption Management";
                RunPageMode = View;
                ToolTip = 'Enable or disable data encryption. Data encryption helps make sure that unauthorized users cannot read business data.';
            }
            action(RebuildCouplingTable)
            {
                ApplicationArea = Suite;
                Caption = 'Rebuild Coupling Table';
                Enabled = true;
                Image = Restore;
                ToolTip = 'Rebuilds the coupling table after Cloud Migration from Business Central 2019 Wave 1 (Business Central 14).';

                trigger OnAction()
                var
                    CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
                begin
                    CDSIntegrationImpl.ScheduleRebuildingOfCouplingTable();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Connection', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Assisted Setup_Promoted"; "Assisted Setup")
                {
                }
                actionref("Test Connection_Promoted"; "Test Connection")
                {
                }
                actionref("Use Certificate Authentication_Promoted"; "Use Certificate Authentication")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Mapping', Comment = 'Generated from the PromotedActionCategories property index 2.';

                actionref(IntegrationTableMappings_Promoted; IntegrationTableMappings)
                {
                }
                actionref("Redeploy Solution_Promoted"; "Redeploy Solution")
                {
                }
                actionref(CoupleUsers_Promoted; CoupleUsers)
                {
                }
                actionref("Integration Table Mappings_Promoted"; "Integration Table Mappings")
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Same action already exists in the page.';
                    ObsoleteTag = '17.0';
                }
            }
            group(Category_Category4)
            {
                Caption = 'Synchronization', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(StartInitialSynchAction_Promoted; StartInitialSynchAction)
                {
                }
                actionref(SynchronizeNow_Promoted; SynchronizeNow)
                {
                }
                actionref("Synch. Job Queue Entries_Promoted"; "Synch. Job Queue Entries")
                {
                }
                actionref(SkippedSynchRecords_Promoted; SkippedSynchRecords)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Encryption', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(EncryptionManagement_Promoted; EncryptionManagement)
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Cloud Migration', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref(RebuildCouplingTable_Promoted; RebuildCouplingTable)
                {
                }
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
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        ApplicationAreaMgmtFacade.CheckAppAreaOnlyBasic();
        SoftwareAsAService := EnvironmentInfo.IsSaaSInfrastructure();
        CRMIntegrationManagement.RegisterAssistedSetup();
        SetVisibilityFlags();
    end;

    trigger OnOpenPage()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000H7B', 'Dataverse', Enum::"Feature Uptake Status"::Discovered);
        FeatureTelemetry.LogUptake('0000H7C', 'Dynamics 365 Sales', Enum::"Feature Uptake Status"::Discovered);
        EnsureCDSConnectionIsEnabled();

        if not Get() then begin
            Init();
            InitializeDefaultProxyVersion();
            Insert();
            LoadConnectionStringElementsFromCDSConnectionSetup();
        end else begin
            CRMPassword := GetPassword();
            if not "Is Enabled" then
                LoadConnectionStringElementsFromCDSConnectionSetup();
            ConnectionString := GetConnectionString();
            UnregisterConnection();
            if (not IsValidProxyVersion()) then begin
                if not IsValidProxyVersion() then
                    InitializeDefaultProxyVersion();
                Modify();
            end;
            if "Is Enabled" then
                RegisterConnection()
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
        [NonDebuggable]
        CRMPassword: Text;
        ResetIntegrationTableMappingConfirmQst: Label 'This will restore the default integration table mappings and synchronization jobs for %1. All custom mappings and jobs will be deleted. The default mappings and jobs will be used the next time data is synchronized. Do you want to continue?', Comment = '%1 = CRM product name';
        EncryptionIsNotActivatedQst: Label 'Data encryption is currently not enabled. We recommend that you encrypt data. \Do you want to open the Data Encryption Management window?';
        WebClientUrlResetMsg: Label 'The %1 Web Client URL has been reset to the default value.', Comment = '%1 - product name';
        SyncNowScheduledMsg: Label 'Synchronization of modified records is scheduled.\You can view details on the %1 page.', Comment = '%1 = The localized caption of page Integration Synch. Job List';
        UnfavorableCRMVersionMsg: Label 'This version of %2 might not work correctly with %1. We recommend you upgrade to a supported version.', Comment = '%1 - product name, %2 = CRM product name';
        FavorableCRMVersionMsg: Label 'The version of %1 is valid.', Comment = '%1 = CRM product name';
        UnfavorableCRMSolutionInstalledMsg: Label 'The %1 Integration Solution was not detected.', Comment = '%1 - product name';
        FavorableCRMSolutionInstalledMsg: Label 'The %1 Integration Solution is installed in %2.', Comment = '%1 - product name, %2 = CRM product name';
        SynchronizeModifiedQst: Label 'This will synchronize all modified records in all integration table mappings.\The synchronization will run in the background so you can continue with other tasks.\\Do you want to continue?';
        ReadyScheduledSynchJobsTok: Label '%1 of %2', Comment = '%1 = Count of scheduled job queue entries in ready or in process state, %2 count of all scheduled jobs';
        ScheduledSynchJobsRunning: Text;
#if not CLEAN20
        CurrentuserIsMappedToCRMUserMsg: Label '%2 user (%1) is mapped to a %3 user.', Comment = '%1 = Current User ID, %2 - product name, %3 = Dataverse service name';
        CurrentuserIsNotMappedToCRMUserMsg: Label 'Because the %2 Users Must Map to %4 Users field is set, %3 integration is not enabled for %1.\\To enable %3 integration for %2 user %1, the authentication email must match the primary email of a %3 user.', Comment = '%1 = Current User ID, %2 - product name, %3 = CRM product name, %4 = Dataverse service name';
#endif
        EnableServiceQst: Label 'The %1 is not enabled. Are you sure you want to exit?', Comment = '%1 = This Page Caption (Microsoft Dynamics 365 Connection Setup)';
        PartialScheduledJobsAreRunningMsg: Label 'An active job queue is available but only %1 of the %2 scheduled synchronization jobs are ready or in process.', Comment = '%1 = Count of scheduled job queue entries in ready or in process state, %2 count of all scheduled jobs';
        JobQueueIsNotRunningMsg: Label 'There is no job queue started. Scheduled synchronization jobs require an active job queue to process jobs.\\Contact your administrator to get a job queue configured and started.';
        AllScheduledJobsAreRunningMsg: Label 'An job queue is started and all scheduled synchronization jobs are ready or already processing.';
        SetupSuccessfulMsg: Label 'The default setup for %1 synchronization has completed successfully.', Comment = '%1 = CRM product name';
        CertificateConnectionSetupTelemetryMsg: Label 'User has successfully set up the certificate connection to Dataverse.', Locked = true;
        CertificateConnectionSetupMsg: Label 'You have successfully upgraded the connection to Dynamics 365 Sales to use certificate-based OAuth 2.0 service-to-service authentication. Business Central has auto-generated a new integration user with user name %1 in your Dynamics 365 sales environment. This user does not require a license.', Comment = '%1 - user name';
        Office365AuthTxt: Label 'AuthType=Office365', Locked = true;
        CategoryTok: Label 'AL Dataverse Integration', Locked = true;
        CRMConnEnabledOnPageTxt: Label 'CRM Connection has been enabled from CRMConnectionSetupPage', Locked = true;
        InstallLatestSolutionConfirmLbl: Label 'Bidirectional Sales Order Integration requires the latest integration solution. Do you want to redeploy latest integration solution?';
        ScheduledSynchJobsRunningStyleExpr: Text;
        CRMSolutionInstalledStyleExpr: Text;
        CRMVersionStyleExpr: Text;
        ConnectionString: Text;
        WebServiceEnabledStyleExpr: Text;
        ActiveJobs: Integer;
        TotalJobs: Integer;
        IsEditable: Boolean;
        IsProxyVersionEnabled: Boolean;
        IsCdsIntegrationEnabled: Boolean;
        IsUserNamePasswordVisible: Boolean;
        IsWebCliResetEnabled: Boolean;
        SoftwareAsAService: Boolean;
        IsAutoCreateSalesOrdersEditable: Boolean;
        IsBidirectionalSalesOrderIntegrationEnabled: Boolean;
        WebServiceEnabled: Boolean;

    local procedure RefreshData()
    begin
#if not CLEAN20
        UpdateIsEnabledState();
#endif
        RefreshDataFromCRM(false);
        SetAutoCreateSalesOrdersEditable();
        RefreshSynchJobsData();
        UpdateEnableFlags();
        SetStyleExpr();
        IsBidirectionalSalesOrderIntegrationEnabled := "Bidirectional Sales Order Int.";
    end;

    local procedure RefreshSynchJobsData()
    begin
        CountCRMJobQueueEntries(ActiveJobs, TotalJobs);
        ScheduledSynchJobsRunning := StrSubstNo(ReadyScheduledSynchJobsTok, ActiveJobs, TotalJobs);
        ScheduledSynchJobsRunningStyleExpr := GetRunningJobsStyleExpr();
    end;

    local procedure SetStyleExpr()
    begin
        CRMSolutionInstalledStyleExpr := GetStyleExpr("Is CRM Solution Installed");
        CRMVersionStyleExpr := GetStyleExpr(IsVersionValid());
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
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
    begin
        IsEditable := not "Is Enabled" and not CDSIntegrationImpl.IsIntegrationEnabled();
        IsProxyVersionEnabled := true;
        if CDSConnectionSetup.Get() then
            if CDSConnectionSetup."Is Enabled" then
                IsProxyVersionEnabled := false;

        IsWebCliResetEnabled := "Is CRM Solution Installed" and "Is Enabled";
    end;

    local procedure SetVisibilityFlags()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        IsUserNamePasswordVisible := true;

        if CDSConnectionSetup.Get() then begin
            IsCdsIntegrationEnabled := CDSConnectionSetup."Is Enabled";
            if CDSConnectionSetup."Authentication Type" = CDSConnectionSetup."Authentication Type"::Office365 then
                if not CDSConnectionSetup."Connection String".Contains(Office365AuthTxt) then
                    IsUserNamePasswordVisible := false;
        end;
    end;

    local procedure IsValidProxyVersion(): Boolean
    begin
        exit("Proxy Version" <> 0);
    end;

    local procedure InitializeDefaultProxyVersion()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        Validate("Proxy Version", CRMIntegrationManagement.GetLastProxyVersionItem());
    end;
}

