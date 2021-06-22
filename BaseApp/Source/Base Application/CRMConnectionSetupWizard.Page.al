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
                    field(Email; "User Name")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Email';
                        ExtendedDatatype = EMail;
                        Editable = ConnectionStringFieldsEditable;
                    }
                    field(Password; Password)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Password';
                        ExtendedDatatype = Masked;
                        Editable = ConnectionStringFieldsEditable;
                    }
                }
                group(Control22)
                {
                    InstructionalText = 'This account must be a valid user in Dynamics 365 Sales that does not have the System Administrator role.';
                    ShowCaption = false;
                }
                group("Advanced Settings")
                {
                    Caption = 'Advanced Settings';
                    Visible = ShowAdvancedSettings;
                    field(ImportCRMSolution; ImportSolution)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Import Dynamics 365 Sales Solution';
                        Enabled = ImportCRMSolutionEnabled;

                        trigger OnValidate()
                        begin
                            OnImportSolutionChange;
                        end;
                    }
                    field(PublishItemAvailabilityService; PublishItemAvailabilityService)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Publish Item Availability Web Service';
                        Enabled = PublishItemAvailabilityServiceEnabled;

                        trigger OnValidate()
                        begin
                            if not PublishItemAvailabilityService then begin
                                Clear("Dynamics NAV OData Username");
                                Clear("Dynamics NAV OData Accesskey");
                            end;
                        end;
                    }
                    label(Control26)
                    {
                        ApplicationArea = Suite;
                        Caption = 'You must assign the security role Business Central Product Availability User to your sales people in Dynamics 365 Sales.';
                    }
                    field(NAVODataUsername; "Dynamics NAV OData Username")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Business Central OData Web Service User Name';
                        Editable = PublishItemAvailabilityService;
                        Enabled = PublishItemAvailabilityServiceEnabled;
                        Lookup = true;
                        LookupPageID = Users;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            User: Record User;
                        begin
                            if PAGE.RunModal(PAGE::Users, User) = ACTION::LookupOK then begin
                                "Dynamics NAV OData Username" := User."User Name";
                                UpdateUserWebKey(User);
                            end;
                        end;
                    }
                    field(NAVODataAccesskey; "Dynamics NAV OData Accesskey")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Business Central OData Web Service Access Key';
                        Editable = false;
                        Enabled = PublishItemAvailabilityServiceEnabled;
                    }
                    field(EnableSalesOrderIntegration; EnableSalesOrderIntegration)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Enable Sales Order Integration';
                        Enabled = EnableSalesOrderIntegrationEnabled;
                    }
                    field(EnableCRMConnection; EnableCRMConnection)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Enable Dynamics 365 Sales Connection';
                        Enabled = EnableCRMConnectionEnabled;
                    }
                    field(SDKVersion; "Proxy Version")
                    {
                        ApplicationArea = Suite;
                        AssistEdit = true;
                        Caption = 'Dynamics 365 SDK Version';
                        Editable = false;

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
                    InstructionalText = 'To enable the connection, choose Finish. You will be asked to specify an administrative user account in Dynamics 365 Sales.';
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
                        Error(CRMURLShouldNotBeEmptyErr, CRMProductName.SHORT);
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
                    AssistedSetup: Codeunit "Assisted Setup";
                begin
                    if ("User Name" = '') or (Password = '') then
                        Error(CRMSynchUserCredentialsNeededErr, CRMProductName.SHORT);
                    if not FinalizeSetup then
                        exit;
                    AssistedSetup.Complete(PAGE::"CRM Connection Setup Wizard");
                    Commit();
                    CurrPage.Close;
                end;
            }
        }
    }

    trigger OnInit()
    begin
        LoadTopBanners;
    end;

    trigger OnOpenPage()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        CRMConnectionSetup.EnsureCDSConnectionIsEnabled();
        CRMConnectionSetup.LoadConnectionStringElementsFromCDSConnectionSetup();

        Init;
        if CRMConnectionSetup.Get then begin
            "Server Address" := CRMConnectionSetup."Server Address";
            "User Name" := CRMConnectionSetup."User Name";
            "User Password Key" := CRMConnectionSetup."User Password Key";
            Password := CRMConnectionSetup.GetPassword();
            ConnectionStringFieldsEditable := false;
        end;
        InitializeDefaultProxyVersion;
        Insert;
        Step := Step::Start;
        EnableControls;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        AssistedSetup: Codeunit "Assisted Setup";
        Info: ModuleInfo;
    begin
        if CloseAction = ACTION::OK then
            if AssistedSetup.ExistsAndIsNotComplete(PAGE::"CRM Connection Setup Wizard") then
                if not Confirm(ConnectionNotSetUpQst, false, CRMProductName.SHORT) then
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
        EnableSalesOrderIntegration: Boolean;
        EnableSalesOrderIntegrationEnabled: Boolean;
        ShowAdvancedSettings: Boolean;
        AdvancedActionEnabled: Boolean;
        SimpleActionEnabled: Boolean;
        Password: Text;
        ConnectionNotSetUpQst: Label 'The %1 connection has not been set up.\\Are you sure you want to exit?', Comment = '%1 = CRM product name';
        MustUpdateClientsQst: Label 'If you change the web service access key, the current access key will no longer be valid. You must update all clients that use it. Do you want to continue?';
        CRMURLShouldNotBeEmptyErr: Label 'You must specify the URL of your %1 solution.', Comment = '%1 = CRM product name';
        CRMSynchUserCredentialsNeededErr: Label 'You must specify the credentials for the user account for synchronization with %1.', Comment = '%1 = CRM product name';

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType)) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue;
    end;

    local procedure NextStep(Backward: Boolean)
    begin
        if Backward then
            Step := Step - 1
        else
            Step := Step + 1;

        EnableControls;
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
        EnableSalesOrderIntegrationEnabled := true;
        EnableSalesOrderIntegration := true;
    end;

    local procedure EnableControls()
    begin
        ResetControls;

        case Step of
            Step::Start:
                ShowStartStep;
            Step::Credentials:
                ShowFinishStep;
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
        User: Record User;
        IdentityManagement: Codeunit "Identity Management";
    begin
        BackActionEnabled := true;
        NextActionEnabled := false;
        AdvancedActionEnabled := not ShowAdvancedSettings;
        SimpleActionEnabled := not AdvancedActionEnabled;
        CredentialsStepVisible := true;
        FinishActionEnabled := true;

        EnableSalesOrderIntegrationEnabled := ImportCRMSolutionEnabled;
        EnableCRMConnectionEnabled := "Server Address" <> '';
        if User.Get(UserSecurityId) then begin
            "Dynamics NAV OData Accesskey" := IdentityManagement.GetWebServicesKey(User."User Security ID");
            if "Dynamics NAV OData Accesskey" <> '' then
                "Dynamics NAV OData Username" := User."User Name";
        end;
        "Authentication Type" := "Authentication Type"::Office365;
        if CRMConnectionSetup.Get then begin
            EnableCRMConnection := true;
            EnableCRMConnectionEnabled := not CRMConnectionSetup."Is Enabled";
            EnableSalesOrderIntegration := true;
            EnableSalesOrderIntegrationEnabled := not CRMConnectionSetup."Is S.Order Integration Enabled";
            ImportSolution := true;
            if CRMConnectionSetup."Is CRM Solution Installed" then begin
                ImportCRMSolutionEnabled := false;
                "Dynamics NAV OData Username" := CRMConnectionSetup."Dynamics NAV OData Username";
                "Dynamics NAV OData Accesskey" := CRMConnectionSetup."Dynamics NAV OData Accesskey";
            end;
        end else begin
            if ImportCRMSolutionEnabled then
                ImportSolution := true;
            if EnableCRMConnectionEnabled then
                EnableCRMConnection := true;
        end;
    end;

    local procedure FinalizeSetup(): Boolean
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        AdminEmail: Text[250];
        AdminPassword: Text;
    begin
        if ImportSolution and ImportCRMSolutionEnabled then begin
            if not PromptForCredentials(AdminEmail, AdminPassword) then
                exit(false);
            CRMIntegrationManagement.ImportCRMSolution(
              "Server Address", "User Name", AdminEmail, AdminPassword, "Proxy Version");
        end;
        if PublishItemAvailabilityService then
            CRMIntegrationManagement.SetupItemAvailabilityService;

        CRMIntegrationManagement.InitializeCRMSynchStatus();
        CRMConnectionSetup.UpdateFromWizard(Rec, Password);
        if EnableCRMConnection then
            CRMConnectionSetup.EnableCRMConnectionFromWizard;
        if EnableSalesOrderIntegration and EnableSalesOrderIntegrationEnabled then
            CRMConnectionSetup.SetCRMSOPEnabledWithCredentials(AdminEmail, AdminPassword, true);
        if PublishItemAvailabilityService and PublishItemAvailabilityServiceEnabled then begin
            CRMIntegrationManagement.SetCRMNAVConnectionUrl(GetUrl(CLIENTTYPE::Web));
            CRMIntegrationManagement.SetCRMNAVODataUrlCredentials(
              CRMIntegrationManagement.GetItemAvailabilityWebServiceURL,
              "Dynamics NAV OData Username", "Dynamics NAV OData Accesskey");
        end;
        exit(true);
    end;

    local procedure OnImportSolutionChange()
    begin
        PublishItemAvailabilityServiceEnabled := ImportSolution;
        PublishItemAvailabilityService := ImportSolution;
    end;

    local procedure UpdateUserWebKey(User: Record User)
    var
        EnvironmentInfo: Codeunit "Environment Information";
        IdentityManagement: Codeunit "Identity Management";
        SetWebServiceAccessKey: Page "Set Web Service Access Key";
    begin
        "Dynamics NAV OData Accesskey" := IdentityManagement.GetWebServicesKey(User."User Security ID");
        if not (EnvironmentInfo.IsSaaS and (UserSecurityId <> User."User Security ID")) and
           ("Dynamics NAV OData Accesskey" = '')
        then
            if Confirm(MustUpdateClientsQst) then begin
                User.SetCurrentKey("User Security ID");
                User.SetRange("User Name", User."User Name");
                SetWebServiceAccessKey.SetRecord(User);
                SetWebServiceAccessKey.SetTableView(User);
                if SetWebServiceAccessKey.RunModal = ACTION::OK then
                    "Dynamics NAV OData Accesskey" := IdentityManagement.GetWebServicesKey(User."User Security ID");
            end;
        CurrPage.Update;
    end;

    local procedure InitializeDefaultProxyVersion()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        Validate("Proxy Version", CRMIntegrationManagement.GetLastProxyVersionItem);
    end;
}

