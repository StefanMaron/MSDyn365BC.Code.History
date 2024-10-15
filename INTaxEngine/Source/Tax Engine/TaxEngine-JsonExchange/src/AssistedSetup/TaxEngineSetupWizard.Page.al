page 20364 "Tax Engine Setup Wizard"
{
    Caption = 'Tax Engine Setup';
    PageType = NavigatePage;
    Permissions = TableData "Tax Type" = rimd,
                  TableData "Tax Attribute" = rimd,
                  TableData "Tax Component" = rimd;

    layout
    {
        area(content)
        {
            group(Control96)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible AND not FinalStepVisible;
            }
            group(Control98)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible AND FinalStepVisible;
            }
            group("<MediaRepositoryDone>")
            {
                Visible = FirstStepVisible;

                group("Welcome to Tax Engine Setup")
                {
                    Caption = 'Welcome to Tax Engine Setup';
                    Visible = FirstStepVisible;

                    group(Control28)
                    {
                        InstructionalText = 'This assisted setup guide helps you automate Tax Engine setup.';
                        ShowCaption = false;
                    }
                }
                group("Let's go!")
                {
                    Caption = 'Let''s go!';

                    group(Control22)
                    {
                        InstructionalText = 'Choose Next to get started.';
                        ShowCaption = false;
                    }
                }
            }
            group(Control17)
            {
                ShowCaption = false;
                Visible = ManualTaxEngineStepVisible OR FinalStepVisible;

                group("That's it!")
                {
                    Caption = 'That''s it!';
                    InstructionalText = 'Tax Engine is set up and ready to go.';
                    Visible = FinalStepVisible;
                }
                group(Control30)
                {
                    InstructionalText = 'To apply the settings, choose Finish.';
                    ShowCaption = false;
                    Visible = FinalStepVisible;
                }
                group(Control25)
                {
                    InstructionalText = 'To review your Tax Engine settings later, open the Tax Engine Setup window.';
                    ShowCaption = false;
                    Visible = FinalStepVisible;
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
                ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Next';
                Enabled = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(false);
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Finish';
                Enabled = FinishActionEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                begin
                    if AutoTaxEngineSetupIsAllowed then
                        FinishAction()
                    else
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
    begin
        AutoTaxEngineSetupIsAllowed := WizardIsAllowed();
        if not AutoTaxEngineSetupIsAllowed then
            Step := Step::Finish;

        WizardNotification.Id := Format(CreateGuid());
        EnableControls();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        AssistedSetup: Codeunit "Assisted Setup";
    begin
        if CloseAction = Action::OK then
            if WizardIsAllowed() and AssistedSetup.ExistsAndIsNotComplete(Page::"Tax Engine Setup Wizard") then
                if not Confirm(NAVNotSetUpQst, false) then
                    Error('');
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        ClientTypeManagement: Codeunit "Client Type Management";
        WizardNotification: Notification;
        Step: Option Start,Finish;
        TopBannerVisible: Boolean;
        ManualTaxEngineStepVisible: Boolean;
        FirstStepVisible: Boolean;
        FinalStepVisible: Boolean;
        FinishActionEnabled: Boolean;
        BackActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        AutoTaxEngineSetupIsAllowed: Boolean;
        NAVNotSetUpQst: Label 'Tax Engine has not been set up.\\Are you sure you want to exit?';

    local procedure EnableControls()
    begin
        ResetControls();

        case Step of
            Step::Start:
                ShowStartStep();
            Step::Finish:
                if AutoTaxEngineSetupIsAllowed then
                    ShowFinishStep()
                else
                    ShowManualStep();
        end;
    end;

    local procedure FinishAction()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        TaxEngineAssistedSetup: Codeunit "Tax Engine Assisted Setup";
    begin
        if not AutoTaxEngineSetupIsAllowed then
            exit;

        ClearTaxEngineSetup();
        TaxEngineAssistedSetup.SetupTaxEngine();
        AssistedSetup.Complete(Page::"Tax Engine Setup Wizard");
        CurrPage.Close();
    end;

    local procedure NextStep(Backwards: Boolean)
    begin
        HideNotification();

        if Backwards then
            Step := Step - 1
        else
            if StepValidation() then
                Step := Step + 1;

        EnableControls();
    end;

    local procedure ShowManualStep()
    begin
        ManualTaxEngineStepVisible := true;
        BackActionEnabled := false;
        NextActionEnabled := false;
        FinishActionEnabled := true;
    end;

    local procedure ShowStartStep()
    begin
        FirstStepVisible := true;
        FinishActionEnabled := false;
        BackActionEnabled := false;
    end;

    local procedure ShowFinishStep()
    begin
        FinalStepVisible := true;
        NextActionEnabled := false;
        FinishActionEnabled := true;
    end;

    local procedure ResetControls()
    begin
        FinishActionEnabled := false;
        BackActionEnabled := true;
        NextActionEnabled := true;

        FirstStepVisible := false;
        FinalStepVisible := false;
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType())) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType()))
        then
            TopBannerVisible := MediaRepositoryDone.Image.HasValue;
    end;

    local procedure ClearTaxEngineSetup()
    var
        TaxType: Record "Tax Type";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        TaxType.DeleteAll(true);
    end;

    local procedure WizardIsAllowed(): Boolean
    var
        TaxType: Record "Tax Type";
    begin
        exit(TaxType.IsEmpty);
    end;

    local procedure StepValidation(): Boolean
    var
        ErrorMessage: Text;
        ValidationErrorMsg: Text;
    begin
        case Step of
        end;

        if ErrorMessage = '' then
            exit(true);

        TrigerNotification(ErrorMessage);
        exit(false);
    end;

    local procedure TrigerNotification(NotificationMsg: Text)
    begin
        WizardNotification.Recall();
        WizardNotification.Message(NotificationMsg);
        WizardNotification.Send();
    end;

    local procedure HideNotification()
    begin
        WizardNotification.Message := '';
        WizardNotification.Recall();
    end;
}