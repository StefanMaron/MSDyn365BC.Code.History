
page 1833 "Teams Centralized Deployment"
{
    Caption = 'Teams App Centralized Deployment';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = NavigatePage;
    ShowFilter = false;
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    AdditionalSearchTerms = 'Add-in, AddIn, M365, Microsoft 365, Addon, Install Teams, Set up Teams';

    layout
    {
        area(content)
        {
            group(TopBannerStandardGrp)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible AND NOT InstructionsStepVisible;
                field(MediaResourcesStandard; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(TopBannerDoneGrp)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible AND InstructionsStepVisible;
                field(MediaResourcesDone; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }

            // Introduction step
            group(Step1)
            {
                Caption = '';
                Visible = IntroStepVisible;
                group("Para1.1")
                {
                    Caption = 'Set up the Business Central app for Teams';
                    Visible = IsSaaS;
                    group("Para1.1.1")
                    {
                        Caption = '';
                        InstructionalText = 'Administrators can deploy Business Central app for Teams for specific users, groups, or the entire organization. By centralizing deployment, users receive the app in all of their Teams clients without having to add it themselves.';
                    }
                    field(LearnMoreOptionsToDeploy; LearnMoreOptionsToDeployLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = '';
                        ShowCaption = false;
                        Editable = false;
                        Visible = IsSaas;
                        trigger OnDrillDown()
                        begin
                            Hyperlink(LearnMoreOptionsToDeployFwdLinkTxt);
                        end;
                    }
                    group("Para1.1.3")
                    {
                        Caption = '';
                        InstructionalText = 'This doesn’t affect permissions assigned to users in Business Central.';
                    }
                }
                group("Para1.2")
                {
                    Caption = 'Let''s go!';
                    Visible = IsSaas;
                    InstructionalText = 'Choose Next to get started.';
                }
                group("Para1.3")
                {
                    Caption = 'This won’t work';
                    Visible = not IsSaaS;
                    group("Para1.2.1")
                    {
                        Caption = '';
                        InstructionalText = 'The Business Central app for Teams requires a Business Central online user account that is not compatible with how your Business Central is deployed.';
                    }
                }
            }

            // Instructions Step for M365
            group("Step2")
            {
                Caption = '';
                Visible = InstructionsStepVisible;
                group("Para2.1")
                {
                    Caption = 'Configure Microsoft 365';
                    group("Para2.1.1")
                    {
                        Caption = '';
                        InstructionalText = 'The Microsoft Teams admin center is where you configure Teams app setup policies for the organization. It requires the Teams Service admin role or the Global admin role.';
                    }
                    group("Para2.1.2")
                    {
                        Caption = '';
                        field(TeamAdminCenterSetup; TeamsAdminCenterLbl)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                            Editable = false;

                            trigger OnDrillDown()
                            begin
                                Hyperlink(TeamsAdminCenterFwdLinkTxt);
                            end;
                        }
                        group("Para2.1.2.2")
                        {
                            Caption = '';
                            InstructionalText = '2. Choose the policy to include the setting to preinstall the Business Central app.';
                        }
                        group("Para2.1.2.3")
                        {
                            Caption = '';
                            InstructionalText = '3. Choose ‘Add apps’ and find the app named Business Central.';
                        }
                        group("Para2.1.2.4")
                        {
                            Caption = '';
                            InstructionalText = '4. Configure any additional settings and save.';
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
                ApplicationArea = Basic, Suite;
                Caption = 'Back';
                Enabled = BackActionEnabled;
                Visible = BackActionVisible;
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
                Visible = NextActionVisible;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(false);
                end;
            }
            action(ActionDone)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Done';
                Visible = DoneActionVisible;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                var
                    GuidedExperience: Codeunit "Guided Experience";
                begin
                    Session.LogMessage('0000FLQ', SetupTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TeamsAppTelemetryCategoryTxt);
                    GuidedExperience.CompleteAssistedSetup(ObjectType::Page, PAGE::"Teams Centralized Deployment");
                    CurrPage.Close();
                end;
            }
            action(ActionOkay)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Okay';
                Visible = OkayActionVisible;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    Session.LogMessage('0000FLR', SetupTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TeamsAppTelemetryCategoryTxt);
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnInit()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        LoadTopBanners();
        IsSaaS := EnvironmentInformation.IsSaaS();
    end;

    trigger OnOpenPage()
    begin
        ShowIntroStep();
    end;

    local procedure NextStep(Backwards: Boolean)
    begin
        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;

        case Step of
            Step::Intro:
                ShowIntroStep();
            Step::Instructions:
                ShowInstructionsStep();
        end;

        CurrPage.Update(true);
    end;

    local procedure ShowIntroStep()
    begin
        ResetWizardControls();
        IntroStepVisible := true;
        if not IsSaaS then begin
            BackActionVisible := false;
            OkayActionVisible := true;
            exit;
        end;
        NextActionVisible := true;
    end;

    local procedure ShowInstructionsStep()
    begin
        ResetWizardControls();
        InstructionsStepVisible := true;
        BackActionEnabled := true;
        NextActionVisible := false;
        DoneActionVisible := true;
    end;

    local procedure ResetWizardControls()
    begin
        // Buttons
        BackActionEnabled := false;
        BackActionVisible := true;
        NextActionVisible := false;
        DoneActionVisible := false;
        OkayActionVisible := false;

        // Tabs
        IntroStepVisible := false;
        InstructionsStepVisible := false;
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

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        ClientTypeManagement: Codeunit "Client Type Management";
        Step: Option Intro,Instructions;
        BackActionEnabled: Boolean;
        BackActionVisible: Boolean;
        NextActionVisible: Boolean;
        DoneActionVisible: Boolean;
        OkayActionVisible: Boolean;
        TopBannerVisible: Boolean;
        IntroStepVisible: Boolean;
        InstructionsStepVisible: Boolean;
        IsSaaS: Boolean;
        LearnMoreOptionsToDeployFwdLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2164137', Locked = true;
        LearnMoreOptionsToDeployLbl: Label 'Learn about options to deploy Teams apps';
        TeamsAdminCenterFwdLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2163970', Locked = true;
        TeamsAdminCenterLbl: Label '1. In the Teams admin center, go to ‘Teams apps > Setup policies’.';
        SetupTelemetryTxt: Label 'Centralized deployment for Teams setup finished', Locked = true;
        TeamsAppTelemetryCategoryTxt: Label 'AL Teams App', Locked = true;
}
