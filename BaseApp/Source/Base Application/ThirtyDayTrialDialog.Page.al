page 9193 "Thirty Day Trial Dialog"
{
    Caption = '30-Day Trial';
    PageType = NavigatePage;

    layout
    {
        area(content)
        {
            group(Control11)
            {
                ShowCaption = false;
                Visible = FirstStepVisible;
                group("Get started with a free 30-day trial")
                {
                    Caption = 'Get started with a free 30-day trial';
                    InstructionalText = 'Explore the benefits of Dynamics 365 Business Central with your own company data.';
                }
                field(Content1Lbl; Content1Lbl)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    MultiLine = true;
                    ShowCaption = false;
                }
                field(Content2Lbl; Content2Lbl)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    MultiLine = true;
                    ShowCaption = false;
                }
                field(Content3Lbl; Content3Lbl)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    MultiLine = true;
                    ShowCaption = false;
                }
            }
            group(Control17)
            {
                ShowCaption = false;
                Visible = FinalStepVisible;
                group("We're ready, let's get started")
                {
                    Caption = 'We''re ready, let''s get started';
                    InstructionalText = 'Read and accept the terms and conditions, and then choose Start Trial to start your 30-day trial period.';
                }
                field(LinkControl; LinkLbl)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    MultiLine = false;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        HyperLink(UrlTxt);
                    end;
                }
                field(TermsAndConditionsCheckBox; TermsAndConditionsAccepted)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'I accept the Terms & Conditions';
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
                //The property 'ToolTip' cannot be empty.
                //ToolTip = '';

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
                    NextStep(false);
                end;
            }
            action(ActionStartTrial)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Start Trial';
                Enabled = TermsAndConditionsAccepted;
                Gesture = None;
                Image = Approve;
                InFooterBar = true;
                //The property 'ToolTip' cannot be empty.
                //ToolTip = '';

                trigger OnAction()
                begin
                    StartTrialAction;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Step := Step::Start;
        EnableControls;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::OK then
            if not TrialWizardCompleted then
                if not Confirm(AbortTrialQst, false) then
                    Error('');
    end;

    var
        Step: Option Start,Finish;
        FirstStepVisible: Boolean;
        FinalStepVisible: Boolean;
        BackActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        TrialWizardCompleted: Boolean;
        TermsAndConditionsAccepted: Boolean;
        LinkLbl: Label 'View Terms & Conditions';
        UrlTxt: Label 'http://go.microsoft.com/fwlink/?LinkId=828977', Locked = true;
        Content1Lbl: Label 'Use the setups that we provide, and import or create items, customers, and vendors to do things like post invoices or use graphs and reports to analyze your finances.';
        Content2Lbl: Label 'If you decide to subscribe, you can continue using the data and setup that you create during the trial.';
        Content3Lbl: Label 'Choose Next to learn more about how to get started.';
        AbortTrialQst: Label 'Are you sure that you want to cancel?';

    local procedure EnableControls()
    begin
        ResetControls;

        case Step of
            Step::Start:
                ShowStartStep;
            Step::Finish:
                ShowFinalStep;
        end;
    end;

    local procedure NextStep(Backwards: Boolean)
    begin
        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;

        EnableControls;
    end;

    local procedure ShowStartStep()
    begin
        FirstStepVisible := true;
        BackActionEnabled := false;
    end;

    local procedure ShowFinalStep()
    begin
        FinalStepVisible := true;
        NextActionEnabled := false;
    end;

    local procedure ResetControls()
    begin
        BackActionEnabled := true;
        NextActionEnabled := true;

        FirstStepVisible := false;
        FinalStepVisible := false;
    end;

    local procedure StartTrialAction()
    begin
        TrialWizardCompleted := true;
        CurrPage.Close;
    end;

    procedure Confirmed(): Boolean
    begin
        exit(TermsAndConditionsAccepted and TrialWizardCompleted);
    end;
}

