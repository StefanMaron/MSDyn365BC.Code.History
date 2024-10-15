namespace System.Automation;

using System.Environment;
using System.Environment.Configuration;
using System.Privacy;

page 1837 "Automate Environment Picker"
{
    Caption = 'Power Automate Environment';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    Extensible = false;
    PageType = NavigatePage;
    ShowFilter = false;
    ApplicationArea = Basic, Suite;
    SourceTable = "Flow User Environment Buffer";
    SourceTableTemporary = true;
    AdditionalSearchTerms = 'Power Automate, install automate, environment, change environment, pick environment';

    layout
    {
        area(content)
        {
            group(TopBannerStandardGrp)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible AND NOT FinishStepVisible;
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
                Visible = TopBannerVisible AND FinishStepVisible;
                field(MediaResourcesDone; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Step1)
            {
                Caption = '';
                Visible = IntroStepVisible;
                group("Para1.1")
                {
                    Caption = 'Power Automate Environment picker';
                    group("Para1.1.1")
                    {
                        Caption = '';
                        InstructionalText = 'Business Central allows to build Power Automate flows that are shown as actions in “Automate” group on various pages or that are related to approval workflows.';
                    }
                    group("Para1.1.2")
                    {
                        Caption = '';
                        InstructionalText = 'This wizard allows you to explicitly choose which Power Platform environment to use for such features, providing all the flexibility you need as a user or maker. If you have relevant permissions, you will be able to propagate the environment choice for all users in your organization.';
                    }
                    group("Para1.1.3")
                    {
                        Caption = '';
                        InstructionalText = ' ';
                    }
                }
                group("Para1.2")
                {
                    Caption = 'Let''s go!';
                    InstructionalText = 'Choose your preferred Power Automate environment. Choose Next to get started.';
                }
            }

            group(Step2)
            {
                Caption = '';
                Visible = PrivacyNoticeStepVisible;

                group(PrivacyNotice)
                {
                    Caption = 'Your privacy is important to us';

                    group(PrivacyNoticeInner)
                    {
                        ShowCaption = false;
                        label(PrivacyNoticeLabel)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'This feature utilizes Power Automate. By continuing you are affirming that you understand that the data handling and compliance standards of Power Automate may not be the same as those provided by Microsoft Dynamics 365 Business Central. If you want to use Power Automate, you need to agree to its Privacy Notice. Otherwise, the change of environment has no effect.';
                        }
                        field(OpenPrivacyNotice; OpenPrivacyNoticeTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = false;
                            ShowCaption = false;

                            trigger OnDrillDown()
                            begin
                                PAGE.Run(Page::"Privacy Notices");
                            end;
                        }
                    }
                }
            }

            group(Step3)
            {
                Caption = '';
                Visible = ChoiceStepVisible;

                group(Choice)
                {
                    Caption = '';
                    repeater(Group)
                    {
                        field("Environment Display Name"; Rec."Environment Display Name")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Power Platform Environment Name';
                            Editable = false;
                            ToolTip = 'Specifies the name of the Power Platform environment.';

                            trigger OnDrillDown()
                            begin
                                EnsureOnlyOneSelection();
                            end;
                        }
                        field(Enabled; Rec.Enabled)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Selected';
                            ToolTip = 'Specifies if the Power Platform environment is selected.';

                            trigger OnValidate()
                            begin
                                EnsureOnlyOneSelection();
                            end;
                        }
                    }
                }
            }

            group(Step4)
            {
                Caption = '';
                Visible = FinishStepVisible;
                group("Para4.1")
                {
                    Caption = 'All done!';
                    group("Para4.1.1.All")
                    {
                        Caption = '';
                        Visible = HasChangedForAll;
                        InstructionalText = 'You selected for your organization: ';
                    }
                    group("Para4.1.1.Me")
                    {
                        Caption = '';
                        Visible = NOT HasChangedForAll;
                        InstructionalText = 'You selected just for you: ';
                    }
                    label(EnvironmentName)
                    {
                        ApplicationArea = All;
                        CaptionClass = EnvironmentDisplayNameText;
                    }
                    group("Para4.1.2")
                    {
                        Caption = '';
                        InstructionalText = 'This Power Automate environment will be now used for flows shown as actions in the “Automate” group and when you are adding new or managing already created workflows.';

                        group("Para4.1.2.1")
                        {
                            Caption = '';
                            InstructionalText = 'This change applies only to you; other users will still use their preferred Power Platform environment, or the default one if they didn''t make a decision.';
                        }
                        group("Para4.1.2.2")
                        {
                            Caption = '';
                            InstructionalText = 'We will now refresh the browser for the changes to take effect.';
                        }
                        group("Para4.1.2.3")
                        {
                            Caption = '';
                            InstructionalText = 'To learn more about integrating Business Central and Power Automate, visit:';
                        }
                        field(IntegratedAppsSetup; IntegratedAppsFwdLinkTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                            Editable = false;

                            trigger OnDrillDown()
                            begin
                                Hyperlink(IntegratedAppsFwdLinkTxt);
                            end;
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
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(true);
                end;
            }
            action(ActionChooseForAll)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Choose for your organization';
                ToolTip = 'Choose the Power Platform environment for all users in your organization.';
                Visible = ChooseActionVisible AND CanApproveForAll;

                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    If Confirm(ConfirmSelectionForAllTxt, false) then begin
                        HasChangedForAll := true;
                        FlowServiceManagement.SaveFlowEnvironmentSelectionForAll(Rec);
                        EnvironmentDisplayNameText := FlowServiceManagement.GetSelectedFlowEnvironmentName();
                        NextStep(false);
                    end;
                end;
            }
            action(ActionChooseForMe)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Choose';
                ToolTip = 'Choose the Power Platform environment just for you.';
                Visible = ChooseActionVisible;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    if HasSomethingChangedForInvidualChoice then
                        FlowServiceManagement.SaveFlowUserEnvironmentSelection(Rec);
                    EnvironmentDisplayNameText := FlowServiceManagement.GetSelectedFlowEnvironmentName();
                    NextStep(false);
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
                    GuidedExperience.CompleteAssistedSetup(ObjectType::Page, PAGE::"Automate Environment Picker");
                    CurrPage.Close();
                    RestartSession();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        ShowIntroStep();
        HasChangedForAll := false;
        CanApproveForAll := FlowServiceManagement.CanApproveForAll();
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
            Step::PrivacyNotice:
                ShowPrivacyNoticeStep();
            Step::Choice:
                ShowChoiceStep();
            Step::Finish:
                ShowFinishStep();
        end;

        CurrPage.Update(true);
    end;

    local procedure ShowIntroStep()
    begin
        ResetWizardControls();
        IntroStepVisible := true;
        BackActionEnabled := false;
    end;

    local procedure ShowPrivacyNoticeStep()
    begin
        ResetWizardControls();
        PrivacyNoticeStepVisible := true;
    end;

    local procedure ShowChoiceStep()
    begin
        // Make sure we reset before fetching to avoid "Record already exists" error
        Rec.Reset();
        Rec.DeleteAll();
        FlowServiceManagement.GetEnvironments(Rec);

        // Make sure we don't display list without any tick
        if not FlowServiceManagement.HasUserSelectedFlowEnvironment() then
            FlowServiceManagement.SetSelectedFlowEnvironmentIDToDefault();

        ResetWizardControls();
        ChoiceStepVisible := true;
        ChooseActionVisible := true;
        NextActionVisible := false;

        if Rec.IsEmpty() then
            Error(FlowServiceManagement.GetGenericError());

        SortByEnvironmentNameAscending();
        Rec.FindFirst();
    end;

    local procedure ShowFinishStep()
    begin
        ResetWizardControls();

        BackActionEnabled := false;
        FinishStepVisible := true;
        NextActionVisible := false;
        DoneActionVisible := true;
    end;

    local procedure ResetWizardControls()
    begin
        // Buttons
        BackActionEnabled := true;
        NextActionVisible := true;
        DoneActionVisible := false;
        ChooseActionVisible := false;

        // Tabs
        IntroStepVisible := false;
        PrivacyNoticeStepVisible := false;
        ChoiceStepVisible := false;
        FinishStepVisible := false;

        // Actions
        HasSomethingChangedForInvidualChoice := false;
    end;

    local procedure EnsureOnlyOneSelection()
    begin
        HasSomethingChangedForInvidualChoice := true;
        Rec.SetRange(Enabled, true);
        if Rec.Count >= 1 then
            Rec.ModifyAll(Enabled, false);

        Rec.Reset();
        Rec.Enabled := true;

        SortByEnvironmentNameAscending();
        CurrPage.Update();
    end;

    local procedure SortByEnvironmentNameAscending()
    begin
        Rec.SetCurrentKey("Environment Display Name");
        Rec.SetAscending("Environment Display Name", true);
    end;

    local procedure RestartSession()
    var
        SessionSetting: SessionSettings;
    begin
        SessionSetting.Init();
        SessionSetting.RequestSessionUpdate(false);
    end;


    var
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        FlowServiceManagement: Codeunit "Flow Service Management";
        Step: Option Intro,PrivacyNotice,Choice,Finish;
        BackActionEnabled: Boolean;
        NextActionVisible: Boolean;
        ChooseActionVisible: Boolean;
        DoneActionVisible: Boolean;
        TopBannerVisible: Boolean;
        IntroStepVisible: Boolean;
        PrivacyNoticeStepVisible: Boolean;
        ChoiceStepVisible: Boolean;
        FinishStepVisible: Boolean;
        HasSomethingChangedForInvidualChoice: Boolean;
        HasChangedForAll: Boolean;
        CanApproveForAll: Boolean;
        EnvironmentDisplayNameText: Text;
        IntegratedAppsFwdLinkTxt: Label 'https://aka.ms/bcautomate', Locked = true;
        OpenPrivacyNoticeTxt: Label 'Open Privacy Notice Page';
        ConfirmSelectionForAllTxt: Label 'If you choose the environment for your organization, it will override the current environment setting for all users. Users that have access to this page will still be able to change it later. This action cannot be reverted. Do you want to continue?';
}
