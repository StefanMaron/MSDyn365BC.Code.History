page 7201 "CDS Connection Setup Wizard"
{
    Caption = 'Common Data Service Connection Setup', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';

    PageType = NavigatePage;
    SourceTable = "CDS Connection Setup";
    SourceTableTemporary = true;
    Extensible = false;

    layout
    {
        area(content)
        {
            group(BannerStandard)
            {
                Caption = '';
                Editable = false;
                Visible = TopBannerVisible and not CredentialsStepVisible;
                field(MediaResourceStandardReference; MediaResourcesStandard."Media Reference")
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
                Visible = TopBannerVisible and CredentialsStepVisible;
                field(MediaResourceDoneReference; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Step0)
            {
                Visible = InfoStepVisible;

                Caption = '';
                group(Control1)
                {
                    InstructionalText = 'Connect Business Central to Common Data Service to synchronize data with other business apps.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';
                    ShowCaption = false;
                }
                group(Control2)
                {
                    InstructionalText = 'Quickly set up the connection, couple records, and even synchronize data.';
                    ShowCaption = false;
                }
                group(Control3)
                {
                    InstructionalText = 'If you choose Next we will try to find your Common Data Service environments so you can choose the one to connect to.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';
                    ShowCaption = false;
                }
            }
            group(Step1)
            {
                Visible = AdminStepVisible;

                group(Control11)
                {
                    Caption = 'SET UP THE CONNECTION';
                    InstructionalText = 'Specify the URL of the Common Data Service environment. Your environments appear in the list, or you can enter the URL.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';
                }

                field(ServerAddress; "Server Address")
                {
                    ApplicationArea = Suite;
                    AssistEdit = true;
                    ToolTip = 'The Common Data Service environment URL.';
                    Caption = 'The Common Data Service environment URL.';
                    ShowCaption = false;

                    trigger OnValidate()
                    begin
                        CDSIntegrationImpl.CheckModifyConnectionURL("Server Address");
                        if "Server Address" <> xRec."Server Address" then begin
                            HasAdminSignedIn := false;
                            NextActionEnabled := false;
                        end;
                        CurrPage.Update();
                    end;

                    trigger OnAssistEdit()
                    var
                        CDSEnvironment: Codeunit "CDS Environment";
                        AuthenticationType: Option Office365,AD,IFD,OAuth;
                    begin
                        AuthenticationType := "Authentication Type";

                        CDSEnvironment.SelectTenantEnvironment(Rec, CDSEnvironment.GetGlobalDiscoverabilityToken(), false);
                        "Authentication Type" := AuthenticationType;

                        if "Server Address" <> xRec."Server Address" then begin
                            HasAdminSignedIn := false;
                            NextActionEnabled := false;
                        end;
                        CurrPage.Update();
                    end;
                }

                group(Control12)
                {
                    InstructionalText = 'Sign in with an administrator user account and give consent to the application that will be used to connect to Common Data Service. The account will be used one time to install and configure components that the integration requires.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';
                    ShowCaption = false;
                }

                group(Control13)
                {
                    Visible = not HasAdminSignedIn;
                    ShowCaption = false;

                    field(SignInAdmin; SignInAdminTxt)
                    {
                        Caption = 'Sign in';
                        ShowCaption = false;
                        Editable = false;
                        ApplicationArea = Suite;

                        trigger OnDrillDown()
                        begin
                            if "Server Address" = '' then
                                Error(NoEnvironmentSelectedErr);

                            HasAdminSignedIn := true;
                            CDSIntegrationImpl.SignInCDSAdminUser(Rec, CrmHelper, AdminUserName, AdminPassword, AdminAccessToken);

                            AreAdminCredentialsCorrect := true;
                            SetPassword(UserPassword);
                            NextActionEnabled := true;

                            CurrPage.Update(false);
                        end;
                    }
                }

                group(Control14)
                {
                    Visible = HasAdminSignedIn and AreAdminCredentialsCorrect;
                    ShowCaption = false;

                    field(SuccesfullyLoggedIn; SuccesfullyLoggedInTxt)
                    {
                        ApplicationArea = Suite;
                        ToolTip = 'Indicates whether the administrator user has logged in successfully.';
                        Caption = 'The administrator is signed in.';
                        Editable = false;
                        ShowCaption = false;
                        Style = Favorable;
                    }
                }

                group(Control15)
                {
                    Visible = HasAdminSignedIn and (not AreAdminCredentialsCorrect);
                    ShowCaption = false;

                    field(UnsuccesfullyLoggedIn; UnsuccesfullyLoggedInTxt)
                    {
                        ApplicationArea = Suite;
                        Tooltip = 'Indicates that the administrator user has not logged in successfully';
                        Caption = 'Could not sign in the administrator.';
                        Editable = false;
                        ShowCaption = false;
                        Style = Unfavorable;
                    }
                }

                group(Control16)
                {
                    InstructionalText = 'To install and configure integration components, choose Next. This might take a few moments.';
                    ShowCaption = false;
                }

            }
            group(Step2)
            {
                Caption = '';
                Visible = CredentialsStepVisible;
                group("Integration User")
                {
                    Caption = '';
                    InstructionalText = 'Provide credentials for the user account that the business apps will use to authenticate when they exchange data. This should be an account that is used only for integration with Common Data Service.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';

                    group(Control22)
                    {
                        InstructionalText = 'This account must be a valid user in Common Data Service and must not be assigned to the System Administrator role. When you finish this guide the account will become non-interactive.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';
                        ShowCaption = false;
                    }

                    field(Email; "User Name")
                    {
                        ApplicationArea = Suite;
                        Caption = 'User Name';
                        ExtendedDatatype = EMail;
                        ToolTip = 'Specifies the email of the user that will be used to connect to the Common Data Service environment and synchronize data. This must not be the administrator user account.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';

                        trigger OnValidate()
                        begin
                            CDSIntegrationImpl.CheckUserName(Rec);
                        end;
                    }
                    field(Password; UserPassword)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Password';
                        ExtendedDatatype = Masked;
                        ToolTip = 'Specifies the password of the user that will be used to connect to the Common Data Service environment and synchronize data.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';

                        trigger OnValidate()
                        begin
                            SetPassword(UserPassword);
                        end;
                    }
                }

            }
            group(Step3)
            {
                Caption = '';
                Visible = OwnershipModelStepVisible;
                group("Ownership Model Selection")
                {
                    Caption = 'Choose an ownership model.';
                    InstructionalText = 'People or a team own records in Common Data Service that are created from data in Business Central. We recommend the Team model.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';

                    field("Ownership Model"; TempCDSConnectionSetup."Ownership Model")
                    {
                        Caption = 'Ownership Model';
                        ShowCaption = false;
                        ApplicationArea = Suite;
                        ToolTip = 'Specifies the type of owner that will be assigned to any record that is created while synchronizing from Business Central to Common Data Service.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';

                        trigger OnValidate()
                        begin
                            IsPersonOwnershipModelSelected := TempCDSConnectionSetup."Ownership Model" = TempCDSConnectionSetup."Ownership Model"::Person;
                            CurrPage.Update(false);
                        end;

                    }
                }
                group("Team Ownership Model")
                {
                    Caption = '';
                    InstructionalText = 'We will create a business unit and a team in Common Data Service. Members of the team will own the synchronized data and can assign records to other users or teams in the business unit.';
                    Visible = not IsPersonOwnershipModelSelected;
                }
                group("Salesperson Ownership Model")
                {
                    Caption = '';
                    InstructionalText = 'Couple salespersons in Business Central with users in Common Data Service. All synchronized data will be automatically owned by salesperson coupled to users. Owner (person) will be able to assign synchronized records to other users or teams in business unit.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';
                    Visible = IsPersonOwnershipModelSelected;
                }

                group("Skip Synchronization")
                {
                    Caption = 'Complete setup without synchronization';
                    InstructionalText = 'Choose this option to enable the connection without synchronizing data.';
                    field(FinishWithoutSynchronizingData; FinishWithoutSynchronizingData)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Complete without synchronization ';
                        ShowCaption = false;
                        ToolTip = 'Complete the Common Data Service Assisted Setup without synchronizing data.';

                        trigger OnValidate()
                        begin
                            if FinishWithoutSynchronizingData then begin
                                NextActionEnabled := false;
                                FinishActionEnabled := true;
                            end else begin
                                NextActionEnabled := true;
                                FinishActionEnabled := false;
                            end;

                            CurrPage.Update(false);
                        end;
                    }
                    group(Control31)
                    {
                        Visible = FinishWithoutSynchronizingData;
                        InstructionalText = 'When you choose Finish, the Common Data Service connection is enabled and you can start synchronizing data.';
                        ShowCaption = false;
                    }
                }
            }
            group(Step4)
            {
                Visible = CoupleSalespersonsStepVisible;
                Caption = '';
                InstructionalText = 'The Person ownership model requires that you couple salespersons in Business Central with users in Common Data Service before you synchronize data. Otherwise, synchronization will not be successful.';
                group(Control41)
                {
                    InstructionalText = 'The salespersons will own the synchronized data and can assign records to other users or teams in the business unit.';
                    ShowCaption = false;
                }
                field(CoupleSalesPeople; CoupleSalesPeopleTxt)
                {
                    Caption = 'Couple Salespeople';
                    ShowCaption = false;
                    Editable = false;
                    ApplicationArea = Suite;

                    trigger OnDrillDown()
                    var
                        CDSCoupleSalespersons: Page "CDS Couple Salespersons";
                    begin
                        SetPassword(UserPassword);
                        CDSIntegrationImpl.CheckConnectionRequiredFields(Rec, false);

                        CDSCoupleSalespersons.LookupMode := true;
                        CDSCoupleSalespersons.Initialize(CrmHelper);
                        if CDSCoupleSalespersons.RunModal() = Action::LookupOK then begin
                            CoupledSalesPeople := true;
                            AddCoupledUsersToDefaultOwningTeam();
                        end;

                        CurrPage.Update(false);
                    end;
                }

            }
            group(Step5)
            {
                Caption = 'Review Recommendations for first-time synchronization.';
                Visible = FullSynchReviewStepVisible;

                group(Control51)
                {
                    InstructionalText = 'First-time synchronization depends on whether there is data in both business apps and the direction.';
                    ShowCaption = false;
                }
                group(Control52)
                {
                    InstructionalText = 'If you have data in both apps and want bi-directional synchronization you must couple each record manually, either yourself, or with help from a Microsoft partner.';
                    ShowCaption = false;
                }
                group(Control53)
                {
                    InstructionalText = 'We can analyze both business apps and provide  recommendations for your first synchronization.';
                    ShowCaption = false;
                }
                field(SynchronizationRecommendations; SynchronizationRecommendationsLbl)
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Caption = 'Show initial synchronization recommendations list.';
                    ShowCaption = false;
                    Style = StrongAccent;
                    StyleExpr = TRUE;

                    trigger OnDrillDown()
                    var
                        CDSFullSynchReview: Page "CDS Full Synch. Review";
                    begin
                        Window.Open('Getting things ready for you.');
                        SetPassword(UserPassword);

                        CDSFullSynchReview.SetRecord(CRMFullSynchReviewLine);
                        CDSFullSynchReview.SetTableView(CRMFullSynchReviewLine);
                        CDSFullSynchReview.LookupMode := true;

                        Window.Close();
                        if CDSFullSynchReview.RunModal() = Action::LookupOK then;

                    end;
                }
                group(Control45)
                {
                    InstructionalText = 'After you choose Finish, you can follow the progress of your first synchronization on the Common Data Service Full Synch Review page. You might need to refresh the page to update the status.';
                    ShowCaption = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionBack)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Back';
                Enabled = BackActionEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                var
                    CDSConnectionSetup: Record "CDS Connection Setup";
                begin

                    if Step = Step::FullSynchReview then
                        if not IsPersonOwnershipModelSelected then begin
                            CDSConnectionSetup.Get();
                            CDSConnectionSetup.Validate("Is Enabled", false);
                            CDSConnectionSetup.Modify(true);
                            Commit();
                            NextStep(true, true);
                            exit;
                        end;

                    if Step = Step::CoupleSalespersons then begin
                        CDSConnectionSetup.Get();
                        CDSConnectionSetup.Validate("Is Enabled", false);
                        CDSConnectionSetup.Modify(true);
                        Commit();
                    end;

                    if Step = Step::OwnershipModel then
                        if "Authentication Type" = "Authentication Type"::Office365 then begin
                            // skip the user credentials step in Office365 authentication
                            // we don't use username/password authentication
                            // we inject an application user and use ClientId/ClientSecret authentication
                            NextStep(true, true);
                            exit;
                        end;

                    NextStep(true, false);
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
                var
                    AuthenticationType: Option Office365,AD,IFD,OAuth;
                begin
                    if Step = Step::Info then begin
                        AuthenticationType := "Authentication Type";
                        GetCDSEnvironment();
                        "Authentication Type" := AuthenticationType;
                    end;

                    if (Step = Step::Admin) then begin
                        if ("Server Address" = '') then
                            Error(URLShouldNotBeEmptyErr);

                        ImportCDSSOlution();

                        if "Authentication Type" = "Authentication Type"::Office365 then begin
                            // skip the user credentials step in Office365 authentication
                            // we don't use username/password authentication
                            // we inject an application user and use ClientId/ClientSecret authentication
                            NextStep(false, true);
                            exit;
                        end;
                    end;

                    if Step = Step::IntegrationUser then begin
                        if ("User Name" = '') or (UserPassword = '') then
                            Error(UsernameAndPasswordShouldNotBeEmptyErr);
                        SetPassword(UserPassword);
                        if not CDSIntegrationImpl.TryCheckCredentials(Rec) then
                            Error(WrongCredentialsErr);
                        CDSIntegrationImpl.CheckIntegrationUserPrerequisites(Rec, AdminUserName, AdminPassword, AdminAccessToken);
                    end;

                    if Step = Step::CoupleSalespersons then begin
                        if (CoupledSalesPeople = false) then
                            Error(SalespeoplShouldBeCoupledErr);
                        Window.Open('Getting things ready for you.');
                        CRMFullSynchReviewLine.DeleteAll();
                        CRMFullSynchReviewLine.Generate();
                        Commit();
                        Window.Close();
                    end;

                    if Step = Step::OwnershipModel then begin
                        Window.Open('Getting things ready for you.');
                        ConfigureCDSSolution();
                        if not IsPersonOwnershipModelSelected then begin
                            CRMFullSynchReviewLine.DeleteAll();
                            CRMFullSynchReviewLine.Generate();
                            Commit();
                            NextStep(false, true);
                            Window.Close();
                            exit;
                        end;
                    end;

                    NextStep(false, false);
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
                    CRMFullSynchReview: Page "CRM Full Synch. Review";
                    CDSCoupleSalespersons: Page "CDS Couple Salespersons";
                begin
                    if FinishWithoutSynchronizingData then begin
                        Window.Open('Getting things ready for you.');
                        ConfigureCDSSolution();
                        SendTraceTag('0000CDW', CategoryTok, Verbosity::Normal, FinishWithoutSynchronizingDataTxt, DataClassification::SystemMetadata);
                        if IsPersonOwnershipModelSelected then
                            if Confirm(OpenCoupleSalespeoplePageQst) then begin
                                Window.Close();
                                CDSCoupleSalespersons.Initialize(CrmHelper);
                                CDSCoupleSalespersons.Run();
                                AssistedSetup.Complete(PAGE::"CDS Connection Setup Wizard");
                                AddCoupledUsersToDefaultOwningTeam();
                                CurrPage.Close();
                                exit;
                            end;
                        Window.Close();
                        Page.Run(Page::"CDS Connection Setup");
                        AssistedSetup.Complete(PAGE::"CDS Connection Setup Wizard");
                        CurrPage.Close();
                        exit;
                    end;

                    Window.Open('Getting things ready for you.');
                    CRMFullSynchReviewLine.DeleteAll(true);

                    CRMFullSynchReview.SetSkipEntitiesNotFullSyncReady();
                    CRMFullSynchReviewLine.Generate(true);
                    CRMFullSynchReviewLine.Start();
                    CRMFullSynchReview.SetRecord(CRMFullSynchReviewLine);
                    CRMFullSynchReview.SetTableView(CRMFullSynchReviewLine);
                    CRMFullSynchReview.LookupMode := true;
                    SendTraceTag('0000CDZ', CategoryTok, Verbosity::Normal, FinishWithSynchronizingDataTxt, DataClassification::SystemMetadata);
                    Window.Close();
                    CRMFullSynchReview.Run();
                    AssistedSetup.Complete(PAGE::"CDS Connection Setup Wizard");
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnInit()
    begin
        LoadTopBanners();
    end;

    trigger OnOpenPage()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        Init();
        if CDSConnectionSetup.Get() then begin
            TempCDSConnectionSetup."Ownership Model" := CDSConnectionSetup."Ownership Model";
            "Server Address" := CDSConnectionSetup."Server Address";
            "User Name" := CDSConnectionSetup."User Name";
            UserPassword := CDSConnectionSetup.GetPassword();
            SetPassword(UserPassword);
        end else
            TempCDSConnectionSetup."Ownership Model" := TempCDSConnectionSetup."Ownership Model"::Team;
        IsPersonOwnershipModelSelected := TempCDSConnectionSetup."Ownership Model" = TempCDSConnectionSetup."Ownership Model"::Person;
        InitializeDefaultProxyVersion();
        Insert();
        Step := Step::Info;
        EnableControls();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        AssistedSetup: Codeunit "Assisted Setup";
    begin
        if CloseAction = ACTION::OK then
            if AssistedSetup.ExistsAndIsNotComplete(PAGE::"CDS Connection Setup Wizard") then
                if not Confirm(ConnectionNotSetUpQst, false) then
                    Error('');
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        TempCDSConnectionSetup: Record "CDS Connection Setup" temporary;
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        ClientTypeManagement: Codeunit "Client Type Management";
        CrmHelper: DotNet CrmHelper;
        Step: Option Info,Admin,IntegrationUser,OwnershipModel,CoupleSalespersons,FullSynchReview,Finish;
        Window: Dialog;
        [NonDebuggable]
        AdminAccessToken: Text;
        [NonDebuggable]
        AdminUserName: Text;
        [NonDebuggable]
        AdminPassword: Text;
        TopBannerVisible: Boolean;
        BackActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        FinishActionEnabled: Boolean;
        InfoStepVisible: Boolean;
        AdminStepVisible: Boolean;
        CredentialsStepVisible: Boolean;
        ImportSolutionStepVisible: Boolean;
        OwnershipModelStepVisible: Boolean;
        CoupleSalespersonsStepVisible: Boolean;
        FullSynchReviewStepVisible: Boolean;
        CoupledSalesPeople: Boolean;
        IsPersonOwnershipModelSelected: Boolean;
        HasAdminSignedIn: Boolean;
        AreAdminCredentialsCorrect: Boolean;
        FinishWithoutSynchronizingData: Boolean;
        GlobalDiscoUrlTokTxt: Label 'https://globaldisco.crm.dynamics.com/', Locked = true;
        OpenCoupleSalespeoplePageQst: Label 'The Person ownership model requires that you couple salespersons in Business Central with users in Common Data Service before you synchronize data. Otherwise, synchronization will not be successful.\\ Do you want to want to couple salespersons and users now?';
        SynchronizationRecommendationsLbl: Label 'Show synchronization recommendations';
        UserPassword: Text;
        SuccesfullyLoggedInTxt: Label 'The administrator is signed in.';
        UnsuccesfullyLoggedInTxt: Label 'Could not sign in the administrator.';
        SignInAdminTxt: Label 'Sign in with administrator user';
        CoupleSalesPeopleTxt: Label 'Couple Salespeople to Users';
        NoEnvironmentSelectedErr: Label 'To sign in the administrator user you must specify an environment.';
        ConnectionNotSetUpQst: Label 'The connection to Common Data Service environment has not been set up.\\Are you sure you want to exit?';
        WrongCredentialsErr: Label 'The credentials provided are incorrect.';
        UsernameAndPasswordShouldNotBeEmptyErr: Label 'You must specify a username and a password for the integration user';
        SalespeoplShouldBeCoupledErr: Label 'When the Person ownership model is selected, coupling of salespeople is required.';
        URLShouldNotBeEmptyErr: Label 'You must specify the URL of your Common Data Service environment.';
        AdminUserShouldBesignedInErr: Label 'The admin user must be connected in order to proceed.';
        CategoryTok: Label 'AL Common Data Service Integration', Locked = true;
        FinishWithoutSynchronizingDataTxt: Label 'User has chosen to finalize CDS configuration without synchronizing data.', Locked = true;
        FinishWithSynchronizingDataTxt: Label 'User has chosen to finalize CDS configuration also synchronizing data.', Locked = true;

    [NonDebuggable]
    [Scope('OnPrem')]
    local procedure GetCDSEnvironment()
    var
        CDSEnvironment: Codeunit "CDS Environment";
        OAuth2: Codeunit OAuth2;
        Token: Text;
    begin
        OAuth2.AcquireOnBehalfOfToken(CDSIntegrationImpl.GetRedirectURL(), GlobalDiscoUrlTokTxt, Token);
        CDSEnvironment.SelectTenantEnvironment(Rec, Token, false);
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType())) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue();
    end;

    local procedure NextStep(Backward: Boolean; SkipStep: Boolean)
    begin
        if Backward then
            Step := Step - 1
        else
            Step := Step + 1;

        if SkipStep then
            if Backward then
                Step := Step - 1
            else
                Step := Step + 1;

        EnableControls();
    end;

    local procedure EnableControls()
    begin
        case Step of
            Step::Info:
                ShowInfoStep();
            Step::Admin:
                ShowAdminStep();
            Step::IntegrationUser:
                ShowIntegrationUserStep();
            Step::OwnershipModel:
                ShowOwnershipModelStep();
            Step::CoupleSalespersons:
                ShowCoupleSalespersonsStep();
            Step::FullSynchReview:
                ShowFullSynchReviewStep();

        end;
    end;

    local procedure ShowInfoStep()
    begin
        BackActionEnabled := false;
        NextActionEnabled := true;
        FinishActionEnabled := false;

        InfoStepVisible := true;
        AdminStepVisible := false;
        CredentialsStepVisible := false;
        ImportSolutionStepVisible := false;
        OwnershipModelStepVisible := false;
        CoupleSalespersonsStepVisible := false;
        FullSynchReviewStepVisible := false;
    end;

    local procedure ShowAdminStep()
    begin
        BackActionEnabled := true;
        if HasAdminSignedIn then
            NextActionEnabled := true
        else
            NextActionEnabled := false;
        FinishActionEnabled := false;

        InfoStepVisible := false;
        AdminStepVisible := true;
        CredentialsStepVisible := false;
        ImportSolutionStepVisible := false;
        OwnershipModelStepVisible := false;
        CoupleSalespersonsStepVisible := false;
        FullSynchReviewStepVisible := false;

        "Authentication Type" := "Authentication Type"::Office365;
    end;

    local procedure ShowIntegrationUserStep()
    begin
        BackActionEnabled := true;
        NextActionEnabled := true;
        FinishActionEnabled := false;

        InfoStepVisible := false;
        AdminStepVisible := false;
        CredentialsStepVisible := true;
        OwnershipModelStepVisible := false;
        CoupleSalespersonsStepVisible := false;
        FullSynchReviewStepVisible := false;
    end;

    local procedure ShowOwnershipModelStep()
    begin
        BackActionEnabled := true;
        if FinishWithoutSynchronizingData then begin
            NextActionEnabled := false;
            FinishActionEnabled := true;
        end else begin
            NextActionEnabled := true;
            FinishActionEnabled := false;
        end;

        InfoStepVisible := false;
        AdminStepVisible := false;
        CredentialsStepVisible := false;
        ImportSolutionStepVisible := false;
        OwnershipModelStepVisible := true;
        CoupleSalespersonsStepVisible := false;
        FullSynchReviewStepVisible := false;

        CoupledSalesPeople := false;
    end;

    local procedure ShowCoupleSalespersonsStep()
    begin
        BackActionEnabled := true;
        NextActionEnabled := true;
        FinishActionEnabled := false;

        InfoStepVisible := false;
        AdminStepVisible := false;
        CredentialsStepVisible := false;
        ImportSolutionStepVisible := false;
        OwnershipModelStepVisible := false;
        CoupleSalespersonsStepVisible := true;
        FullSynchReviewStepVisible := false;

        CoupledSalesPeople := false;
    end;

    local procedure ShowFullSynchReviewStep()
    begin
        BackActionEnabled := true;
        NextActionEnabled := false;
        FinishActionEnabled := true;

        InfoStepVisible := false;
        AdminStepVisible := false;
        CredentialsStepVisible := false;
        ImportSolutionStepVisible := false;
        OwnershipModelStepVisible := false;
        CoupleSalespersonsStepVisible := false;
        FullSynchReviewStepVisible := true;
    end;

    local procedure InitializeDefaultProxyVersion()
    begin
        Validate("Proxy Version", CDSIntegrationImpl.GetLastProxyVersionItem());
    end;

    local procedure FinalizeSetup(IsEnabled: Boolean): Boolean
    begin
        "Ownership Model" := TempCDSConnectionSetup."Ownership Model";
        "Is Enabled" := IsEnabled;
        CDSIntegrationImpl.UpdateConnectionSetupFromWizard(Rec, UserPassword);
        exit(true);
    end;

    [NonDebuggable]
    local procedure ConfigureCDSSolution()
    var
        CDSConectionSetup: Record "CDS Connection Setup";
    begin
        if "Authentication Type" <> "Authentication Type"::Office365 then begin
            SetPassword(UserPassword);
            CDSIntegrationImpl.CheckCredentials(Rec);
        end;
        CDSIntegrationImpl.ConfigureIntegrationSolution(Rec, CrmHelper, AdminUserName, AdminPassword, AdminAccessToken, true);

        if not FinalizeSetup(true) then
            exit;

        if CDSConectionSetup.Get() then begin
            CDSIntegrationImpl.RegisterConnection(CDSConectionSetup, false);
            CDSIntegrationImpl.ActivateConnection();
            CDSIntegrationImpl.ClearConnectionDisableReason(CDSConectionSetup);
            CDSConectionSetup.EnableIntegrationTables();
        end;

        Commit();
    end;

    [NonDebuggable]
    local procedure ImportCDSSolution()
    begin
        if not HasAdminSignedIn then
            Error(AdminUserShouldBesignedInErr);

        Window.Open('Getting things ready for you.');
        CDSIntegrationImpl.ImportIntegrationSolution(Rec, CrmHelper, AdminUserName, AdminPassword, AdminAccessToken, false);
        Window.Close();
    end;

    local procedure AddCoupledUsersToDefaultOwningTeam()
    begin
        CDSIntegrationImpl.AddCoupledUsersToDefaultOwningTeam(Rec, CrmHelper);
    end;
}
