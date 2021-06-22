page 1806 "Exchange Setup Wizard"
{
    Caption = 'Office Add-In Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = NavigatePage;
    ShowFilter = false;
    SourceTable = "Office Add-in";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Control96)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible AND NOT DoneVisible;
                field("MediaResourcesStandard.""Media Reference"""; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control98)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible AND DoneVisible;
                field("MediaResourcesDone.""Media Reference"""; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Step1)
            {
                Caption = '';
                Visible = IntroVisible;
                group("Para1.1")
                {
                    Caption = 'Welcome to Office Add-In Setup';
                    group("Para1.1.1")
                    {
                        Caption = '';
                        InstructionalText = 'You can set up Office add-ins in Exchange or Exchange Online to complete business tasks without leaving your Outlook inbox.';
                    }
                }
                group("Para1.2")
                {
                    Caption = 'Let''s go!';
                    InstructionalText = 'Choose Next so you can set up Office add-ins.';
                }
            }
            group(Step2)
            {
                Caption = '';
                Visible = DeploymentModeVisible;
                group("Para2.1")
                {
                    Caption = 'Do you want to set up the add-ins for your organization or only for you?';
                    field(DeploymentMode; DeploymentMode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Set up for:';
                        OptionCaption = 'My Mailbox,My Organization';
                    }
                }
            }
            group("Step2.1")
            {
                Caption = '';
                Visible = O365Visible;
                field(UseO365; EmailIsHostedO365)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Is your email hosted in Office 365?';
                    DrillDown = true;

                    trigger OnValidate()
                    begin
                        if IsSaaS and not EmailIsHostedO365 then
                            Error(UnavailableInSaaS);
                    end;
                }
            }
            group(Step3)
            {
                Caption = '';
                Visible = CredentialsVisible;
                group("Step3.1")
                {
                    Caption = 'Provide your credentials for Exchange or Exchange Online.';
                    Visible = NOT OnPremOrgDeploy;
                    field(Email; Email)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Email';
                        ExtendedDatatype = EMail;

                        trigger OnValidate()
                        begin
                            CredentialsValidated := false;
                        end;
                    }
                    field(Password; Password)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Password';
                        ExtendedDatatype = Masked;

                        trigger OnValidate()
                        begin
                            CredentialsValidated := false;
                        end;
                    }
                    group(Control20)
                    {
                        Caption = '';
                        Visible = DeploymentMode = DeploymentMode::Organization;
                        label(Administrator)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'You must specify credentials for an administrative account.';
                            Style = Attention;
                            StyleExpr = TRUE;
                        }
                    }
                }
                group("Step3.2")
                {
                    Caption = '';
                    Visible = OnPremOrgDeploy;
                    field(ExchangeUserName; UserName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Exchange administrator user name';
                    }
                    field(ExchangePassword; Password)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Exchange administrator password';
                        ExtendedDatatype = Masked;
                    }
                    field(ExchangeEndpoint; PSEndpoint)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Exchange PowerShell endpoint';
                    }
                }
            }
            group(Step4)
            {
                Caption = '';
                Visible = EmailVisible;
                group("Para4.1")
                {
                    Caption = 'Receive a sample email message to evaluate the add-ins';
                    group("Para4.1.1")
                    {
                        Caption = '';
                        InstructionalText = 'We can send you a sample email message from a contact in this evaluation company so that you can try out the Outlook add-in experience. To have a sample email sent to your inbox, select the checkbox.';
                    }
                    field(SetupEmails; SetupEmails)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Send sample email message';
                    }
                }
            }
            group(Step5)
            {
                Caption = '';
                Visible = DoneVisible;
                group("That's it!")
                {
                    Caption = 'That''s it!';
                    InstructionalText = 'Choose Finish to enable Office add-ins in Exchange Online.';
                    Visible = NOT OnPremOrgDeploy;
                }
                group(Control30)
                {
                    Caption = 'That''s it!';
                    InstructionalText = 'Choose Finish to enable Office add-ins in Exchange.';
                    Visible = OnPremOrgDeploy;
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
                ApplicationArea = Basic, Suite;
                Caption = 'Next';
                Enabled = NextEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    if Step = Step::Credentials then
                        ValidateCredentials;
                    NextStep(false);
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Finish';
                Enabled = FinishEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                var
                    AssistedSetup: Codeunit "Assisted Setup";
                begin
                    DeployToExchange;
                    AssistedSetup.Complete(PAGE::"Exchange Setup Wizard");
                    CurrPage.Close;
                end;
            }
        }
    }

    trigger OnInit()
    var
        User: Record User;
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        IsSaaS := EnvironmentInformation.IsSaaS();
        User.SetRange("User Name", UserId);
        if User.FindFirst then
            Email := User."Authentication Email";

        LoadTopBanners;
        CredentialsRequired := (Email = '') or ExchangeAddinSetup.CredentialsRequired(Email);
        EmailIsHostedO365 := true;
    end;

    trigger OnOpenPage()
    begin
        ShowIntroStep;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        AssistedSetup: Codeunit "Assisted Setup";
        Info: ModuleInfo;
    begin
        if CloseAction = ACTION::OK then
            if AssistedSetup.ExistsAndIsNotComplete(PAGE::"Exchange Setup Wizard") then
                if not Confirm(NAVNotSetUpQst, false) then
                    Error('');
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        ExchangeAddinSetup: Codeunit "Exchange Add-in Setup";
        ClientTypeManagement: Codeunit "Client Type Management";
        Step: Option Intro,DeploymentMode,UseO365,Credentials,Email,Done;
        Email: Text[80];
        UserName: Text[80];
        Password: Text[30];
        PSEndpoint: Text[250];
        EmailIsHostedO365: Boolean;
        DeploymentMode: Option User,Organization;
        BackEnabled: Boolean;
        NextEnabled: Boolean;
        FinishEnabled: Boolean;
        TopBannerVisible: Boolean;
        IntroVisible: Boolean;
        DeploymentModeVisible: Boolean;
        O365Visible: Boolean;
        CredentialsVisible: Boolean;
        EmailVisible: Boolean;
        DoneVisible: Boolean;
        IsSaaS: Boolean;
        NAVNotSetUpQst: Label 'No Office add-ins have been set up.\\Are you sure that you want to exit?';
        SetupEmails: Boolean;
        CredentialsRequired: Boolean;
        CredentialsValidated: Boolean;
        EmailPasswordMissingErr: Label 'Please enter a valid email address and password.';
        SkipDeployment: Boolean;
        UsernamePasswordMissingErr: Label 'Please enter a valid domain username and password.';
        SampleEndpointTxt: Label 'http://mail.cronus.com/PowerShell', Locked = true;
        OnPremOrgDeploy: Boolean;
        ConnectingMsg: Label 'Connecting to Exchange.';
        DeployAccountMsg: Label 'Deploying add-ins for your account.';
        DeployOrgMsg: Label 'Deploying add-ins for your organization.';
        DeploySampleMailMsg: Label 'Deploying sample emails to your mailbox.';
        DeployAddInMsg: Label 'Deploying %1.', Comment = '%1 is the name of an Office add-in.';
        ProgressTemplateMsg: Label '#1##########\@2@@@@@@@@@@', Locked = true;
        UnavailableInSaaS: Label 'The business inbox in Outlook is only supported if your organization uses Office 365.';
        SetupTelemetryTxt: Label 'Setting up Outlook add-ins with deployment mode = %1', Locked = true;

    local procedure NextStep(Backwards: Boolean)
    begin
        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;

        case Step of
            Step::Intro:
                ShowIntroStep;
            Step::DeploymentMode:
                ShowDeploymentModeStep;
            Step::UseO365:
                ShowO365Step(Backwards);
            Step::Credentials:
                ShowCredentialsStep(Backwards);
            Step::Email:
                ShowEmailStep(Backwards);
            Step::Done:
                ShowDoneStep;
        end;

        CurrPage.Update(true);
    end;

    local procedure ShowIntroStep()
    begin
        ResetWizardControls;
        IntroVisible := true;
        BackEnabled := false;
    end;

    local procedure ShowDeploymentModeStep()
    begin
        ResetWizardControls;
        NextEnabled := true;
        DeploymentModeVisible := true;
        OnPremOrgDeploy := false;
    end;

    local procedure ShowO365Step(Backwards: Boolean)
    begin
        ResetWizardControls;
        NextEnabled := true;
        O365Visible := true;

        if DeploymentMode <> DeploymentMode::Organization then
            NextStep(Backwards);
    end;

    local procedure ShowCredentialsStep(Backwards: Boolean)
    begin
        ResetWizardControls;
        CredentialsVisible := true;
        OnPremOrgDeploy := (DeploymentMode = DeploymentMode::Organization) and (not EmailIsHostedO365);

        if OnPremOrgDeploy and (PSEndpoint = '') then
            PSEndpoint := SampleEndpointTxt;

        if not NeedCredentials then
            NextStep(Backwards);
    end;

    local procedure ShowEmailStep(Backwards: Boolean)
    begin
        ResetWizardControls;
        NextEnabled := true;
        EmailVisible := true;

        if (not ExchangeAddinSetup.SampleEmailsAvailable) or OnPremOrgDeploy then
            NextStep(Backwards);
    end;

    local procedure ShowDoneStep()
    begin
        ResetWizardControls;
        DoneVisible := true;
        NextEnabled := false;
        FinishEnabled := true;
    end;

    local procedure ResetWizardControls()
    begin
        // Buttons
        BackEnabled := true;
        NextEnabled := true;
        FinishEnabled := false;

        // Tabs
        IntroVisible := false;
        DeploymentModeVisible := false;
        CredentialsVisible := false;
        EmailVisible := false;
        DoneVisible := false;
        O365Visible := false;
    end;

    local procedure DeployToExchange()
    var
        OfficeAddin: Record "Office Add-in";
        AddinDeploymentHelper: Codeunit "Add-in Deployment Helper";
        OfficeMgt: Codeunit "Office Management";
        ProgressWindow: Dialog;
        Progress: Integer;
    begin
        if SkipDeployment then
            exit;
        ProgressWindow.Open(ProgressTemplateMsg);
        ProgressWindow.Update(1, ConnectingMsg);
        ProgressWindow.Update(2, 3000);

        if not OnPremOrgDeploy then
            if NeedCredentials then
                ExchangeAddinSetup.InitializeServiceWithCredentials(Email, Password);

        SendTraceTag('0000ACW', OfficeMgt.GetOfficeAddinTelemetryCategory(), Verbosity::Normal,
            StrSubstNo(SetupTelemetryTxt, Format(DeploymentMode)), DataClassification::SystemMetadata);

        if DeploymentMode = DeploymentMode::User then begin
            ProgressWindow.Update(1, DeployAccountMsg);
            ProgressWindow.Update(2, 6000);
            ExchangeAddinSetup.DeployAddins(OfficeAddin);
        end else
            if OfficeAddin.GetAddins then begin
                Progress := 4000;
                ProgressWindow.Update(1, DeployOrgMsg);
                ProgressWindow.Update(2, Progress);
                if OnPremOrgDeploy then begin
                    AddinDeploymentHelper.SetManifestDeploymentCustomEndpoint(PSEndpoint);
                    AddinDeploymentHelper.SetManifestDeploymentCredentials(UserName, Password);
                end else begin
                    AddinDeploymentHelper.SetManifestDeploymentCustomEndpoint(PSEndpoint);
                    AddinDeploymentHelper.SetManifestDeploymentCredentials(Email, Password);
                end;
                repeat
                    Progress += 1000;
                    ProgressWindow.Update(1, StrSubstNo(DeployAddInMsg, OfficeAddin.Name));
                    ProgressWindow.Update(2, Progress);
                    AddinDeploymentHelper.DeployManifest(OfficeAddin);
                until OfficeAddin.Next = 0;
            end;

        if SetupEmails then begin
            ProgressWindow.Update(1, DeploySampleMailMsg);
            ProgressWindow.Update(2, 9000);
            ExchangeAddinSetup.DeploySampleEmails(Email);
        end;

        ProgressWindow.Update(2, 10000);
        ProgressWindow.Close;
    end;

    local procedure ValidateCredentials()
    begin
        if SkipDeployment then
            exit;

        if OnPremOrgDeploy then begin
            if (UserName = '') or (Password = '') or (PSEndpoint = '') then
                Error(UsernamePasswordMissingErr);
        end else begin
            if NeedCredentials and not CredentialsValidated then begin
                if (Email = '') or (Password = '') then
                    Error(EmailPasswordMissingErr);
                ExchangeAddinSetup.InitializeServiceWithCredentials(Email, Password);
            end;
            CredentialsValidated := true;
        end;
    end;

    procedure SkipDeploymentToExchange(Skip: Boolean)
    begin
        SkipDeployment := Skip;
    end;

    local procedure NeedCredentials(): Boolean
    begin
        exit((DeploymentMode = DeploymentMode::Organization) or CredentialsRequired);
    end;

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
}

