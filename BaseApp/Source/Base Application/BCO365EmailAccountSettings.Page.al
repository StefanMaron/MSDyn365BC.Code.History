page 2335 "BC O365 Email Account Settings"
{
    Caption = ' ';
    DeleteAllowed = false;
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "SMTP Mail Setup";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Control4)
            {
                InstructionalText = 'Your invoices will be sent from the following email account.';
                ShowCaption = false;
            }
            field("Email Provider"; EmailProvider)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Email Account Type';
                ToolTip = 'Specifies your email provider.';

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

                    Password := '';
                    PasswordModified := true;
                end;
            }
            group(Control12)
            {
                ShowCaption = false;
                group(Control13)
                {
                    InstructionalText = 'Enter the SMTP Server Details.';
                    ShowCaption = false;
                    Visible = AdvancedSettingsVisible;
                    field(Authentication; Authentication)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                    }
                    field("SMTP Server"; "SMTP Server")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        ShowMandatory = true;
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
            }
            group(Control16)
            {
                ShowCaption = false;
                group(Control17)
                {
                    ShowCaption = false;
                    field(FromAccount; FromAccount)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Email';
                        Importance = Promoted;

                        trigger OnValidate()
                        var
                            MailManagement: Codeunit "Mail Management";
                        begin
                            SplitUserIdAndSendAs(FromAccount);

                            if GetSender <> '' then
                                MailManagement.CheckValidEmailAddress("User ID");
                        end;
                    }
                    field(Password; Password)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Password';
                        ExtendedDatatype = Masked;
                        ToolTip = 'Specifies the password used for logging into the server.';

                        trigger OnValidate()
                        begin
                            PasswordModified := true;
                            "Password Key" := CreateGuid; // trigger modify
                        end;
                    }
                    field(TestEmailLbl; TestEmailLbl)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Editable = false;
                        ShowCaption = false;
                        Style = StandardAccent;
                        StyleExpr = TRUE;

                        trigger OnDrillDown()
                        begin
                            ValidateSettings(false);

                            SendTestEmailAction;
                        end;
                    }
                }
            }
            group(Control14)
            {
                ShowCaption = false;
                Visible = NOT LookupMode;
                field(SendViaGraphLbl; SendViaGraphLbl)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Editable = false;
                    ShowCaption = false;
                    Visible = GraphMailAvailable;

                    trigger OnDrillDown()
                    begin
                        PAGE.RunModal(PAGE::"Graph Mail Setup");
                        CurrPage.Update;
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        UpdateRec;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if not CurrPage.LookupMode then
            if ValidateSettings(true) then
                StoreSMTPSetup;
    end;

    trigger OnOpenPage()
    var
        GraphMail: Codeunit "Graph Mail";
    begin
        Init;
        Insert;

        LookupMode := CurrPage.LookupMode;

        GraphMailAvailable := false;
        if not LookupMode then
            GraphMailAvailable := GraphMail.UserHasLicense;

        UpdateRec;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not CurrPage.LookupMode then
            if ValidateSettings(true) then
                StoreSMTPSetup;
    end;

    var
        SMTPMail: Codeunit "SMTP Mail";
        AdvancedSettingsVisible: Boolean;
        FromAccount: Text[250];
        Password: Text[250];
        PasswordModified: Boolean;
        LookupMode: Boolean;
        EmailProvider: Option "Office 365",Outlook,Gmail,Yahoo,"Other Email Provider";
        DummyPasswordTxt: Label '***', Locked = true;
        TestEmailLbl: Label 'Send test email';
        EmailMissingUserPassErr: Label 'You must provide a user name and password to send email.';
        MissingServerSettingsErr: Label 'You must provide server information to send email.';
        SendViaGraphLbl: Label 'Send email from my account';
        GraphMailAvailable: Boolean;

    procedure StoreSMTPSetup()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
    begin
        if not SMTPMailSetup.Get then begin
            SMTPMailSetup.Init();
            SMTPMailSetup.Insert();
        end;

        // preserve old password key in case we need to remove it
        "Password Key" := SMTPMailSetup."Password Key";

        SMTPMailSetup.TransferFields(Rec, false);

        if PasswordModified then begin
            if Password = '' then
                SMTPMailSetup.RemovePassword
            else
                SMTPMailSetup.SetPassword(Password);
        end;

        SMTPMailSetup.Modify(true);
    end;

    local procedure SendTestEmailAction()
    begin
        StoreSMTPSetup;
        Commit();
        CODEUNIT.Run(CODEUNIT::"SMTP Test Mail");
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

        AdvancedSettingsVisible := EmailProvider = EmailProvider::"Other Email Provider";
    end;

    [TryFunction]
    procedure ValidateSettings(EmptyAuthInfoValid: Boolean)
    begin
        if EmailProvider = EmailProvider::"Other Email Provider" then begin
            if (not EmptyAuthInfoValid) and ("SMTP Server" = '') then
                Error(MissingServerSettingsErr);
            exit;
        end;

        if EmptyAuthInfoValid and ("User ID" = '') and (Password = '') then
            exit;

        if ("User ID" = '') or (Password = '') then
            Error(EmailMissingUserPassErr);
    end;

    [Scope('OnPrem')]
    procedure UpdateRec()
    var
        User: Record User;
        SMTPMailSetup: Record "SMTP Mail Setup";
        SMTPMail: Codeunit "SMTP Mail";
    begin
        if SMTPMailSetup.GetSetup and SMTPMail.IsEnabled then begin
            TransferFields(SMTPMailSetup);
            GetEmailProvider(SMTPMailSetup)
        end else begin
            SMTPMail.ApplyOffice365Smtp(Rec);
            EmailProvider := EmailProvider::"Office 365";
            if User.Get(UserSecurityId) then
                "User ID" := User."Authentication Email";
        end;

        Modify;

        if SMTPMailSetup.HasPassword then
            Password := DummyPasswordTxt;

        PasswordModified := false;

        FromAccount := GetConnectionString;
    end;
}

