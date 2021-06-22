page 1805 "Email Setup Wizard"
{
    Caption = 'Email Setup';
    PageType = NavigatePage;
    SourceTable = "SMTP Mail Setup";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Control96)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible AND NOT FinalStepVisible;
                field("MediaResourcesStandard.""Media Reference"""; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control98)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible AND FinalStepVisible;
                field("MediaResourcesDone.""Media Reference"""; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group("<MediaRepositoryDone>")
            {
                Visible = FirstStepVisible;
                group("Welcome to Email Setup")
                {
                    Caption = 'Welcome to Email Setup';
                    Visible = FirstStepVisible;
                    group(Control18)
                    {
                        InstructionalText = 'To send email messages using actions on documents, such as the Sales Invoice window, you must log on to the relevant email account.';
                        ShowCaption = false;
                    }
                }
                group("Let's go!")
                {
                    Caption = 'Let''s go!';
                    group(Control22)
                    {
                        InstructionalText = 'Choose Next so you can set up email sending from documents.';
                        ShowCaption = false;
                    }
                }
            }
            group(Control2)
            {
                InstructionalText = 'Choose your email provider.';
                ShowCaption = false;
                Visible = ProviderStepVisible;
                field("Email Provider"; EmailProvider)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Email Provider';

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
                    InstructionalText = 'Enter the credentials for the account, which will be used for sending emails.';
                    ShowCaption = false;
                    Visible = MailSettingsVisible;
                    field(Email; "User ID")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
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
                group(Control23)
                {
                    InstructionalText = 'To verify that the specified email setup works, choose Send Test Email.';
                    ShowCaption = false;
                }
                group("That's it!")
                {
                    Caption = 'That''s it!';
                    group(Control25)
                    {
                        InstructionalText = 'To enable email sending directly from documents, choose Finish.';
                        ShowCaption = false;
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
            action(ActionSendTestEmail)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Send Test Email';
                Enabled = true;
                Image = Email;
                InFooterBar = true;
                Visible = FinishActionEnabled;

                trigger OnAction()
                begin
                    SendTestEmailAction;
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

    trigger OnInit()
    begin
        LoadTopBanners;
    end;

    trigger OnOpenPage()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
        CompanyInformation: Record "Company Information";
        SMTPMail: Codeunit "SMTP Mail";
    begin
        Init;
        if SMTPMailSetup.Get then begin
            TransferFields(SMTPMailSetup);
            GetEmailProvider(SMTPMailSetup)
        end else begin
            SMTPMail.ApplyOffice365Smtp(Rec);
            EmailProvider := EmailProvider::"Office 365";
            if CompanyInformation.Get then
                "User ID" := CompanyInformation."E-Mail";
        end;
        Insert;
        if SMTPMailSetup.HasPassword then
            Password := DummyPasswordTxt;

        Step := Step::Start;
        EnableControls;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        AssistedSetup: Codeunit "Assisted Setup";
        Info: ModuleInfo;
    begin
        if CloseAction = ACTION::OK then 
            if AssistedSetup.ExistsAndIsNotComplete(PAGE::"Email Setup Wizard") then
                if not Confirm(NAVNotSetUpQst, false) then
                    Error('');
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        SMTPMail: Codeunit "SMTP Mail";
        ClientTypeManagement: Codeunit "Client Type Management";
        Step: Option Start,Provider,Settings,Finish;
        TopBannerVisible: Boolean;
        FirstStepVisible: Boolean;
        ProviderStepVisible: Boolean;
        SettingsStepVisible: Boolean;
        AdvancedSettingsVisible: Boolean;
        MailSettingsVisible: Boolean;
        FinalStepVisible: Boolean;
        EmailProvider: Option "Office 365",Outlook,Gmail,Yahoo,"Other Email Provider";
        FinishActionEnabled: Boolean;
        BackActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        NAVNotSetUpQst: Label 'Email has not been set up.\\Are you sure you want to exit?';
        EmailPasswordMissingErr: Label 'Please enter a valid email address and password.';
        Password: Text[250];
        DummyPasswordTxt: Label '***', Locked = true;

    local procedure EnableControls()
    begin
        ResetControls;

        case Step of
            Step::Start:
                ShowStartStep;
            Step::Provider:
                ShowProviderStep;
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
    var
        AssistedSetup: Codeunit "Assisted Setup";
    begin
        StoreSMTPSetup;
        AssistedSetup.Complete(PAGE::"Email Setup Wizard");
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

    local procedure ShowProviderStep()
    begin
        ProviderStepVisible := true;
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
        ProviderStepVisible := false;
        SettingsStepVisible := false;
        FinalStepVisible := false;
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

    local procedure GetEmailProvider(var SMTPMailSetup: Record "SMTP Mail Setup")
    begin
        case true of
            SMTPMail.IsOffice365Setup(SMTPMailSetup):
                EmailProvider := EmailProvider::"Office 365";
            SMTPMail.IsOutlookSetup(SMTPMailSetup):
                EmailProvider := EmailProvider::Outlook;
            SMTPMail.IsGmailSetup(SMTPMailSetup):
                EmailProvider := EmailProvider::Gmail;
            SMTPMail.IsYahooSetup(SMTPMailSetup):
                EmailProvider := EmailProvider::Yahoo;
            else
                EmailProvider := EmailProvider::"Other Email Provider";
        end;
    end;
}

