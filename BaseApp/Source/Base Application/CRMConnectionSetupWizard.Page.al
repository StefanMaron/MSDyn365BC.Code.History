page 1817 "CRM Connection Setup Wizard"
{
    Caption = 'Dynamics 365 Connection Setup';
    PageType = NavigatePage;
    SourceTable = "CRM Connection Setup";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(BannerStandard)
            {
                Caption = '';
                Editable = false;
                Visible = TopBannerVisible AND NOT CredentialsStepVisible;
                field("MediaResourcesStandard.""Media Reference"""; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(BannerDone)
            {
                Caption = '';
                Editable = false;
                Visible = TopBannerVisible AND CredentialsStepVisible;
                field("MediaResourcesDone.""Media Reference"""; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Step1)
            {
                Visible = FirstStepVisible;
                group("Welcome to Dynamics 365 Connection Setup")
                {
                    Caption = 'Welcome to Dynamics 365 Connection Setup';
                    group(Control23)
                    {
                        InstructionalText = 'You can set up a Dynamics 365 Sales connection to enable seamless coupling of data.';
                        ShowCaption = false;
                    }
                    group(Control21)
                    {
                        InstructionalText = 'Start by specifying the URL to your Dynamics 365 Sales solution, such as https://mycrm.crm4.dynamics.com';
                        ShowCaption = false;
                    }
                    field(ServerAddress; "Server Address")
                    {
                        ApplicationArea = Suite;
                        Editable = ConnectionStringFieldsEditable;
                        ToolTip = 'Specifies the URL of the Dynamics 365 Sales server that hosts the Dynamics 365 Sales solution that you want to connect to.';

                        trigger OnValidate()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CRMIntegrationManagement.CheckModifyCRMConnectionURL("Server Address");
                        end;
                    }
                    group(Control9)
                    {
                        InstructionalText = 'Once coupled, you can work with and synchronize data types that are common to both services, such as customers, contacts, and sales information, and keep the data up-to-date in both locations.';
                        ShowCaption = false;
                    }
                }
            }
            group(Step2)
            {
                Caption = '';
                Visible = CredentialsStepVisible;
                group("Step2.1")
                {
                    Caption = '';
                    InstructionalText = 'Specify the user that will be used for synchronization between the two services.';
                    Visible = IsUserNamePasswordVisible;
                    field(Email; "User Name")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Email';
                        ExtendedDatatype = EMail;
                        Editable = ConnectionStringFieldsEditable;
                        ToolTip = 'Specifies the user name of a Dynamics 365 Sales account.';
                    }
                    field(Password; Password)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Password';
                        ExtendedDatatype = Masked;
                        Editable = ConnectionStringFieldsEditable;
                        ToolTip = 'Specifies the password of a Dynamics 365 Sales user account.';
                    }
                }
                group(Control22)
                {
                    InstructionalText = 'This account must be a valid user in Dynamics 365 Sales that does not have the System Administrator role.';
                    ShowCaption = false;
                    Visible = IsUserNamePasswordVisible;
                }
                group("Advanced Settings")
                {
                    Caption = 'Advanced Connection Settings';
                    Visible = ShowAdvancedSettings;
                    field(ImportCRMSolution; ImportSolution)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Import Dynamics 365 Sales Solution';
                        Enabled = ImportCRMSolutionEnabled;
                        ToolTip = 'Specifies that the Dynamics 365 Sales Solution will be imported.';

                        trigger OnValidate()
                        begin
                            OnImportSolutionChange();
                        end;
                    }
                    field(EnableItemAvailability; EnableItemAvailability)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Automatically Synchronize Item Availability';
                        Enabled = PublishItemAvailabilityServiceEnabled;
                        ToolTip = 'Specifies that item availability job queue entry will be scheduled.';
                    }
                    field(PublishItemAvailabilityService; PublishItemAvailabilityService)
                    {
                        ObsoleteState = Pending;
                        ObsoleteReason = 'This functionality is replaced with new item availability job queue entry.';
                        ObsoleteTag = '18.0';
                        Visible = false;
                        ApplicationArea = Suite;
                        Caption = 'Publish Item Availability Web Service';
                        Enabled = PublishItemAvailabilityServiceEnabled;
                    }
                    label(Control26)
                    {
                        ObsoleteState = Pending;
                        ObsoleteReason = 'This functionality is replaced with new item availability job queue entry.';
                        ObsoleteTag = '18.0';
                        Visible = false;
                        ApplicationArea = Suite;
                        Caption = 'You must assign the security role Business Central Product Availability User to your sales people in Dynamics 365 Sales.';
                    }
                    field(NAVODataUsername; "Dynamics NAV OData Username")
                    {
                        ObsoleteState = Pending;
                        ObsoleteReason = 'This functionality is replaced with new item availability job queue entry.';
                        ObsoleteTag = '18.0';
                        Visible = false;
                        ApplicationArea = Suite;
                        Caption = 'Business Central OData Web Service User Name';
                        Editable = PublishItemAvailabilityService;
                        Enabled = PublishItemAvailabilityServiceEnabled;
                        Lookup = true;
                        LookupPageID = Users;
                    }
                    field(NAVODataAccesskey; "Dynamics NAV OData Accesskey")
                    {
                        ObsoleteState = Pending;
                        ObsoleteReason = 'This functionality is replaced with new item availability job queue entry.';
                        ObsoleteTag = '18.0';
                        Visible = false;
                        ApplicationArea = Suite;
                        Caption = 'Business Central OData Web Service Access Key';
                        Editable = false;
                        Enabled = PublishItemAvailabilityServiceEnabled;
                    }
                    field(EnableSalesOrderIntegration; EnableSalesOrderIntegration)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Enable Legacy Sales Order Integration';
                        Enabled = EnableSalesOrderIntegrationEnabled;
                        ToolTip = 'Specifies that it is possible for Dynamics 365 Sales users to submit sales orders that can then be viewed and imported in Dynamics 365.';

                        trigger OnValidate()
                        begin
                            if EnableSalesOrderIntegration then
                                EnableBidirectionalSalesOrderIntegrationEnabled := false
                            else
                                EnableBidirectionalSalesOrderIntegrationEnabled := true;
                        end;
                    }
                    field(EnableBidirectionalSalesOrderIntegration; EnableBidirectionalSalesOrderIntegration)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Enable Bidirectional Sales Order Integration';
                        Enabled = EnableBidirectionalSalesOrderIntegrationEnabled;
                        ToolTip = 'Specifies that it is possible to synchronize Sales Order bidirectionally. This feature will also enable Archiving Orders.';

                        trigger OnValidate()
                        begin
                            if EnableBidirectionalSalesOrderIntegration then
                                EnableSalesOrderIntegrationEnabled := false
                            else
                                EnableSalesOrderIntegrationEnabled := true;
                        end;
                    }
                    field(EnableCRMConnection; EnableCRMConnection)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Enable Dynamics 365 Sales Connection';
                        Enabled = EnableCRMConnectionEnabled;
                        ToolTip = 'Specifies if the connection to Dynamics 365 Sales will be enabled.';
                    }
                    field(SDKVersion; "Proxy Version")
                    {
                        ApplicationArea = Suite;
                        AssistEdit = true;
                        Caption = 'Dynamics 365 SDK Version';
                        Editable = false;
                        ToolTip = 'Specifies the Microsoft Dynamics 365 (CRM) software development kit version that is used to connect to Dynamics 365 Sales.';

                        trigger OnAssistEdit()
                        var
                            TempStack: Record TempStack temporary;
                        begin
                            if PAGE.RunModal(PAGE::"SDK Version List", TempStack) = ACTION::LookupOK then begin
                                "Proxy Version" := TempStack.StackOrder;
                                CurrPage.Update(true);
                            end;
                        end;
                    }
                }
                group(Control20)
                {
                    InstructionalText = 'To enable the connection, choose Finish. You may be asked to specify an administrative user account in Dynamics 365 Sales.';
                    ShowCaption = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ActionBack)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Back';
                Enabled = BackActionEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(true);
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next';
                Enabled = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    if (Step = Step::Start) and ("Server Address" = '') then
                        Error(CRMURLShouldNotBeEmptyErr, CRMProductName.SHORT());
                    NextStep(false);
                end;
            }
            action(ActionAdvanced)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Advanced';
                Image = Setup;
                InFooterBar = true;
                Visible = AdvancedActionEnabled;

                trigger OnAction()
                begin
                    ShowAdvancedSettings := true;
                    AdvancedActionEnabled := false;
                    SimpleActionEnabled := true;
                end;
            }
            action(ActionSimple)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Simple';
                Image = Setup;
                InFooterBar = true;
                Visible = SimpleActionEnabled;

                trigger OnAction()
                begin
                    ShowAdvancedSettings := false;
                    AdvancedActionEnabled := true;
                    SimpleActionEnabled := false;
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Finish';
                Enabled = FinishActionEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                var
                    FeatureTelemetry: Codeunit "Feature Telemetry";
                    GuidedExperience: Codeunit "Guided Experience";
                begin
                    if "Authentication Type" = "Authentication Type"::Office365 then
                        if "User Name" = '' then
                            Error(CRMSynchUserCredentialsNeededErr, CRMProductName.SHORT());

                    if not FinalizeSetup() then
                        exit;
                    Page.Run(Page::"CRM Connection Setup");
                    GuidedExperience.CompleteAssistedSetup(ObjectType::Page, PAGE::"CRM Connection Setup Wizard");
                    Commit();
                    FeatureTelemetry.LogUptake('0000H77', 'Dynamics 365 Sales', Enum::"Feature Uptake Status"::"Set up");
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnInit()
    begin
        LoadTopBanners();
        SetVisibilityFlags();
    end;

    trigger OnOpenPage()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        CRMConnectionSetup.EnsureCDSConnectionIsEnabled();
        CRMConnectionSetup.LoadConnectionStringElementsFromCDSConnectionSetup();
        FeatureTelemetry.LogUptake('0000H78', 'Dataverse', Enum::"Feature Uptake Status"::Discovered);
        FeatureTelemetry.LogUptake('0000H79', 'Dynamics 365 Sales', Enum::"Feature Uptake Status"::Discovered);

        Init();
        if CRMConnectionSetup.Get() then begin
            "Proxy Version" := CRMConnectionSetup."Proxy Version";
            "Authentication Type" := CRMConnectionSetup."Authentication Type";
            "Server Address" := CRMConnectionSetup."Server Address";
            "User Name" := CRMConnectionSetup."User Name";
            "User Password Key" := CRMConnectionSetup."User Password Key";
            Password := CRMConnectionSetup.GetPassword();
            ConnectionStringFieldsEditable := false;
        end else begin
            InitializeDefaultAuthenticationType();
            InitializeDefaultProxyVersion();
        end;
        Insert();
        Step := Step::Start;
        EnableControls();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        if CloseAction = ACTION::OK then
            if GuidedExperience.AssistedSetupExistsAndIsNotComplete(ObjectType::Page, PAGE::"CRM Connection Setup Wizard") then
                if not Confirm(ConnectionNotSetUpQst, false, CRMProductName.SHORT()) then
                    Error('');
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        CRMProductName: Codeunit "CRM Product Name";
        ClientTypeManagement: Codeunit "Client Type Management";
        Step: Option Start,Credentials,Finish;
        TopBannerVisible: Boolean;
        ConnectionStringFieldsEditable: Boolean;
        BackActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        FinishActionEnabled: Boolean;
        FirstStepVisible: Boolean;
        CredentialsStepVisible: Boolean;
        EnableCRMConnection: Boolean;
        ImportSolution: Boolean;
        PublishItemAvailabilityService: Boolean;
        EnableCRMConnectionEnabled: Boolean;
        ImportCRMSolutionEnabled: Boolean;
        PublishItemAvailabilityServiceEnabled: Boolean;
        EnableBidirectionalSalesOrderIntegration: Boolean;
        EnableBidirectionalSalesOrderIntegrationEnabled: Boolean;
        EnableSalesOrderIntegration: Boolean;
        EnableSalesOrderIntegrationEnabled: Boolean;
        EnableItemAvailability: Boolean;
        ShowAdvancedSettings: Boolean;
        AdvancedActionEnabled: Boolean;
        SimpleActionEnabled: Boolean;
        IsUserNamePasswordVisible: Boolean;
        [NonDebuggable]
        Password: Text;
        ConnectionNotSetUpQst: Label 'The %1 connection has not been set up.\\Are you sure you want to exit?', Comment = '%1 = CRM product name';
        CRMURLShouldNotBeEmptyErr: Label 'You must specify the URL of your %1 solution.', Comment = '%1 = CRM product name';
        CRMSynchUserCredentialsNeededErr: Label 'You must specify the credentials for the user account for synchronization with %1.', Comment = '%1 = CRM product name';
        Office365AuthTxt: Label 'AuthType=Office365', Locked = true;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType())) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue;
    end;

    local procedure SetVisibilityFlags()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        IsUserNamePasswordVisible := true;

        if CDSConnectionSetup.Get() then
            if CDSConnectionSetup."Authentication Type" = CDSConnectionSetup."Authentication Type"::Office365 then
                if not CDSConnectionSetup."Connection String".Contains(Office365AuthTxt) then
                    IsUserNamePasswordVisible := false;
    end;

    local procedure NextStep(Backward: Boolean)
    begin
        if Backward then
            Step := Step - 1
        else
            Step := Step + 1;

        EnableControls();
    end;

    local procedure ResetControls()
    begin
        BackActionEnabled := false;
        NextActionEnabled := false;
        FinishActionEnabled := false;
        AdvancedActionEnabled := false;

        FirstStepVisible := false;
        CredentialsStepVisible := false;

        ImportCRMSolutionEnabled := true;
        PublishItemAvailabilityServiceEnabled := true;
        EnableBidirectionalSalesOrderIntegration := true;
        EnableBidirectionalSalesOrderIntegrationEnabled := true;
    end;

    local procedure EnableControls()
    begin
        ResetControls();

        case Step of
            Step::Start:
                ShowStartStep();
            Step::Credentials:
                ShowFinishStep();
        end;
    end;

    local procedure ShowStartStep()
    begin
        BackActionEnabled := false;
        NextActionEnabled := true;
        FinishActionEnabled := false;
        FirstStepVisible := true;
        AdvancedActionEnabled := false;
        SimpleActionEnabled := false;
    end;

    local procedure ShowFinishStep()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        BackActionEnabled := true;
        NextActionEnabled := false;
        AdvancedActionEnabled := not ShowAdvancedSettings;
        SimpleActionEnabled := not AdvancedActionEnabled;
        CredentialsStepVisible := true;
        FinishActionEnabled := true;

        EnableBidirectionalSalesOrderIntegrationEnabled := ImportCRMSolutionEnabled;
        EnableSalesOrderIntegrationEnabled := ImportCRMSolutionEnabled;
        EnableCRMConnectionEnabled := "Server Address" <> '';
        "Authentication Type" := "Authentication Type"::Office365;
        if CRMConnectionSetup.Get() then begin
            EnableCRMConnection := true;
            EnableCRMConnectionEnabled := not CRMConnectionSetup."Is Enabled";
            EnableBidirectionalSalesOrderIntegration := CRMConnectionSetup."Bidirectional Sales Order Int.";
            EnableSalesOrderIntegration := CRMConnectionSetup."Is S.Order Integration Enabled";
            EnableBidirectionalSalesOrderIntegrationEnabled := not CRMConnectionSetup."Bidirectional Sales Order Int." and not CRMConnectionSetup."Is S.Order Integration Enabled";
            EnableSalesOrderIntegrationEnabled := not CRMConnectionSetup."Bidirectional Sales Order Int." and not CRMConnectionSetup."Is S.Order Integration Enabled";
            ImportSolution := true;
            if CRMConnectionSetup."Is CRM Solution Installed" then
                ImportCRMSolutionEnabled := false;
        end else begin
            if ImportCRMSolutionEnabled then
                ImportSolution := true;
            if EnableCRMConnectionEnabled then
                EnableCRMConnection := true;
        end;
    end;

    [NonDebuggable]
    local procedure FinalizeSetup(): Boolean
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        AdminEmail: Text;
        AdminPassword: Text;
        AccessToken: Text;
        AdminADDomain: Text;
    begin
        if ImportSolution and ImportCRMSolutionEnabled then begin
            case "Authentication Type" of
                "Authentication Type"::Office365:
                    CDSIntegrationImpl.GetAccessToken("Server Address", true, AccessToken);
                "Authentication Type"::AD:
                    if not PromptForCredentials(AdminEmail, AdminPassword, AdminADDomain) then
                        exit(false);
                else
                    if not PromptForCredentials(AdminEmail, AdminPassword) then
                        exit(false);
            end;
            CRMIntegrationManagement.ImportCRMSolution("Server Address", "User Name", AdminEmail, AdminPassword, AccessToken, AdminADDomain, "Proxy Version", true);
        end;
        if EnableBidirectionalSalesOrderIntegration then
            Validate("Bidirectional Sales Order Int.", true);
        if EnableSalesOrderIntegration then
            "Is S.Order Integration Enabled" := true;
        if EnableItemAvailability then
            "Item Availability Enabled" := true;

        CRMIntegrationManagement.InitializeCRMSynchStatus();
        CRMConnectionSetup.UpdateFromWizard(Rec, Password);
        if EnableCRMConnection then
            CRMConnectionSetup.EnableCRMConnectionFromWizard();
        if EnableSalesOrderIntegration and EnableSalesOrderIntegrationEnabled then
            CRMConnectionSetup.SetCRMSOPEnabledWithCredentials(AdminEmail, AdminPassword, true);
        exit(true);
    end;

    local procedure OnImportSolutionChange()
    begin
        PublishItemAvailabilityServiceEnabled := ImportSolution;
    end;

    local procedure InitializeDefaultAuthenticationType()
    begin
        Validate("Authentication Type", "Authentication Type"::Office365);
    end;

    local procedure InitializeDefaultProxyVersion()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        Validate("Proxy Version", CRMIntegrationManagement.GetLastProxyVersionItem());
    end;
}

