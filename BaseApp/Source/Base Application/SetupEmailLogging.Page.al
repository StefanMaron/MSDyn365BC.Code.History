#if not CLEAN22
namespace System.EMail;

using Microsoft.CRM.Outlook;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Setup;
using System;
using System.Environment;
using System.Environment.Configuration;
using System.Integration;
using System.Security.Encryption;
using System.Utilities;

page 1811 "Setup Email Logging"
{
    Caption = 'Email Logging Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = NavigatePage;
    ShowFilter = false;
    ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';

    layout
    {
        area(content)
        {
            group(Control96)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and not DoneVisible;
#pragma warning disable AA0100
                field("MediaResourcesStandard.""Media Reference"""; MediaResourcesStandard."Media Reference")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite, RelationshipMgmt;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control98)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and DoneVisible;
#pragma warning disable AA0100
                field("MediaResourcesDone.""Media Reference"""; MediaResourcesDone."Media Reference")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite, RelationshipMgmt;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Step1)
            {
                Caption = '';
                Visible = IntroVisible;
                group("Welcome to Email Logging Setup")
                {
                    Caption = 'Welcome to Email Logging Setup';
                    group(OAuth2)
                    {
                        Visible = not SoftwareAsAService;
                        Caption = '';
                        InstructionalText = 'This guide will help you to setup Email Logging with OAuth2 authentication flow to connect to Exchange.';
                    }
                    group(Control4)
                    {
                        Caption = '';
                        InstructionalText = 'Choose the following link to learn more about how to set up Exchange public folders and rules, so your organization can track email communication between sales people and external contacts.';
                    }
                    field(HelpLink; HelpLinkTxt)
                    {
                        ApplicationArea = RelationshipMgmt;
                        ShowCaption = false;
                        Editable = false;
                        Style = StandardAccent;

                        trigger OnDrillDown()
                        begin
                            Hyperlink(HelpLinkUrlTxt);
                            HelpLinkVisited := true;
                        end;
                    }
                    field(ManualSetupDone; ManualSetupDone)
                    {
                        Caption = 'Manual setup done';
                        ShowCaption = true;
                        Editable = HelpLinkVisited;
                        ApplicationArea = RelationshipMgmt;

                        trigger OnValidate()
                        begin
                            NextEnabled := ManualSetupDone;
                        end;
                    }
                }
            }
            group(Step2)
            {
                Visible = ClientCredentialsVisible;
                InstructionalText = 'Specify the ID and secret of the Microsoft Entra application that will be used to connect to Exchange.', Comment = 'Exchange and Microsoft Entra are names of a Microsoft service and a Microsoft Azure resource and should not be translated.';
                ShowCaption = false;

                group(ClientCredentials)
                {
                    Visible = not SoftwareAsAService;
                    ShowCaption = false;

                    field(ClientCredentialsLink; ClientCredentialsLinkTxt)
                    {
                        ShowCaption = false;
                        Editable = false;
                        ApplicationArea = RelationshipMgmt;

                        trigger OnDrillDown()
                        begin
                            CustomCredentialsSpecified := SetupEmailLogging.PromptClientCredentials(ClientId, ClientSecret, RedirectURL);
                            NextEnabled := CustomCredentialsSpecified;
                        end;
                    }
                }
                group(SpecifiedCustomClientCredentialsGroup)
                {
                    Visible = CustomCredentialsSpecified;
                    ShowCaption = false;

                    field(SpecifiedCustomClientCredentials; SpecifiedCustomClientCredentialsTxt)
                    {
                        ApplicationArea = RelationshipMgmt;
                        ToolTip = 'Indicates that the custom client credentials are specified and will be used to connect to Exchange.', Comment = 'Exchange is a name of a Microsoft service and should not be translated.';
                        Caption = 'Custom client ID and secret are specified and will be used to connect to Exchange.', Comment = 'Exchange is a name of a Microsoft service and should not be translated.';
                        Editable = false;
                        ShowCaption = false;
                        Style = Standard;
                    }
                }
                group(ClientCredentialsRequiredGroup)
                {
                    Visible = not CustomCredentialsSpecified;
                    ShowCaption = false;

                    field(ClientCredentialsRequired; ClientCredentialsRequiredTxt)
                    {
                        ApplicationArea = RelationshipMgmt;
                        ToolTip = 'Indicates that the client ID and secret are required to connect to Exchange.', Comment = 'Exchange is a name of a Microsoft service and should not be translated.';
                        Caption = 'Client ID and secret are required to connect to Exchange.', Comment = 'Exchange is a name of a Microsoft service and should not be translated.';
                        Editable = false;
                        ShowCaption = false;
                        Style = Standard;
                    }
                }
                group(DefaultClientCredentialsGroup)
                {
                    Visible = not CustomCredentialsSpecified;
                    ShowCaption = false;

                    field(DefaultClientCredentials; DefaultClientCredentialsTxt)
                    {
                        ApplicationArea = RelationshipMgmt;
                        ToolTip = 'Indicates that the default client credentials will be used to connect to Exchange.', Comment = 'Exchange is a name of a Microsoft service and should not be translated.';
                        Caption = 'The default client credentials will be used to connect to Exchange.', Comment = 'Exchange is a name of a Microsoft service and should not be translated.';
                        Editable = false;
                        ShowCaption = false;
                        Style = Standard;
                    }
                }
            }
            group(Step3)
            {
                InstructionalText = 'Sign in with an Exhange administrator user account and give consent to the application that will be used to connect to Exchange.', Comment = 'Exhange is a name of a Microsoft Service and should not be translated.';
                Visible = OAuth2Visible;
                ShowCaption = false;

                group(AdminSignIn)
                {
                    ShowCaption = false;

                    field(SignInAdminLink; SignInAdminLinkTxt)
                    {
                        ShowCaption = false;
                        Editable = false;
                        ApplicationArea = RelationshipMgmt;

                        trigger OnDrillDown()
                        begin
                            HasAdminSignedIn := true;
                            AreAdminCredentialsCorrect := SignInExchangeAdminUser();
                            NextEnabled := AreAdminCredentialsCorrect;
                            CurrPage.Update(false);
                        end;
                    }
                }
                group(AdminSignInSucceed)
                {
                    Visible = HasAdminSignedIn and AreAdminCredentialsCorrect;
                    ShowCaption = false;

                    field(SuccesfullyLoggedIn; SuccesfullyLoggedInTxt)
                    {
                        ApplicationArea = RelationshipMgmt;
                        ToolTip = 'Specifies if the Exchange administrator has logged in successfully.';
                        Caption = 'The administrator is signed in.';
                        Editable = false;
                        ShowCaption = false;
                        Style = Favorable;
                    }
                }
                group(AdminSignInFailed)
                {
                    Visible = HasAdminSignedIn and (not AreAdminCredentialsCorrect);
                    ShowCaption = false;

                    field(UnsuccesfullyLoggedIn; UnsuccesfullyLoggedInTxt)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Tooltip = 'Indicates that the Exhange administrator user has not logged in successfully';
                        Caption = 'Could not sign in the administrator.';
                        Editable = false;
                        ShowCaption = false;
                        Style = Unfavorable;
                    }
                }
            }
            group(Step4)
            {
                InstructionalText = 'Provide email of user on behalf of whom the scheduled job will connect to Exchange and process emails.', Comment = 'Exchange is a name of a Microsoft Service and should not be translated.';
                Visible = UserEmailVisible;
                ShowCaption = false;

                field(Email; UserEmail)
                {
                    ApplicationArea = RelationshipMgmt;
                    Tooltip = 'Specifies email of user on behalf of whom the scheduled job will connect to Exchange and process emails.', Comment = 'Exchange is a name of a Microsoft Service and should not be translated.';
                    Caption = 'User Email';
                    ExtendedDatatype = EMail;

                    trigger OnValidate()
                    begin
                        ValidateUserEmailLinkVisited := false;
                        IsUserEmailValid := false;
                        NextEnabled := false;
                    end;
                }
                group(ValidateUserEmailGroup)
                {
                    ShowCaption = false;

                    field(ValidateUserEmailLink; ValidateUserEmailLinkTxt)
                    {
                        ShowCaption = false;
                        Editable = false;
                        ApplicationArea = RelationshipMgmt;

                        trigger OnDrillDown()
                        begin
                            ValidateUserEmailLinkVisited := true;
                            IsUserEmailValid := InitializeExchangeWebServicesClient();
                            NextEnabled := IsUserEmailValid;
                        end;
                    }
                }
                group(ValidUserEmailGroup)
                {
                    Visible = ValidateUserEmailLinkVisited and IsUserEmailValid;
                    ShowCaption = false;

                    field(ValidEmail; ValidEmailTxt)
                    {
                        ApplicationArea = RelationshipMgmt;
                        ToolTip = 'Indicates that email is successfully validated.';
                        Caption = 'Email is successfully validated.';
                        Editable = false;
                        ShowCaption = false;
                        Style = Favorable;
                    }
                }
                group(InvalidUserEmailGroup)
                {
                    Visible = ValidateUserEmailLinkVisited and (not IsUserEmailValid);
                    ShowCaption = false;

                    field(InvalidEmail; InvalidEmailTxt)
                    {
                        ApplicationArea = RelationshipMgmt;
                        ToolTip = 'Indicates that email validation failed.';
                        Caption = 'Email validation failed.';
                        Editable = false;
                        ShowCaption = false;
                        Style = Unfavorable;
                    }
                }
            }
            group(Step5)
            {
                InstructionalText = 'The following public folders will be used for email logging.';
                Visible = ValidatePublicFoldersVisible;

                field(DefaultFolderSetup; DefaultFolderSetup)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Default Folder Setup';
                    trigger OnValidate()
                    begin
                        if DefaultFolderSetup then begin
                            QueueFolderPath := QueueFolderPathTxt;
                            StorageFolderPath := StorageFolderPath;
                        end;
                        ArePublicFoldersValid := false;
                        NextEnabled := false;
                    end;
                }
                field(QueueFolderPath; QueueFolderPath)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Queue Folder Path';
                    ToolTip = 'Specifies the name of the queue folder in Outlook.';
                    Editable = not DefaultFolderSetup;

                    trigger OnAssistEdit()
                    var
                        ExchangeFolder: Record "Exchange Folder";
                    begin
                        if DefaultFolderSetup then
                            exit;
                        ValidatePublicFoldersLinkVisited := false;
                        ArePublicFoldersValid := false;
                        NextEnabled := false;
                        if SetupEmailLogging.GetExchangeFolder(ExchangeWebServicesClient, ExchangeFolder, SelectQueueFolderTxt) then
                            QueueFolderPath := ExchangeFolder.FullPath;
                    end;
                }
                field(StorageFolderPath; StorageFolderPath)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Storage Folder Path';
                    ToolTip = 'Specifies the name of the storage folder in Outlook.';
                    Editable = not DefaultFolderSetup;

                    trigger OnAssistEdit()
                    var
                        ExchangeFolder: Record "Exchange Folder";
                    begin
                        if DefaultFolderSetup then
                            exit;
                        ValidatePublicFoldersLinkVisited := false;
                        ArePublicFoldersValid := false;
                        NextEnabled := false;
                        if SetupEmailLogging.GetExchangeFolder(ExchangeWebServicesClient, ExchangeFolder, SelectStorageFolderTxt) then
                            StorageFolderPath := ExchangeFolder.FullPath;
                    end;
                }
                group(ValidatePublicFoldersGroup)
                {
                    ShowCaption = false;

                    field(ValidatePublicFoldersLink; ValidatePublicFoldersLinkTxt)
                    {
                        ShowCaption = false;
                        Editable = false;
                        ApplicationArea = RelationshipMgmt;

                        trigger OnDrillDown()
                        begin
                            ValidatePublicFoldersLinkVisited := true;
                            ArePublicFoldersValid := ValidatePublicFolders();
                            NextEnabled := ArePublicFoldersValid;
                        end;
                    }
                }
                group(ValidPublicFoldersGroup)
                {
                    Visible = ValidatePublicFoldersLinkVisited and ArePublicFoldersValid;
                    ShowCaption = false;

                    field(ValidPublicFolders; ValidPublicFoldersTxt)
                    {
                        ApplicationArea = RelationshipMgmt;
                        ToolTip = 'Indicates that the public folders are successfully validated.';
                        Caption = 'Public folders are successfully validated.';
                        Editable = false;
                        ShowCaption = false;
                        Style = Favorable;
                    }
                }
                group(InvalidPublicFoldersGroup)
                {
                    Visible = ValidatePublicFoldersLinkVisited and (not ArePublicFoldersValid);
                    ShowCaption = false;

                    field(InvalidPublicFolders; InvalidPublicFoldersTxt)
                    {
                        ApplicationArea = RelationshipMgmt;
                        ToolTip = 'Indicates that the public folders validation failed.';
                        Caption = 'Public folders validation failed.';
                        Editable = false;
                        ShowCaption = false;
                        Style = Unfavorable;
                    }
                }
            }
            group(Step6)
            {
                Caption = '';
                Visible = DoneVisible;
                group(FinalStepDesc)
                {
                    Caption = 'That''s it!';
                    InstructionalText = 'When you choose Finish, the following will be created:';
                    group(Control33)
                    {
                        ShowCaption = false;
                        field(CreateEmailLoggingJobQueue; CreateEmailLoggingJobQueue)
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Create Email Logging Job Queue';
                        }
                        group(InvalidInteractionTemplateSetupGroup)
                        {
                            Visible = CreateEmailLoggingJobQueue and (not ValidInteractionTemplateSetup);
                            ShowCaption = false;
                            InstructionalText = 'Email Logging requires correctly configured Interaction Template Setup.';

                            field(InteractionTemplateSetupLink; InteractionTemplateSetupLinkTxt)
                            {
                                ApplicationArea = RelationshipMgmt;
                                ShowCaption = false;
                                Editable = false;
                                Style = StandardAccent;

                                trigger OnDrillDown()
                                var
                                    EmailLoggingDispatcher: Codeunit "Email Logging Dispatcher";
                                    ErrorMsg: Text;
                                begin
                                    Commit();
                                    Page.RunModal(Page::"Interaction Template Setup");
                                    ValidInteractionTemplateSetup := EmailLoggingDispatcher.CheckInteractionTemplateSetup(ErrorMsg);
                                end;
                            }
                            field(InvalidInteractionTemplateSetup; InvalidInteractionTemplateSetupTxt)
                            {
                                ApplicationArea = RelationshipMgmt;
                                ToolTip = 'Indicates that Interaction Template Setup needs to be configurred.';
                                Caption = 'Interaction Template Setup needs to be configurred.';
                                Editable = false;
                                ShowCaption = false;
                                Style = Unfavorable;
                            }
                        }
                        group(ValidInteractionTemplateSetupGroup)
                        {
                            Visible = CreateEmailLoggingJobQueue and ValidInteractionTemplateSetup;
                            ShowCaption = false;

                            field(ValidInteractionTemplateSetup; ValidInteractionTemplateSetupTxt)
                            {
                                ApplicationArea = RelationshipMgmt;
                                ToolTip = 'Indicates that Interaction Template Setup is correctly configurred.';
                                Caption = 'Interaction Template Setup is correctly configurred.';
                                Editable = false;
                                ShowCaption = false;
                                Style = Favorable;
                            }
                        }
                    }
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
                ApplicationArea = RelationshipMgmt;
                Caption = 'Back';
                ToolTip = 'Back';
                Enabled = BackEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(true);
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Next';
                ToolTip = 'Next';
                Enabled = NextEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(false);
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Finish';
                ToolTip = 'Finish';
                Enabled = FinishEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                var
                    MarketingSetup: Record "Marketing Setup";
                    GuidedExperience: Codeunit "Guided Experience";
                begin
                    if MarketingSetup.Get() then begin
                        SetupEmailLogging.ClearEmailLoggingSetup(MarketingSetup);
                        SetupEmailLogging.DeleteEmailLoggingJobQueueSetup();
                    end;

                    UpdateMarketingSetup(MarketingSetup);
                    MarketingSetup.SetQueueFolder(TempQueueExchangeFolder);
                    MarketingSetup.SetStorageFolder(TempStorageExchangeFolder);

                    if CreateEmailLoggingJobQueue then begin
                        Session.LogMessage('0000CIK', CreateEmailLoggingJobTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
                        SetupEmailLogging.CreateEmailLoggingJobQueueSetup();
                    end else
                        Session.LogMessage('0000CIL', SkipCreatingEmailLoggingJobTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

                    GuidedExperience.CompleteAssistedSetup(ObjectType::Page, PAGE::"Setup Email Logging");

                    Session.LogMessage('0000CIJ', EmailLoggingSetupCompletedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

                    OnAfterAssistedSetupEmailLoggingCompleted();
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnInit()
    var
        MarketingSetup: Record "Marketing Setup";
        EnvironmentInfo: Codeunit "Environment Information";
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
        [NonDebuggable]
        ClientSecretLocal: Text;
    begin
        LoadTopBanners();
        if SetupEmailLogging.IsEmailLoggingUsingGraphApiFeatureEnabled() then
            Error(EmailLoggingUsingGraphApiFeatureEnabledErr);
        SoftwareAsAService := EnvironmentInfo.IsSaaSInfrastructure();
        DefaultFolderSetup := true;
        QueueFolderPath := QueueFolderPathTxt;
        StorageFolderPath := StorageFolderPathTxt;

        if MarketingSetup.Get() then begin
            if not SoftwareAsAService then begin
                ClientId := MarketingSetup."Exchange Client Id";
                if not IsNullGuid(MarketingSetup."Exchange Client Secret Key") then
                    if IsolatedStorageManagement.Get(MarketingSetup."Exchange Client Secret Key", DataScope::Company, ClientSecretLocal) then
                        ClientSecret := CopyStr(ClientSecretLocal, 1, MaxStrLen(ClientSecret));
                RedirectURL := MarketingSetup."Exchange Redirect URL";
                CustomCredentialsSpecified := (ClientId <> '') or (ClientSecret <> '') or (RedirectURL <> '');
            end;
            if not IsNullGuid(MarketingSetup."Exchange Tenant Id Key") then
                IsolatedStorageManagement.Get(MarketingSetup."Exchange Tenant Id Key", DataScope::Company, TenantId);

            UserEmail := CopyStr(MarketingSetup."Exchange Account User Name", 1, MaxStrLen(UserEmail));

            DefaultFolderSetup :=
                (MarketingSetup."Queue Folder Path" = '') or
                (MarketingSetup."Storage Folder Path" = '') or
                ((MarketingSetup."Queue Folder Path" = QueueFolderPathTxt) and (MarketingSetup."Storage Folder Path" = StorageFolderPathTxt));
            if not DefaultFolderSetup then begin
                QueueFolderPath := MarketingSetup."Queue Folder Path";
                StorageFolderPath := MarketingSetup."Storage Folder Path";
            end;
        end;
    end;

    trigger OnOpenPage()
    begin
        ShowIntroStep();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        if CloseAction = ACTION::OK then
            if GuidedExperience.AssistedSetupExistsAndIsNotComplete(ObjectType::Page, PAGE::"Setup Email Logging") then
                if not Confirm(NAVNotSetUpQst, false) then
                    Error('');
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        TempQueueExchangeFolder: Record "Exchange Folder" temporary;
        TempStorageExchangeFolder: Record "Exchange Folder" temporary;
        SetupEmailLogging: Codeunit "Setup Email Logging";
        ClientTypeManagement: Codeunit "Client Type Management";
        ExchangeWebServicesClient: Codeunit "Exchange Web Services Client";
        AdminOAuthCredentials: DotNet OAuthCredentials;
        Step: Option Intro,Client,OAuth2,Email,PublicFolders,Done;
        [NonDebuggable]
        UserEmail: Text[80];
        [NonDebuggable]
        ClientId: Text[250];
        [NonDebuggable]
        ClientSecret: Text[250];
        RedirectURL: Text[2048];
        QueueFolderPath: Text;
        StorageFolderPath: Text;
        BackEnabled: Boolean;
        NextEnabled: Boolean;
        FinishEnabled: Boolean;
        TopBannerVisible: Boolean;
        IntroVisible: Boolean;
        OAuth2Visible: Boolean;
        UserEmailVisible: Boolean;
        ClientCredentialsVisible: Boolean;
        ManualSetupDone: Boolean;
        SoftwareAsAService: Boolean;
        DoneVisible: Boolean;
        HelpLinkVisited: Boolean;
        ValidatePublicFoldersVisible: Boolean;
        TenantId: Text;
        QueueFolderPathTxt: Label '\Email Logging\Queue\', Locked = true;
        StorageFolderPathTxt: Label '\Email Logging\Storage\', Locked = true;
        RootFolderPathTemplateTxt: Label '\%1\', Locked = true;
        PathDelimiterTxt: Label '\', Locked = true;
        DefaultFolderSetup: Boolean;
        NAVNotSetUpQst: Label 'Setup of Email Logging was not finished. \\Are you sure that you want to exit?';
        CreateEmailLoggingJobQueue: Boolean;
        EmailLoggingTelemetryCategoryTxt: Label 'AL Email Logging', Locked = true;
        UpdateMarketingSetupTxt: Label 'Update marketing setup record.', Locked = true;
        ConnectingToExchangeMsg: Label 'Connecting to Exchange.', Comment = 'Exchange is a name of a Microsoft service and should not be translated.';
        ValidatePublicFoldersMsg: Label 'Validating public folders.';
        HelpLinkTxt: Label 'Track Email Message Exchanges';
        HelpLinkUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115467', Locked = true;
        SuccesfullyLoggedInTxt: Label 'The administrator is signed in.';
        UnsuccesfullyLoggedInTxt: Label 'Could not sign in the administrator.';
        DefaultClientCredentialsTxt: Label 'The default client credentials will be used to connect to Exchange.', Comment = 'Exchange is a name of a Microsoft service and should not be translated.';
        SpecifiedCustomClientCredentialsTxt: Label 'Custom client ID and secret are specified and will be used to connect to Exchange.', Comment = 'Exchange is a name of a Microsoft service and should not be translated.';
        ClientCredentialsRequiredTxt: Label 'Client ID and secret are required to connect to Exchange.', Comment = 'Exchange is a name of a Microsoft service and should not be translated.';
        SignInAdminLinkTxt: Label 'Sign in with administrator user';
        ClientCredentialsLinkTxt: Label 'Specify custom client ID and secret';
        CannotAccessRootPublicFolderErr: Label 'Could not access the root public folder with the specified user.';
        CannotInitializeConnectionToExchangeErr: Label 'Could not initialize connection to Exchange.', Comment = 'Exchange is a name of a Microsoft service and should not be translated.';
        EmptyUserEmailErr: Label 'User email is empty.';
        CannotAccessRootPublicFolderTxt: Label 'Could not access the root public folder. User: %1, URL: %2.', Locked = true;
        CannotInitializeConnectionToExchangeTxt: Label 'Could not initialize connection to Exchange. User: %1, URL: %2.', Locked = true;
        ServiceInitializedTxt: Label 'Service has been initalized.', Locked = true;
        ServiceValidatedTxt: Label 'Service has been validated.', Locked = true;
        EmptyUserEmailTxt: Label 'User email is empty.', Locked = true;
        ValidateUserEmailLinkTxt: Label 'Check connection of behalf of the specified user';
        ValidEmailTxt: Label 'Connection check is successful.';
        InvalidEmailTxt: Label 'Connection check failed.';
        ValidatePublicFoldersLinkTxt: Label 'Validate public folders';
        ValidPublicFoldersTxt: Label 'Public folders are successfuly validated.';
        InvalidPublicFoldersTxt: Label 'Public folders validation failed.';
        SelectQueueFolderTxt: Label 'Select Queue folder';
        SelectStorageFolderTxt: Label 'Select Storage folder';
        InteractionTemplateSetupLinkTxt: Label 'Interaction Template Setup';
        ValidInteractionTemplateSetupTxt: Label 'Interaction Template Setup is correctly configured.';
        InvalidInteractionTemplateSetupTxt: Label 'Interaction Template Setup needs to be configured.';
        EmailLoggingSetupCompletedTxt: Label 'Email Logging Setup completed.', Locked = true;
        CreateEmailLoggingJobTxt: Label 'Create email logging job', Locked = true;
        SkipCreatingEmailLoggingJobTxt: Label 'Skip creating email logging job', Locked = true;
        EmailLoggingUsingGraphApiFeatureEnabledErr: Label 'The feature Email Logging using Graph API has been enabled. Please use the new setup.';
        HasAdminSignedIn: Boolean;
        AreAdminCredentialsCorrect: Boolean;
        CustomCredentialsSpecified: Boolean;
        ValidateUserEmailLinkVisited: Boolean;
        IsUserEmailValid: Boolean;
        ValidatePublicFoldersLinkVisited: Boolean;
        ArePublicFoldersValid: Boolean;
        ValidInteractionTemplateSetup: Boolean;

    local procedure NextStep(Backwards: Boolean)
    begin
        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;

        if SoftwareAsAService then
            if Step = Step::Client then
                NextStep(Backwards);

        case Step of
            Step::Intro:
                ShowIntroStep();
            Step::Client:
                ShowClientStep();
            Step::OAuth2:
                ShowOAuth2Step();
            Step::Email:
                ShowEmailStep();
            Step::PublicFolders:
                ShowPublicFoldersStep();
            Step::Done:
                ShowDoneStep();
        end;
        CurrPage.Update(true);
    end;

    local procedure ShowIntroStep()
    begin
        ResetWizardControls();
        IntroVisible := true;
        NextEnabled := ManualSetupDone;
        BackEnabled := false;
    end;

    local procedure ShowClientStep()
    begin
        ResetWizardControls();
        ClientCredentialsVisible := true;
    end;

    local procedure ShowOAuth2Step()
    begin
        ResetWizardControls();
        OAuth2Visible := true;
        if HasAdminSignedIn and (not AreAdminCredentialsCorrect) then
            HasAdminSignedIn := false;
        NextEnabled := AreAdminCredentialsCorrect;
    end;

    local procedure ShowEmailStep()
    begin
        ResetWizardControls();
        UserEmailVisible := true;
        NextEnabled := IsUserEmailValid;
    end;

    local procedure ShowPublicFoldersStep()
    begin
        ResetWizardControls();
        ValidatePublicFoldersVisible := true;
        NextEnabled := ArePublicFoldersValid;
    end;

    local procedure ShowDoneStep()
    var
        EmailLoggingDispatcher: Codeunit "Email Logging Dispatcher";
        ErrorMsg: Text;
    begin
        ResetWizardControls();
        DoneVisible := true;
        NextEnabled := false;
        ValidInteractionTemplateSetup := EmailLoggingDispatcher.CheckInteractionTemplateSetup(ErrorMsg);
        FinishEnabled := ValidInteractionTemplateSetup;
        CreateEmailLoggingJobQueue := true;
    end;

    local procedure ResetWizardControls()
    begin
        // Buttons
        BackEnabled := true;
        NextEnabled := true;
        FinishEnabled := false;

        // Tabs
        IntroVisible := false;
        ClientCredentialsVisible := false;
        OAuth2Visible := false;
        UserEmailVisible := false;
        ValidatePublicFoldersVisible := false;
        DoneVisible := false;
    end;

    [TryFunction]
    [NonDebuggable]
    local procedure SignInExchangeAdminUser()
    var
        Token: Text;
    begin
        if SoftwareAsAService then begin
            ClientId := '';
            ClientSecret := '';
            RedirectURL := '';
        end;

        SetupEmailLogging.PromptAdminConsent(ClientId, ClientSecret, RedirectURL, Token);
        SetupEmailLogging.ExtractTenantIdFromAccessToken(TenantId, Token);
        AdminOAuthCredentials := AdminOAuthCredentials.OAuthCredentials(Token);
    end;

    [TryFunction]
    [NonDebuggable]
    local procedure InitializeExchangeWebServicesClient()
    var
        TempExchangeFolder: Record "Exchange Folder" temporary;
        ClientOAuthCredentials: DotNet OAuthCredentials;
        ProgressWindow: Dialog;
        ServiceUri: Text;
        Token: SecretText;
    begin
        if UserEmail = '' then begin
            Session.LogMessage('0000D9X', EmptyUserEmailTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            Error(EmptyUserEmailErr);
        end;

        ServiceUri := SetupEmailLogging.GetDomainFromEmail(UserEmail);

        ProgressWindow.Open('#1');
        ProgressWindow.Update(1, ConnectingToExchangeMsg);

        ExchangeWebServicesClient.InvalidateService();

        SetupEmailLogging.GetClientCredentialsAccessToken(ClientId, ClientSecret, RedirectURL, TenantId, Token);
        CreateClientOAuthCredentials(ClientOAuthCredentials, Token);

        if not ExchangeWebServicesClient.InitializeOnServerWithImpersonation(UserEmail, ServiceUri, ClientOAuthCredentials) then begin
            Session.LogMessage('0000D9Y', StrSubstNo(CannotInitializeConnectionToExchangeTxt, UserEmail, ServiceUri), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            Error(CannotInitializeConnectionToExchangeErr);
        end;

        Session.LogMessage('0000D9Z', ServiceInitializedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

        ExchangeWebServicesClient.GetPublicFolders(TempExchangeFolder);
        if TempExchangeFolder.IsEmpty() then begin
            Session.LogMessage('0000DA0', StrSubstNo(CannotAccessRootPublicFolderTxt, UserEmail, ServiceUri), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            Error(CannotAccessRootPublicFolderErr);
        end;

        Session.LogMessage('0000DA1', ServiceValidatedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
        ProgressWindow.Close();
    end;

    [NonDebuggable]
    local procedure CreateClientOAuthCredentials(var OAuthCredentials: DotNet OAuthCredentials; Token: SecretText)
    begin
        OAuthCredentials := OAuthCredentials.OAuthCredentials(Token.Unwrap());
    end;

    [TryFunction]
    local procedure ValidatePublicFolders()
    var
        ProgressWindow: Dialog;
        PathSegments: List of [Text];
        RootFolderPath: Text;
    begin
        ProgressWindow.Open('#1');
        ProgressWindow.Update(1, ValidatePublicFoldersMsg);

        PathSegments := QueueFolderPath.Split(PathDelimiterTxt);
        RootFolderPath := StrSubstNo(RootFolderPathTemplateTxt, PathSegments.Get(2));
        ExchangeWebServicesClient.GetPublicFolders(TempQueueExchangeFolder);
        TempQueueExchangeFolder.Get(RootFolderPath);
        ExchangeWebServicesClient.GetPublicFolders(TempQueueExchangeFolder);
        TempQueueExchangeFolder.Get(QueueFolderPath);
        TempQueueExchangeFolder.CalcFields("Unique ID");

        PathSegments := StorageFolderPath.Split(PathDelimiterTxt);
        RootFolderPath := StrSubstNo(RootFolderPathTemplateTxt, PathSegments.Get(2));
        ExchangeWebServicesClient.GetPublicFolders(TempStorageExchangeFolder);
        TempStorageExchangeFolder.Get(RootFolderPath);
        ExchangeWebServicesClient.GetPublicFolders(TempStorageExchangeFolder);
        TempStorageExchangeFolder.Get(StorageFolderPath);
        TempStorageExchangeFolder.CalcFields("Unique ID");

        ProgressWindow.Close();
    end;

    [NonDebuggable]
    local procedure UpdateMarketingSetup(var MarketingSetup: Record "Marketing Setup")
    begin
        Session.LogMessage('0000BYP', UpdateMarketingSetupTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
        MarketingSetup.Validate("Exchange Service URL", SetupEmailLogging.GetDomainFromEmail(UserEmail));
        MarketingSetup.Validate("Autodiscovery E-Mail Address", UserEmail);
        MarketingSetup.Validate("Email Batch Size", 10);
        MarketingSetup.Validate("Exchange Account User Name", UserEmail);
        if CustomCredentialsSpecified then begin
            MarketingSetup.Validate("Exchange Client Id", ClientId);
            MarketingSetup.SetExchangeClientSecret(ClientSecret);
            MarketingSetup.Validate("Exchange Redirect URL", RedirectURL);
        end;
        MarketingSetup.SetExchangeTenantId(TenantId);
        MarketingSetup.Validate("Email Logging Enabled", true);
        MarketingSetup.Modify();
    end;

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

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssistedSetupEmailLoggingCompleted()
    begin
    end;
}
#endif
