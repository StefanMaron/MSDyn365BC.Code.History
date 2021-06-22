page 2197 "O365 Email Setup Wizard"
{
    Caption = 'Email Setup';
    PageType = NavigatePage;
    SourceTable = "SMTP Mail Setup";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Control20)
            {
                ShowCaption = false;
                Visible = FirstStepVisible;
                group("Welcome to Email Setup")
                {
                    Caption = 'Welcome to Email Setup';
                    Visible = FirstStepVisible;
                    group(Control18)
                    {
                        InstructionalText = 'Let''s set up the account from which invoice emails will be sent.';
                        ShowCaption = false;
                    }
                }
            }
            group(Control2)
            {
                Editable = FirstStepVisible;
                ShowCaption = false;
                Visible = FirstStepVisible OR SettingsStepVisible;
                group(Control19)
                {
                    Editable = FirstStepVisible;
                    InstructionalText = 'Choose your email account type';
                    ShowCaption = false;
                    Visible = NOT SettingsStepVisible;
                }
                field("Email Provider"; EmailProvider)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Email Account type';
                    ShowCaption = false;

                    trigger OnValidate()
                    begin
                        case EmailProvider of
                            EmailProvider::"Office 365":
                                SMTPMail.ApplyOffice365Smtp(Rec);
                            EmailProvider::Outlook:
                                SMTPMail.ApplyOutlookSmtp(Rec);
                            EmailProvider::Gmail:
                                SMTPMail.ApplyGmailSmtp(Rec);
                            EmailProvider::Yahoo:
                                SMTPMail.ApplyYahooSmtp(Rec);
                            EmailProvider::"Other Email Provider":
                                "SMTP Server" := '';
                        end;
                        AdvancedSettingsVisible := EmailProvider = EmailProvider::"Other Email Provider";
                        EnableControls;
                    end;
                }
            }
            group(Control12)
            {
                ShowCaption = false;
                Visible = SettingsStepVisible;
                group(Control27)
                {
                    InstructionalText = 'Enter the SMTP Server Details.';
                    ShowCaption = false;
                    Visible = AdvancedSettingsVisible;
                    field(Authentication; Authentication)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;

                        trigger OnValidate()
                        begin
                            EnableControls;
                        end;
                    }
                    field("SMTP Server"; "SMTP Server")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        ShowMandatory = true;

                        trigger OnValidate()
                        begin
                            EnableControls;
                        end;
                    }
                    field("SMTP Server Port"; "SMTP Server Port")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                    }
                    field("Secure Connection"; "Secure Connection")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                    }
                }
                group(Control26)
                {
                    InstructionalText = 'Enter the credentials for the account, which will be used for sending the invoice emails.';
                    ShowCaption = false;
                    Visible = MailSettingsVisible;
                    field("User ID"; "User ID")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Email';
                        ExtendedDatatype = EMail;

                        trigger OnValidate()
                        begin
                            EnableControls;
                        end;
                    }
                    field(Password; Password)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Password';
                        ExtendedDatatype = Masked;

                        trigger OnValidate()
                        begin
                            EnableControls;
                        end;
                    }
                }
            }
            group(Control17)
            {
                ShowCaption = false;
                Visible = FinalStepVisible;
                group("That's it!")
                {
                    Caption = 'That''s it!';
                    InstructionalText = 'If you want to verify that the specified email setup works, click on Send test email.';
                    field(TestEmailLbl; TestEmailLbl)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Editable = false;
                        ShowCaption = false;
                        Style = StandardAccent;
                        StyleExpr = TRUE;

                        trigger OnDrillDown()
                        begin
                            SendTestEmailAction;
                        end;
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
                ApplicationArea = Basic, Suite, Invoicing;
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
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Next';
                Enabled = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    case Step of
                        Step::Settings:
                            if (Authentication = Authentication::Basic) and (("User ID" = '') or (Password = '')) then
                                Error(EmailPasswordMissingErr);
                    end;

                    NextStep(false);
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Finish';
                Enabled = FinishActionEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                begin
                    FinishAction;
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
        User: Record User;
        SMTPMail: Codeunit "SMTP Mail";
    begin
        Init;
        if SMTPMailSetup.GetSetup and SMTPMail.IsEnabled then begin
            TransferFields(SMTPMailSetup);
            GetEmailProvider(SMTPMailSetup)
        end else begin
            SMTPMail.ApplyOffice365Smtp(Rec);
            EmailProvider := EmailProvider::"Office 365";
            if User.Get(UserSecurityId) then
                "User ID" := User."Authentication Email";
        end;
        Insert;
        if SMTPMailSetup.HasPassword then
            Password := DummyPasswordTxt;

        Step := Step::Start;
        EnableControls;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::OK then
            if not SetupCompleted then
                if not Confirm(NotSetUpQst, false) then
                    Error('');
    end;

    var
        SMTPMail: Codeunit "SMTP Mail";
        FirstStepVisible: Boolean;
        SettingsStepVisible: Boolean;
        AdvancedSettingsVisible: Boolean;
        MailSettingsVisible: Boolean;
        FinalStepVisible: Boolean;
        FinishActionEnabled: Boolean;
        BackActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        NotSetUpQst: Label 'Email has not been set up.\\Are you sure you want to exit?';
        EmailPasswordMissingErr: Label 'Please enter a valid email address and password.';
        SetupCompleted: Boolean;
        Password: Text[250];
        DummyPasswordTxt: Label '***', Locked = true;
        Step: Option Start,Settings,Finish;
        EmailProvider: Option "Office 365",Outlook,Gmail,Yahoo,"Other Email Provider";
        TestEmailLbl: Label 'Send test email';

    local procedure EnableControls()
    begin
        ResetControls;

        case Step of
            Step::Start:
                ShowStartStep;
            Step::Settings:
                ShowSettingsStep;
            Step::Finish:
                ShowFinishStep;
        end;
    end;

    local procedure StoreSMTPSetup()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
    begin
        if not SMTPMailSetup.Get then begin
            SMTPMailSetup.Init();
            SMTPMailSetup.Insert();
        end;

        SMTPMailSetup.TransferFields(Rec, false);
        if Password <> DummyPasswordTxt then
            SMTPMailSetup.SetPassword(Password);
        SMTPMailSetup.Modify(true);
        Commit();
    end;

    local procedure SendTestEmailAction()
    begin
        StoreSMTPSetup;
        CODEUNIT.Run(CODEUNIT::"SMTP Test Mail");
    end;

    local procedure FinishAction()
    begin
        StoreSMTPSetup;
        SetupCompleted := true;
        CurrPage.Close;
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
        FinishActionEnabled := false;
        BackActionEnabled := false;
    end;

    local procedure ShowSettingsStep()
    begin
        SettingsStepVisible := true;
        AdvancedSettingsVisible := EmailProvider = EmailProvider::"Other Email Provider";
        MailSettingsVisible := Authentication = Authentication::Basic;
        NextActionEnabled := "SMTP Server" <> '';
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
        SettingsStepVisible := false;
        FinalStepVisible := false;
    end;

    local procedure GetEmailProvider(var SMTPMailSetup: Record "SMTP Mail Setup")
    begin
        if SMTPMail.IsOffice365Setup(SMTPMailSetup) then
            EmailProvider := EmailProvider::"Office 365"
        else
            if SMTPMail.IsOutlookSetup(SMTPMailSetup) then
                EmailProvider := EmailProvider::Outlook
            else
                if SMTPMail.IsGmailSetup(SMTPMailSetup) then
                    EmailProvider := EmailProvider::Gmail
                else
                    if SMTPMail.IsYahooSetup(SMTPMailSetup) then
                        EmailProvider := EmailProvider::Yahoo
                    else
                        EmailProvider := EmailProvider::"Other Email Provider";
    end;
}

